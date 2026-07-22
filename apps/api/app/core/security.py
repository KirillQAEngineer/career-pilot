from datetime import datetime, timedelta, UTC
from uuid import UUID, uuid4

import jwt
from pwdlib import PasswordHash

from app.core.config import settings

ALGORITHM = "HS256"
TOKEN_ISSUER = "jobcompass-api"
TOKEN_AUDIENCE = "jobcompass-web"

password_hash = PasswordHash.recommended()


def hash_password(password: str) -> str:
    return password_hash.hash(password)


def verify_password(password: str, hashed_password: str) -> bool:
    return password_hash.verify(password, hashed_password)


def create_access_token(user_id: UUID) -> str:
    issued_at = datetime.now(UTC)
    expire = datetime.now(UTC) + timedelta(
        minutes=settings.access_token_expire_minutes
    )

    payload = {
        "sub": str(user_id),
        "iss": TOKEN_ISSUER,
        "aud": TOKEN_AUDIENCE,
        "iat": issued_at,
        "exp": expire,
        "jti": str(uuid4()),
        "type": "access",
    }

    return jwt.encode(
        payload,
        settings.secret_key,
        algorithm=ALGORITHM,
    )
