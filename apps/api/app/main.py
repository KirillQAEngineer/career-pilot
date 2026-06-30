from fastapi import FastAPI
from app.api.routes.resume import router as resume_router
from app.api.routes.users import router as users_router

from app.api.health import router as health_router
from app.core.config import settings

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
)

app.include_router(health_router)

app.include_router(resume_router)

app.include_router(users_router)