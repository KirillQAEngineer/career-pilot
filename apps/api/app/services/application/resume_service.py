from pathlib import Path
from uuid import uuid4
import logging

from fastapi import HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.models.resume_profile import ResumeProfile
from app.db.models.user import User
from app.db.repositories.resume_profile_repository import (
    ResumeProfileRepository,
)
from app.schemas.analysis import AnalysisResponse
from app.schemas.resume_profile import ResumeProfile as ResumeProfileSchema
from app.schemas.upload import UploadResponse
from app.services.ai.factory import get_ai
from app.services.application.resume_profile_enricher import (
    ResumeProfileEnricher,
)
from app.services.parsers.parser import extract_text


UPLOAD_DIR = Path(settings.upload_dir)
UPLOAD_DIR.mkdir(exist_ok=True)
logger = logging.getLogger(__name__)


class ResumeService:

    def __init__(self, db: Session):
        self.db = db
        self.repository = ResumeProfileRepository(db)
        self.ai = None

    async def upload_resume(
        self,
        user: User,
        file: UploadFile,
    ) -> UploadResponse:

        filename = file.filename or ""

        self._validate_file(filename)

        try:
            file_path = await self._save_file(file)
        except OSError as exception:
            logger.exception("Failed to save uploaded resume")

            raise HTTPException(
                status_code=500,
                detail="Could not save uploaded resume file.",
            ) from exception

        try:
            resume_text = self._extract_text(
                file_path,
            ).strip()
        except Exception as exception:
            logger.exception("Failed to extract text from resume")

            raise HTTPException(
                status_code=400,
                detail=(
                    "Could not read text from this resume. "
                    "Please upload a text-based PDF or DOCX file."
                ),
            ) from exception
        finally:
            file_path.unlink(missing_ok=True)

        if not resume_text:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Could not find readable text in this resume. "
                    "Please upload a text-based PDF or DOCX file."
                ),
            )

        try:
            profile = self._build_resume_profile(
                resume_text,
            )

            analysis = self._analyze_resume(
                resume_text,
            )
        except Exception:
            logger.exception(
                "AI resume analysis failed. Falling back to local profile."
            )
            profile = self._fallback_profile(resume_text)
            analysis = self._fallback_analysis(resume_text)

        if profile is None:
            profile = self._fallback_profile(resume_text)

        profile = ResumeProfileEnricher().enrich(
            profile,
            resume_text,
        )

        profile = self._merge_existing_profile(
            user.id,
            profile,
        )

        if analysis is None:
            analysis = self._fallback_analysis(resume_text)

        self._save_resume_profile(
            user,
            profile,
            resume_text,
        )

        return UploadResponse(
            filename=filename,
            characters=len(resume_text),
            text=resume_text,
            analysis=analysis,
            profile=profile,
        )

    def _validate_file(
        self,
        filename: str,
    ) -> None:

        if not filename.lower().endswith((".pdf", ".docx")):
            raise HTTPException(
                status_code=400,
                detail="Only PDF and DOCX files are supported.",
            )

    async def _save_file(
        self,
        file: UploadFile,
    ) -> Path:

        suffix = Path(file.filename or "").suffix.lower()

        filename = f"{uuid4()}{suffix}"

        file_path = UPLOAD_DIR / filename

        total_bytes = 0
        first_chunk = True

        try:
            with file_path.open("wb") as destination:
                while chunk := await file.read(1024 * 1024):
                    total_bytes += len(chunk)

                    if total_bytes > settings.max_resume_upload_bytes:
                        raise HTTPException(
                            status_code=413,
                            detail="Resume file is too large. Maximum size is 5 MB.",
                        )

                    if first_chunk:
                        self._validate_file_signature(suffix, chunk)
                        first_chunk = False

                    destination.write(chunk)
        except Exception:
            file_path.unlink(missing_ok=True)
            raise

        if total_bytes == 0:
            file_path.unlink(missing_ok=True)
            raise HTTPException(status_code=400, detail="Resume file is empty.")

        return file_path

    def _validate_file_signature(self, suffix: str, content: bytes) -> None:
        valid_signature = (
            suffix == ".pdf" and content.startswith(b"%PDF-")
        ) or (
            suffix == ".docx" and content.startswith(b"PK")
        )

        if not valid_signature:
            raise HTTPException(
                status_code=400,
                detail="The uploaded file content does not match its extension.",
            )

    def _extract_text(
        self,
        file_path: Path,
    ) -> str:

        return extract_text(file_path)

    def _build_resume_profile(
        self,
        resume_text: str,
    ):

        return self._get_ai().build_resume_profile(
            resume_text,
        )

    def _analyze_resume(
        self,
        resume_text: str,
    ):

        return self._get_ai().analyze_resume(
            resume_text,
        )

    def _get_ai(self):
        if self.ai is None:
            self.ai = get_ai()

        return self.ai

    def _save_resume_profile(
        self,
        user: User,
        profile: ResumeProfileSchema,
        resume_text: str,
    ) -> ResumeProfile:

        return self.repository.upsert_from_resume(
            user_id=user.id,
            profile=profile,
            resume_text=resume_text,
        )

    def _merge_existing_profile(
        self,
        user_id: int,
        profile: ResumeProfileSchema,
    ) -> ResumeProfileSchema:
        existing = self.repository.get_by_user_id(user_id)

        if existing is None:
            return profile

        def values(value: str) -> list[str]:
            return [item.strip() for item in value.split(",") if item.strip()]

        def merge(left: list[str], right: list[str]) -> list[str]:
            result: list[str] = []
            seen: set[str] = set()

            for item in [*left, *right]:
                key = item.casefold()

                if key in seen:
                    continue

                seen.add(key)
                result.append(item)

            return result

        return profile.model_copy(
            update={
                "skills": merge(values(existing.skills), profile.skills),
                "technologies": merge(
                    values(existing.technologies),
                    profile.technologies,
                ),
                "preferred_roles": merge(
                    values(existing.preferred_roles),
                    profile.preferred_roles,
                ),
            }
        )

    def _fallback_profile(
        self,
        resume_text: str,
    ) -> ResumeProfileSchema:
        normalized = resume_text.lower()

        profession = "QA Engineer" if "qa" in normalized else "Specialist"
        level = "Senior" if "senior" in normalized else "Middle"

        profile = ResumeProfileSchema(
            profession=profession,
            level=level,
            skills=["Testing"],
            technologies=[],
            english_level="Not specified",
            preferred_roles=[profession],
        )

        return ResumeProfileEnricher().enrich(
            profile,
            resume_text,
        )

    def _fallback_analysis(
        self,
        resume_text: str,
    ) -> AnalysisResponse:
        return AnalysisResponse(
            summary=(
                "Resume was uploaded and parsed. AI analysis was not "
                "available, so JobCompass created a basic local profile."
            ),
            score=60,
            strengths=["Readable resume text was found."],
            weaknesses=["AI-based detailed analysis is temporarily unavailable."],
            recommendations=[
                "Review and edit the generated profile fields manually.",
            ],
        )
