from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from app.schemas.resume_profile_response import ResumeProfileResponse


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    full_name: str = Field(min_length=1, max_length=255)


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    email: EmailStr
    full_name: str
    is_admin: bool
    created_at: datetime

    model_config = {
        "from_attributes": True
    }


class Token(BaseModel):
    access_token: str
    token_type: str


class AdminStatsResponse(BaseModel):
    total_users: int
    total_admins: int


class AdminUserDetail(UserResponse):
    profile: ResumeProfileResponse | None = None


class AdminRoleUpdate(BaseModel):
    is_admin: bool
