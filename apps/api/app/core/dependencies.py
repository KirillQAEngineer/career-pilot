from uuid import UUID

import jwt
from jwt import InvalidTokenError

from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.repositories.user_repository import UserRepository
from app.core.config import settings
from app.core.security import ALGORITHM, TOKEN_AUDIENCE, TOKEN_ISSUER

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/auth/login",
)


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):

    try:
        payload = jwt.decode(
            token,
            settings.secret_key,
            algorithms=[ALGORITHM],
            audience=TOKEN_AUDIENCE,
            issuer=TOKEN_ISSUER,
            options={
                "require": ["sub", "exp", "iat", "iss", "aud", "jti"],
            },
        )

        if payload.get("type") != "access":
            raise InvalidTokenError("Invalid token type")

        user_id = UUID(payload["sub"])

    except (InvalidTokenError, KeyError, TypeError, ValueError):
        raise HTTPException(401, "Invalid token") from None

    user = UserRepository(db).get_by_public_id(user_id)

    if not user:
        raise HTTPException(401, "User not found")

    return user


def require_admin(
    current_user=Depends(get_current_user),
):
    if not current_user.is_admin:
        raise HTTPException(403, "Administrator access required")

    return current_user
