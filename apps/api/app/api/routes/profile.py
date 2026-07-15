from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.db.models.user import User
from app.db.repositories.resume_profile_repository import (
    ResumeProfileRepository,
)
from app.db.session import get_db
from app.schemas import ResumeProfileResponse
from app.schemas.resume_profile_update import ResumeProfileUpdate
from app.schemas.resume_profile import ResumeProfile as ResumeProfileSchema

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


@router.put(
    "/me",
    response_model=ResumeProfileResponse,
)
def update_my_profile(
    data: ResumeProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repository = ResumeProfileRepository(db)

    profile = repository.get_by_user_id(current_user.id)

    if profile is None:
        return repository.create(
            user_id=current_user.id,
            profile=ResumeProfileSchema(**data.model_dump()),
            resume_text="",
        )

    return repository.update(
        profile=profile,
        data=data,
    )


@router.delete(
    "/me/resume",
    response_model=ResumeProfileResponse,
)
def delete_my_resume(
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

    return repository.clear_resume(profile)


@router.delete(
    "/me",
    status_code=204,
)
def delete_my_profile(
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

    repository.delete(profile)
