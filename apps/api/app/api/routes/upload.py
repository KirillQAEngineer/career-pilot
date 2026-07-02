from pathlib import Path
from app.services.application.resume_service import ResumeService

from fastapi import APIRouter, Depends, UploadFile
from sqlalchemy.orm import Session

from app.db.session import get_db

from app.schemas.upload import UploadResponse
from app.core.dependencies import get_current_user
from app.db.models.user import User


router = APIRouter(
    prefix="/upload",
    tags=["Upload"],
)


@router.post(
    "/",
    response_model=UploadResponse,
)
async def upload_resume(
    file: UploadFile,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):

    service = ResumeService(db)

    return await service.upload_resume(
        current_user,
        file,
    )