from pathlib import Path

from fastapi import APIRouter, File, HTTPException, UploadFile

from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.repositories.resume_profile_repository import ResumeProfileRepository
from fastapi import Depends

from app.schemas.upload import UploadResponse
from app.services.parsers.parser import extract_text
from app.services.ai.factory import get_ai
from app.core.dependencies import get_current_user
from app.db.models.user import User


router = APIRouter(
    prefix="/upload",
    tags=["Upload"],
)

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)


@router.post("/", response_model=UploadResponse)
async def upload_resume(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):

    filename = file.filename or ""

    if not filename.endswith((".pdf", ".docx")):
        raise HTTPException(
            status_code=400,
            detail="Only PDF and DOCX files are supported.",
        )

    content = await file.read()

    destination = UPLOAD_DIR / filename

    destination.write_bytes(content)

    text = extract_text(filename, content)

    ai = get_ai()

    analysis = ai.analyze_resume(text)
    profile = ai.build_resume_profile(text)

    repository = ResumeProfileRepository(db)

    repository.create(
    user_id=current_user.id,
    profile=profile,
    resume_text=text,
)

    return UploadResponse(
    filename=filename,
    characters=len(text),
    text=text,
    analysis=analysis,
    profile=profile,
    )  