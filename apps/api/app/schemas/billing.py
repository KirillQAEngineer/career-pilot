from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, Field


class BillingStatusResponse(BaseModel):
    has_analytics_access: bool
    checkout_available: bool
    email_verified: bool
    price_minor_units: int
    currency: str
    display_price: str
    latest_payment_status: str | None = None


class CheckoutRequest(BaseModel):
    amount_usdt: Decimal = Field(
        ge=Decimal("1"),
        le=Decimal("100000"),
        max_digits=8,
        decimal_places=2,
    )


class CheckoutResponse(BaseModel):
    payment_id: UUID
    confirmation_url: str
    status: str


class PaymentStatusResponse(BaseModel):
    payment_id: UUID
    status: str
    has_analytics_access: bool
