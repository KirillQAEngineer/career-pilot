from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.repositories.user_repository import UserRepository
from app.core.dependencies import get_current_user
from app.core.security import verify_password, create_access_token
from app.core.rate_limit import auth_rate_limit_key, auth_rate_limiter
from app.db.models.user import User
from app.schemas.user import Token, UserCreate, UserResponse

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"],
)


@router.get("/me", response_model=UserResponse)
def current_account(
    current_user: User = Depends(get_current_user),
):
    return current_user


@router.post("/register", response_model=Token, status_code=201)
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

    user = repository.create(
        email=email,
        password=user_data.password,
        full_name=user_data.full_name.strip(),
    )

    token = create_access_token(user.public_id)

    return {
        "access_token": token,
        "token_type": "bearer",
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

    auth_rate_limiter.reset(account_limit_key)
    token = create_access_token(user.public_id)

    return {
        "access_token": token,
        "token_type": "bearer",
    }
