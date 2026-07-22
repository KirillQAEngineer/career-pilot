import hashlib
import hmac
import json
from decimal import Decimal, InvalidOperation

import requests

from app.core.config import settings
from app.db.models.payment import Payment
from app.db.models.user import User


class NowPaymentsUnavailable(RuntimeError):
    pass


class NowPaymentsInvalidPayment(RuntimeError):
    pass


class NowPaymentsClient:
    BASE_URL = "https://api.nowpayments.io/v1"
    PENDING_STATUSES = {
        "waiting",
        "confirming",
        "confirmed",
        "sending",
        "partially_paid",
    }
    FAILED_STATUSES = {"failed", "refunded", "expired"}

    @property
    def is_configured(self) -> bool:
        return bool(
            settings.nowpayments_api_key and settings.nowpayments_ipn_secret
        )

    def create_invoice(self, payment: Payment, user: User) -> dict:
        self._ensure_configured()
        frontend_url = settings.frontend_base_url.rstrip("/")
        response = requests.post(
            f"{self.BASE_URL}/invoice",
            headers={
                "x-api-key": settings.nowpayments_api_key,
                "Content-Type": "application/json",
            },
            json={
                "price_amount": self._amount_value(payment),
                "price_currency": payment.currency.lower(),
                "order_id": str(payment.public_id),
                "order_description": (
                    "JobCompass lifetime Analytics access"
                ),
                "ipn_callback_url": (
                    f"{settings.public_api_base_url.rstrip('/')}"
                    "/billing/nowpayments/ipn"
                ),
                "success_url": f"{frontend_url}/?payment_return=1",
                "cancel_url": f"{frontend_url}/?payment_canceled=1",
                "is_fixed_rate": True,
                "is_fee_paid_by_user": True,
            },
            timeout=15,
        )
        response.raise_for_status()

        return response.json()

    def get_payment(self, provider_payment_id: str) -> dict:
        self._ensure_configured()
        response = requests.get(
            f"{self.BASE_URL}/payment/{provider_payment_id}",
            headers={"x-api-key": settings.nowpayments_api_key},
            timeout=15,
        )
        response.raise_for_status()

        return response.json()

    def verify_ipn_signature(self, payload: dict, signature: str) -> bool:
        if not signature or not settings.nowpayments_ipn_secret:
            return False

        canonical_payload = json.dumps(
            payload,
            separators=(",", ":"),
            sort_keys=True,
        )
        expected = hmac.new(
            settings.nowpayments_ipn_secret.encode("utf-8"),
            canonical_payload.encode("utf-8"),
            hashlib.sha512,
        ).hexdigest()

        return hmac.compare_digest(expected, signature.lower())

    def validate_payment(
        self,
        payload: dict,
        payment: Payment,
        user: User,
    ) -> str:
        del user  # User identity is bound through the local payment order ID.

        try:
            received_amount = Decimal(str(payload.get("price_amount")))
        except (InvalidOperation, TypeError, ValueError):
            raise NowPaymentsInvalidPayment("Invalid payment amount") from None

        expected_amount = Decimal(payment.amount_minor_units) / Decimal("100")
        provider_payment_id = str(payload.get("payment_id", ""))
        invoice_id = str(payload.get("invoice_id", ""))
        payment_status = str(payload.get("payment_status", ""))

        if (
            not provider_payment_id
            or provider_payment_id != payment.provider_payment_id
            or not invoice_id
            or invoice_id != payment.provider_invoice_id
            or str(payload.get("order_id", "")) != str(payment.public_id)
            or received_amount != expected_amount
            or str(payload.get("price_currency", "")).upper()
            != payment.currency.upper()
        ):
            raise NowPaymentsInvalidPayment("Payment metadata mismatch")

        if payment_status == "finished":
            return "succeeded"

        if payment_status in self.PENDING_STATUSES:
            return payment_status

        if payment_status in self.FAILED_STATUSES:
            return payment_status

        raise NowPaymentsInvalidPayment("Unsupported payment status")

    def _ensure_configured(self) -> None:
        if not self.is_configured:
            raise NowPaymentsUnavailable("NOWPayments is not configured")

    @staticmethod
    def _amount_value(payment: Payment) -> float:
        return payment.amount_minor_units / 100
