from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import require_analytics_access
from app.db.models.user import User
from app.db.repositories.application_repository import (
    ApplicationRepository,
)
from app.db.session import get_db
from app.schemas.application import (
    ApplicationCreate,
    ApplicationAnalyticsUpdate,
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
    current_user: User = Depends(require_analytics_access),
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
    current_user: User = Depends(require_analytics_access),
    db: Session = Depends(get_db),
):
    repository = ApplicationRepository(db)

    return repository.get_by_user_id(
        current_user.id,
    )


@router.get(
    "/archived",
    response_model=list[ApplicationResponse],
)
def get_archived_applications(
    current_user: User = Depends(require_analytics_access),
    db: Session = Depends(get_db),
):
    repository = ApplicationRepository(db)

    applications = repository.get_by_user_id(
        current_user.id,
        include_archived=True,
    )

    return [
        application
        for application in applications
        if application.archived_at is not None
    ]


@router.get(
    "/stats",
    response_model=ApplicationStatsResponse,
)
def get_application_stats(
    current_user: User = Depends(require_analytics_access),
    db: Session = Depends(get_db),
):
    repository = ApplicationRepository(db)

    return repository.get_stats(
        current_user.id,
    )


@router.patch(
    "/stats/analytics",
    response_model=ApplicationStatsResponse,
)
def update_application_analytics(
    request: ApplicationAnalyticsUpdate,
    current_user: User = Depends(require_analytics_access),
    db: Session = Depends(get_db),
):
    repository = ApplicationRepository(db)

    repository.update_analytics_adjustment(
        current_user.id,
        request.model_dump(exclude_unset=True),
    )

    return repository.get_stats(current_user.id)


@router.patch(
    "/{application_id}/status",
    response_model=ApplicationResponse,
)
def update_application_status(
    application_id: int,
    request: ApplicationStatusUpdate,
    current_user: User = Depends(require_analytics_access),
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


@router.patch(
    "/{application_id}/archive",
    response_model=ApplicationResponse,
)
def archive_application(
    application_id: int,
    current_user: User = Depends(require_analytics_access),
    db: Session = Depends(get_db),
):
    repository = ApplicationRepository(db)

    application = repository.archive(
        current_user.id,
        application_id,
    )

    if application is None:
        raise HTTPException(
            status_code=404,
            detail="Application not found",
        )

    return application


@router.patch(
    "/{application_id}/unarchive",
    response_model=ApplicationResponse,
)
def unarchive_application(
    application_id: int,
    current_user: User = Depends(require_analytics_access),
    db: Session = Depends(get_db),
):
    repository = ApplicationRepository(db)

    application = repository.unarchive(
        current_user.id,
        application_id,
    )

    if application is None:
        raise HTTPException(
            status_code=404,
            detail="Application not found",
        )

    return application
