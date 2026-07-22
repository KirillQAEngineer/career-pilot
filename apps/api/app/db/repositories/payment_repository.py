from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy.orm import Session

from app.db.models.payment import Payment
from app.db.models.user import User


class PaymentRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_pending(
        self,
        *,
        user_id: int,
        product: str,
        amount_minor_units: int,
        currency: str,
    ) -> Payment:
        payment = Payment(
            user_id=user_id,
            provider="nowpayments",
            product=product,
            amount_minor_units=amount_minor_units,
            currency=currency,
            status="pending",
        )
        self.db.add(payment)
        self.db.commit()
        self.db.refresh(payment)

        return payment

    def set_provider_data(
        self,
        payment: Payment,
        *,
        provider_invoice_id: str,
        confirmation_url: str | None,
        status: str,
    ) -> Payment:
        payment.provider_invoice_id = provider_invoice_id
        payment.confirmation_url = confirmation_url
        payment.status = status
        self.db.commit()
        self.db.refresh(payment)

        return payment

    def set_provider_payment_id(
        self,
        payment: Payment,
        provider_payment_id: str,
    ) -> Payment:
        if (
            payment.provider_payment_id
            and payment.provider_payment_id != provider_payment_id
        ):
            raise ValueError("Provider payment ID mismatch")

        payment.provider_payment_id = provider_payment_id
        self.db.commit()
        self.db.refresh(payment)

        return payment

    def mark_failed(self, payment: Payment) -> Payment:
        payment.status = "failed"
        self.db.commit()
        self.db.refresh(payment)

        return payment

    def get_by_public_id(self, payment_id: UUID, user_id: int) -> Payment | None:
        return (
            self.db.query(Payment)
            .filter(Payment.public_id == payment_id, Payment.user_id == user_id)
            .first()
        )

    def get_by_provider_id(self, provider_payment_id: str) -> Payment | None:
        return (
            self.db.query(Payment)
            .filter(Payment.provider_payment_id == provider_payment_id)
            .first()
        )

    def get_by_provider_invoice_id(
        self,
        provider_invoice_id: str,
    ) -> Payment | None:
        return (
            self.db.query(Payment)
            .filter(Payment.provider_invoice_id == provider_invoice_id)
            .first()
        )

    def get_latest_for_user(self, user_id: int) -> Payment | None:
        return (
            self.db.query(Payment)
            .filter(Payment.user_id == user_id)
            .order_by(Payment.id.desc())
            .first()
        )

    def apply_provider_status(
        self,
        payment: Payment,
        user: User,
        status: str,
    ) -> Payment:
        payment.status = status

        if status == "succeeded" and payment.paid_at is None:
            payment.paid_at = datetime.now(UTC).replace(tzinfo=None)
            user.analytics_lifetime_access = True
        elif status == "refunded":
            other_successful_payment = (
                self.db.query(Payment)
                .filter(
                    Payment.user_id == user.id,
                    Payment.id != payment.id,
                    Payment.status == "succeeded",
                )
                .first()
            )
            if other_successful_payment is None:
                user.analytics_lifetime_access = False

        self.db.commit()
        self.db.refresh(payment)
        self.db.refresh(user)

        return payment
