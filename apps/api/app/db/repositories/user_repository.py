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
    ) -> User:

        user = User(
            email=email,
            hashed_password=hash_password(password),
            full_name=full_name,
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

    def update_admin_role(
        self,
        user: User,
        is_admin: bool,
    ) -> User:
        user.is_admin = is_admin

        self.db.commit()
        self.db.refresh(user)

        return user
