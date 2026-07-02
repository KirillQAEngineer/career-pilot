from jose import jwt, JWTError

from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.repositories.user_repository import UserRepository
from app.core.config import settings

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/auth/login",
)


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    print("=" * 50)
    print("TOKEN:", token)

    try:
        payload = jwt.decode(
            token,
            settings.secret_key,
            algorithms=["HS256"],
        )

        print("PAYLOAD:", payload)

        user_id = int(payload["sub"])

        print("USER_ID:", user_id)

    except Exception as e:
        print("JWT ERROR:", repr(e))
        raise HTTPException(401, "Invalid token")

    user = UserRepository(db).get(user_id)

    print("USER:", user)

    if not user:
        print("USER NOT FOUND")
        raise HTTPException(401, "User not found")

    print("SUCCESS")
    print("=" * 50)

    return user