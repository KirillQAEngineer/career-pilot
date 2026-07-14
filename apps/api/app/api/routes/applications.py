from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.db.models.user import User
from app.db.repositories.application_repository import (
    ApplicationRepository,
)
from app.db.session import get_db
from app.schemas.application import (
    ApplicationCreate,
    ApplicationResponse,
    ApplicationStatsResponse,
    ApplicationStatusUpdate,
)


router = APIRouter(
    prefix="/applications",
    tags=["Applications"],
)


@router.post(
    "",
    response_model=ApplicationResponse,
)
def create_application(
    request: ApplicationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repository = ApplicationRepository(db)

    return repository.create_from_interaction(
        current_user.id,
        request.model_dump(),
    )


@router.get(
    "",
    response_model=list[ApplicationResponse],
)
def get_applications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repository = ApplicationRepository(db)

    return repository.get_by_user_id(
        current_user.id,
    )

@router.get(
    "/stats",
    response_model=ApplicationStatsResponse,
)
def get_application_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repository = ApplicationRepository(db)

    return repository.get_stats(
        current_user.id,
    )


@router.patch(
    "/{application_id}/status",
    response_model=ApplicationResponse,
)
def update_application_status(
    application_id: int,
    request: ApplicationStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repository = ApplicationRepository(db)

    application = repository.update_status(
        current_user.id,
        application_id,
        request.status,
    )

    if application is None:
        raise HTTPException(
            status_code=404,
            detail="Application not found",
        )

    return application
