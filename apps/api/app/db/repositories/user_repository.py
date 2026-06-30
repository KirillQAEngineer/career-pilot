from sqlalchemy.orm import Session

from app.db.models.user import User


class UserRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(self, email: str, full_name: str):

        user = User(
            email=email,
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