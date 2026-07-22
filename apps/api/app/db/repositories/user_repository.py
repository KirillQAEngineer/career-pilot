from datetime import datetime
from sqlalchemy.orm import Session
from uuid import UUID

from app.core.security import hash_password
from app.db.models.user import User


class UserRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(
        self,
        email: str,
        password: str,
        full_name: str,
        *,
        email_verification_required: bool = True,
    ) -> User:

        user = User(
            email=email,
            hashed_password=hash_password(password),
            full_name=full_name,
            email_verification_required=email_verification_required,
        )

        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)

        return user

    def get_all(self):
        return self.db.query(User).order_by(User.id).all()

    def count(self) -> int:
        return self.db.query(User).count()

    def count_admins(self) -> int:
        return self.db.query(User).filter(User.is_admin.is_(True)).count()

    def get(self, user_id: int):
        return self.db.query(User).filter(User.id == user_id).first()

    def get_by_public_id(self, public_id: UUID):
        return self.db.query(User).filter(User.public_id == public_id).first()

    def get_by_email(self, email: str):
        return self.db.query(User).filter(User.email == email).first()

    def get_by_verification_token_hash(self, token_hash: str):
        return (
            self.db.query(User)
            .filter(User.email_verification_token_hash == token_hash)
            .first()
        )

    def set_verification_token(
        self,
        user: User,
        *,
        token_hash: str,
        expires_at: datetime,
        sent_at: datetime,
    ) -> User:
        user.email_verification_token_hash = token_hash
        user.email_verification_expires_at = expires_at
        user.email_verification_sent_at = sent_at
        self.db.commit()
        self.db.refresh(user)

        return user

    def mark_email_verified(self, user: User, verified_at: datetime) -> User:
        user.email_verified_at = verified_at
        user.email_verification_required = False
        user.email_verification_token_hash = None
        user.email_verification_expires_at = None
        self.db.commit()
        self.db.refresh(user)

        return user

    def grant_analytics_lifetime_access(self, user: User) -> User:
        user.analytics_lifetime_access = True
        self.db.commit()
        self.db.refresh(user)

        return user

    def update_analytics_lifetime_access(
        self,
        user: User,
        has_access: bool,
    ) -> User:
        user.analytics_lifetime_access = has_access
        self.db.commit()
        self.db.refresh(user)

        return user

    def update_admin_role(
        self,
        user: User,
        is_admin: bool,
    ) -> User:
        user.is_admin = is_admin

        self.db.commit()
        self.db.refresh(user)

        return user
