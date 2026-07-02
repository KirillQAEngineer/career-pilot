from fastapi import FastAPI
from app.api.routes.users import router as users_router
from app.api.routes.upload import router as upload_router
from app.api.routes.analyze import router as analyze_router
from app.api.routes.auth import router as auth_router
from app.api.routes.profile import router as profile_router
from app.api.routes.jobs import router as jobs_router

from app.api.health import router as health_router
from app.core.config import settings

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
)

app.include_router(health_router)

app.include_router(users_router)

app.include_router(upload_router)

app.include_router(analyze_router)

app.include_router(auth_router)

app.include_router(profile_router)

app.include_router(jobs_router)