from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.db.models.user import User
from app.db.repositories.resume_profile_repository import ResumeProfileRepository
from app.db.session import get_db
from app.schemas import ResumeProfileResponse

router = APIRouter(
    prefix="/profile",
    tags=["Profile"],
)


@router.get(
    "/me",
    response_model=ResumeProfileResponse,
)
def get_my_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repository = ResumeProfileRepository(db)

    profile = repository.get_by_user_id(current_user.id)

    if profile is None:
        raise HTTPException(
            status_code=404,
            detail="Resume profile not found",
        )

    return profile