import logging

import requests
from fastapi import APIRouter, Depends, Header, HTTPException, Response
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.dependencies import get_current_user
from app.core.rate_limit import api_rate_limiter
from app.db.models.payment import Payment
from app.db.models.user import User
from app.db.repositories.payment_repository import PaymentRepository
from app.db.repositories.user_repository import UserRepository
from app.db.session import get_db
from app.schemas.billing import (
    BillingStatusResponse,
    CheckoutRequest,
    CheckoutResponse,
    PaymentStatusResponse,
)
from app.services.nowpayments import (
    NowPaymentsClient,
    NowPaymentsInvalidPayment,
    NowPaymentsUnavailable,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/billing", tags=["Billing"])
PRODUCT = "analytics_lifetime"
ACTIVE_PAYMENT_STATUSES = {
    "pending",
    "waiting",
    "confirming",
    "confirmed",
    "sending",
    "partially_paid",
}


@router.get("/me", response_model=BillingStatusResponse)
def billing_status(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    latest = PaymentRepository(db).get_latest_for_user(current_user.id)

    return BillingStatusResponse(
        has_analytics_access=_has_access(current_user),
        checkout_available=NowPaymentsClient().is_configured,
        email_verified=current_user.email_verified_at is not None,
        price_minor_units=settings.analytics_lifetime_price_minor_units,
        currency=settings.analytics_lifetime_price_currency.upper(),
        display_price=settings.analytics_lifetime_display_price,
        latest_payment_status=latest.status if latest else None,
    )


@router.post(
    "/analytics-lifetime/checkout",
    response_model=CheckoutResponse,
)
def create_checkout(
    request: CheckoutRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if _has_access(current_user):
        raise HTTPException(409, "Analytics access is already active")

    if current_user.email_verified_at is None:
        raise HTTPException(403, "Verify your email before payment")

    api_rate_limiter.check(
        f"billing:checkout:{current_user.public_id}",
        limit=3,
        window_seconds=600,
    )
    repository = PaymentRepository(db)
    latest = repository.get_latest_for_user(current_user.id)
    amount_minor_units = int(request.amount_usdt * 100)

    if (
        latest
        and latest.status in ACTIVE_PAYMENT_STATUSES
        and latest.confirmation_url
        and latest.amount_minor_units == amount_minor_units
    ):
        return _checkout_response(latest)

    if latest and latest.status in ACTIVE_PAYMENT_STATUSES:
        repository.mark_failed(latest)

    payment = repository.create_pending(
        user_id=current_user.id,
        product=PRODUCT,
        amount_minor_units=amount_minor_units,
        currency=settings.analytics_lifetime_price_currency.upper(),
    )

    try:
        payload = NowPaymentsClient().create_invoice(payment, current_user)
        confirmation_url = payload.get("invoice_url")
        provider_invoice_id = payload.get("id")

        if not confirmation_url or provider_invoice_id is None:
            raise NowPaymentsInvalidPayment("Missing invoice URL")

        payment = repository.set_provider_data(
            payment,
            provider_invoice_id=str(provider_invoice_id),
            confirmation_url=str(confirmation_url),
            status="pending",
        )
    except NowPaymentsUnavailable:
        repository.mark_failed(payment)
        raise HTTPException(503, "Payments are temporarily unavailable") from None
    except (requests.RequestException, NowPaymentsInvalidPayment):
        repository.mark_failed(payment)
        logger.exception("Could not create NOWPayments invoice")
        raise HTTPException(502, "Could not create payment") from None

    return _checkout_response(payment)


@router.post(
    "/analytics-lifetime/refresh",
    response_model=PaymentStatusResponse,
)
def refresh_payment(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    api_rate_limiter.check(
        f"billing:refresh:{current_user.public_id}",
        limit=10,
        window_seconds=300,
    )
    repository = PaymentRepository(db)
    payment = repository.get_latest_for_user(current_user.id)

    if payment is None:
        raise HTTPException(404, "Payment not found")

    if payment.provider_payment_id:
        payment = _reconcile_payment(
            payment,
            current_user,
            repository,
            NowPaymentsClient(),
        )

    return PaymentStatusResponse(
        payment_id=payment.public_id,
        status=payment.status,
        has_analytics_access=_has_access(current_user),
    )


@router.post("/nowpayments/ipn", status_code=204)
def nowpayments_ipn(
    payload: dict,
    x_nowpayments_sig: str | None = Header(
        default=None,
        alias="x-nowpayments-sig",
    ),
    db: Session = Depends(get_db),
):
    client = NowPaymentsClient()
    if not client.verify_ipn_signature(payload, x_nowpayments_sig or ""):
        raise HTTPException(401, "Invalid IPN signature")

    provider_invoice_id = str(payload.get("invoice_id", ""))
    provider_payment_id = str(payload.get("payment_id", ""))

    if not provider_invoice_id or not provider_payment_id:
        raise HTTPException(400, "Payment identifiers are missing")

    api_rate_limiter.check(
        f"billing:ipn:{provider_payment_id}",
        limit=20,
        window_seconds=60,
    )
    repository = PaymentRepository(db)
    payment = repository.get_by_provider_invoice_id(provider_invoice_id)

    if payment is None:
        return Response(status_code=204)

    user = UserRepository(db).get(payment.user_id)
    if user is None:
        return Response(status_code=204)

    try:
        payment = repository.set_provider_payment_id(
            payment,
            provider_payment_id,
        )
        _reconcile_payment(payment, user, repository, client)
    except (
        requests.RequestException,
        NowPaymentsInvalidPayment,
        NowPaymentsUnavailable,
        ValueError,
    ):
        logger.exception("Could not reconcile NOWPayments IPN")
        raise HTTPException(502, "Could not verify payment") from None

    return Response(status_code=204)


def _reconcile_payment(
    payment: Payment,
    user: User,
    repository: PaymentRepository,
    client: NowPaymentsClient,
) -> Payment:
    try:
        payload = client.get_payment(payment.provider_payment_id or "")
        status = client.validate_payment(payload, payment, user)
    except NowPaymentsUnavailable:
        raise HTTPException(503, "Payments are temporarily unavailable") from None
    except (requests.RequestException, NowPaymentsInvalidPayment):
        raise HTTPException(502, "Could not verify payment") from None

    return repository.apply_provider_status(payment, user, status)


def _has_access(user: User) -> bool:
    return user.is_admin or user.analytics_lifetime_access


def _checkout_response(payment: Payment) -> CheckoutResponse:
    if payment.confirmation_url is None:
        raise HTTPException(502, "Payment confirmation URL is missing")

    return CheckoutResponse(
        payment_id=payment.public_id,
        confirmation_url=payment.confirmation_url,
        status=payment.status,
    )
