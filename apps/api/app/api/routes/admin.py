from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.core.dependencies import require_admin
from app.db.models.user import User
from app.db.repositories.resume_profile_repository import (
    ResumeProfileRepository,
)
from app.db.repositories.user_repository import UserRepository
from app.db.session import get_db
from app.schemas.user import (
    AdminAnalyticsAccessUpdate,
    AdminRoleUpdate,
    AdminStatsResponse,
    AdminUserDetail,
    UserResponse,
)


router = APIRouter(
    prefix="/admin",
    tags=["Admin"],
)


@router.get("/stats", response_model=AdminStatsResponse)
def admin_stats(
    _: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    repository = UserRepository(db)

    return AdminStatsResponse(
        total_users=repository.count(),
        total_admins=repository.count_admins(),
    )


@router.get("/users", response_model=list[UserResponse])
def admin_users(
    _: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    return UserRepository(db).get_all()


@router.get("/users/{user_id}", response_model=AdminUserDetail)
def admin_user_detail(
    user_id: UUID,
    _: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    user = UserRepository(db).get_by_public_id(user_id)

    if user is None:
        raise HTTPException(404, "User not found")

    profile = ResumeProfileRepository(db).get_by_user_id(user.id)

    return AdminUserDetail(
        id=user.public_id,
        email=user.email,
        full_name=user.full_name,
        is_admin=user.is_admin,
        email_verified_at=user.email_verified_at,
        email_verification_required=user.email_verification_required,
        analytics_lifetime_access=user.analytics_lifetime_access,
        created_at=user.created_at,
        profile=profile,
    )


@router.patch("/users/{user_id}/role", response_model=UserResponse)
def update_admin_role(
    user_id: UUID,
    data: AdminRoleUpdate,
    current_admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    repository = UserRepository(db)
    user = repository.get_by_public_id(user_id)

    if user is None:
        raise HTTPException(404, "User not found")

    if user.id == current_admin.id and not data.is_admin:
        raise HTTPException(400, "You cannot remove your own administrator role")

    return repository.update_admin_role(user, data.is_admin)


@router.patch(
    "/users/{user_id}/analytics-access",
    response_model=UserResponse,
)
def update_analytics_access(
    user_id: UUID,
    data: AdminAnalyticsAccessUpdate,
    _: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    repository = UserRepository(db)
    user = repository.get_by_public_id(user_id)

    if user is None:
        raise HTTPException(404, "User not found")

    return repository.update_analytics_lifetime_access(
        user,
        data.analytics_lifetime_access,
    )
