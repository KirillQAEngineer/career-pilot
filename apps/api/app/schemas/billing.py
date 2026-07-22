from uuid import UUID

from pydantic import BaseModel


class BillingStatusResponse(BaseModel):
    has_analytics_access: bool
    checkout_available: bool
    email_verified: bool
    price_minor_units: int
    currency: str
    display_price: str
    latest_payment_status: str | None = None


class CheckoutResponse(BaseModel):
    payment_id: UUID
    confirmation_url: str
    status: str


class PaymentStatusResponse(BaseModel):
    payment_id: UUID
    status: str
    has_analytics_access: bool
