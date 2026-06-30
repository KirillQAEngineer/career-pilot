from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.repositories import UserRepository
from app.db.session import get_db

from app.schemas import UserCreate, UserResponse

router = APIRouter(
    prefix="/users",
    tags=["Users"],
)


@router.post(
    "",
    response_model=UserResponse,
)
def create_user(
    user: UserCreate,
    db: Session = Depends(get_db),
):

    repository = UserRepository(db)

    return repository.create(
    email=user.email,
    password=user.password,
    full_name=user.full_name,
    )


@router.get(
    "",
    response_model=list[UserResponse],
)
def get_users(
    db: Session = Depends(get_db),
):

    repository = UserRepository(db)

    return repository.get_all()