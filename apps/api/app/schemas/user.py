from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.schemas.resume_profile_response import ResumeProfileResponse


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=9, max_length=128)
    full_name: str = Field(min_length=1, max_length=255)

    @field_validator("full_name")
    @classmethod
    def validate_full_name(cls, value: str) -> str:
        normalized = value.strip()

        if not normalized:
            raise ValueError("Full name is required")

        return normalized


class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class UserResponse(BaseModel):
    id: UUID = Field(validation_alias="public_id")
    email: EmailStr
    full_name: str
    is_admin: bool
    email_verified_at: datetime | None
    email_verification_required: bool
    analytics_lifetime_access: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class Token(BaseModel):
    access_token: str
    token_type: str


class RegistrationResponse(BaseModel):
    message: str
    email: EmailStr


class EmailVerificationRequest(BaseModel):
    email: EmailStr


class MessageResponse(BaseModel):
    message: str


class AdminStatsResponse(BaseModel):
    total_users: int
    total_admins: int


class AdminUserDetail(UserResponse):
    profile: ResumeProfileResponse | None = None


class AdminRoleUpdate(BaseModel):
    is_admin: bool


class AdminAnalyticsAccessUpdate(BaseModel):
    analytics_lifetime_access: bool
