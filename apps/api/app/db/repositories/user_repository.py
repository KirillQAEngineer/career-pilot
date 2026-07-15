from sqlalchemy.orm import Session

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
        return self.db.query(User).all()

    def get(self, user_id: int):
        return self.db.query(User).filter(User.id == user_id).first()

    def get_by_email(self, email: str):
        return self.db.query(User).filter(User.email == email).first()
