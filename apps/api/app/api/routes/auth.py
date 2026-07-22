import logging
from urllib.parse import urlencode

import requests
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.repositories.user_repository import UserRepository
from app.core.dependencies import get_current_user
from app.core.security import verify_password, create_access_token
from app.core.rate_limit import auth_rate_limit_key, auth_rate_limiter
from app.db.models.user import User
from app.schemas.user import (
    EmailVerificationRequest,
    MessageResponse,
    RegistrationResponse,
    Token,
    UserCreate,
    UserResponse,
)
from app.services.email_delivery import EmailDeliveryUnavailable
from app.services.email_verification import EmailVerificationService
from app.core.config import settings

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"],
)


@router.get("/me", response_model=UserResponse)
def current_account(
    current_user: User = Depends(get_current_user),
):
    return current_user


@router.post(
    "/register",
    response_model=RegistrationResponse,
    status_code=202,
)
def register(
    user_data: UserCreate,
    request: Request,
    db: Session = Depends(get_db),
):
    auth_rate_limiter.check(
        auth_rate_limit_key(request, action="register"),
        limit=10,
        window_seconds=3600,
    )

    repository = UserRepository(db)
    email = user_data.email.lower().strip()

    if repository.get_by_email(email):
        raise HTTPException(409, "User with this email already exists")

    verification_service = EmailVerificationService(repository)

    try:
        verification_service.ensure_available()
    except RuntimeError:
        raise HTTPException(
            503,
            "Email verification is temporarily unavailable",
        ) from None

    user = repository.create(
        email=email,
        password=user_data.password,
        full_name=user_data.full_name.strip(),
        email_verification_required=True,
    )

    try:
        verification_service.send(user)
    except (EmailDeliveryUnavailable, requests.RequestException):
        logger.exception("Failed to send verification email")

    return {
        "message": "Check your email to complete registration",
        "email": user.email,
    }


@router.post("/login", response_model=Token)
def login(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    repository = UserRepository(db)
    normalized_email = form_data.username.lower().strip()
    account_limit_key = auth_rate_limit_key(
        request,
        action="login-account",
        account=normalized_email,
    )

    auth_rate_limiter.check(
        auth_rate_limit_key(request, action="login"),
        limit=20,
        window_seconds=60,
    )
    auth_rate_limiter.check(
        account_limit_key,
        limit=5,
        window_seconds=300,
    )

    user = repository.get_by_email(normalized_email)

    if not user:
        raise HTTPException(401, "Invalid credentials")

    if not 1 <= len(form_data.password) <= 128:
        raise HTTPException(401, "Invalid credentials")

    if not user.hashed_password:
        raise HTTPException(401, "Invalid credentials")

    if not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(401, "Invalid credentials")

    if user.email_verification_required and user.email_verified_at is None:
        raise HTTPException(403, "Email verification required")

    auth_rate_limiter.reset(account_limit_key)
    token = create_access_token(user.public_id)

    return {
        "access_token": token,
        "token_type": "bearer",
    }


@router.post(
    "/resend-verification",
    response_model=MessageResponse,
    status_code=202,
)
def resend_verification(
    data: EmailVerificationRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    normalized_email = data.email.lower().strip()
    auth_rate_limiter.check(
        auth_rate_limit_key(
            request,
            action="resend-verification",
            account=normalized_email,
        ),
        limit=3,
        window_seconds=900,
    )
    repository = UserRepository(db)
    user = repository.get_by_email(normalized_email)

    if user is not None and user.email_verified_at is None:
        try:
            EmailVerificationService(repository).send(user)
        except (RuntimeError, EmailDeliveryUnavailable, requests.RequestException):
            logger.exception("Failed to resend verification email")

    return {"message": "If the account exists, a verification email was sent"}


@router.post(
    "/me/send-verification",
    response_model=MessageResponse,
    status_code=202,
)
def send_current_user_verification(
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.email_verified_at is not None:
        return {"message": "Email is already verified"}

    auth_rate_limiter.check(
        auth_rate_limit_key(
            request,
            action="current-user-verification",
            account=str(current_user.public_id),
        ),
        limit=3,
        window_seconds=900,
    )

    try:
        EmailVerificationService(UserRepository(db)).send(current_user)
    except (RuntimeError, EmailDeliveryUnavailable, requests.RequestException):
        raise HTTPException(
            503,
            "Could not send verification email",
        ) from None

    return {"message": "Verification email sent"}


@router.get("/verify-email", include_in_schema=False)
def verify_email(
    token: str = Query(min_length=32, max_length=256),
    db: Session = Depends(get_db),
):
    user = EmailVerificationService(UserRepository(db)).verify(token)
    status = "success" if user is not None else "invalid"
    query = urlencode({"email_verification": status})
    redirect_url = f"{settings.frontend_base_url.rstrip('/')}/?{query}"

    return RedirectResponse(redirect_url, status_code=303)
