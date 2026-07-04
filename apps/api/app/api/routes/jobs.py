from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.db.models.user import User
from app.db.repositories.resume_profile_repository import ResumeProfileRepository
from app.db.session import get_db

from app.schemas.job_match_request import JobMatchRequest
from app.services.ai.factory import get_ai
from app.services.jobs.factory import get_jobs_provider
from app.services.application.job_match_service import JobMatchService
from app.services.application.job_score_service import JobScoreService

router = APIRouter(
    prefix="/jobs",
    tags=["Jobs"],
)

@router.post("/match")
def match_job(
    request: JobMatchRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):

    repository = ResumeProfileRepository(db)

    resume = repository.get_by_user_id(current_user.id)

    if resume is None:
        raise HTTPException(
            status_code=404,
            detail="Resume not found",
        )

    matcher = JobMatchService()

    return matcher.match(
        resume.resume_text,
        request.job,
    )

@router.get("/search")
def search_jobs(
    limit: int = 50,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):

    profile = ResumeProfileRepository(db).get_by_user_id(
    current_user.id
)

    if not profile:
        raise HTTPException(
        status_code=404,
        detail="Resume profile not found"
    )

    provider = get_jobs_provider()

    jobs = provider.search(
        profile.profession,
    )

    score_service = JobScoreService()

    jobs.sort(
        key=lambda job: score_service.calculate(
            profile,
            job,
        ),
        reverse=True,
    )

    return jobs[:limit]