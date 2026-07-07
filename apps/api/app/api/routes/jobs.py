from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.db.models.user import User
from app.db.repositories.job_interaction_repository import (
    JobInteractionRepository,
)
from app.db.repositories.resume_profile_repository import (
    ResumeProfileRepository,
)
from app.db.session import get_db

from app.schemas.job_interaction import JobInteractionRequest
from app.schemas.job_match_request import JobMatchRequest

from app.services.application.job_match_service import JobMatchService
from app.services.application.job_score_service import JobScoreService
from app.services.jobs.factory import get_jobs_provider

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
    resume = ResumeProfileRepository(db).get_by_user_id(
        current_user.id,
    )

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
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = ResumeProfileRepository(db).get_by_user_id(
        current_user.id,
    )

    if profile is None:
        raise HTTPException(
            status_code=404,
            detail="Resume profile not found",
        )

    provider = get_jobs_provider()
    jobs = provider.search(profile.profession)

    score_service = JobScoreService()

    results = []

    for job in jobs:
        score = score_service.score(
            profile.resume_text,
            job,
        )

        results.append(
            {
                "job": job,
                "score": score,
                "why_match": (
                    "Rule-based match calculated "
                    "from resume."
                ),
                "missing_skills": [],
                "recommendation": _recommendation(score),
            }
        )

    results.sort(
        key=lambda x: x["score"],
        reverse=True,
    )

    return results[:limit]


@router.get("/feed")
def jobs_feed(
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = ResumeProfileRepository(db).get_by_user_id(
        current_user.id,
    )

    if profile is None:
        raise HTTPException(
            status_code=404,
            detail="Resume profile not found",
        )

    provider = get_jobs_provider()
    jobs = provider.search(profile.profession)

    scorer = JobScoreService()

    feed = []

    for job in jobs:
        score = scorer.score(
            profile.resume_text,
            job,
        )

        if score < 20:
            continue

        feed.append(
            {
                "job": job,
                "score": score,
                "why_match": (
                    "Rule-based match calculated "
                    "from resume."
                ),
                "missing_skills": [],
                "recommendation": _recommendation(score),
            }
        )

    feed.sort(
        key=lambda x: x["score"],
        reverse=True,
    )

    return feed[:limit]


@router.post("/interact")
def interact(
    request: JobInteractionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repository = JobInteractionRepository(db)

    return repository.create(
        current_user.id,
        request.model_dump(),
    )


@router.get("/saved")
def saved_jobs(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repository = JobInteractionRepository(db)

    return repository.get_saved_by_user_id(
        current_user.id,
    )


@router.delete("/saved")
def delete_saved_job(
    job_url: str = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repository = JobInteractionRepository(db)

    deleted = repository.delete_saved_by_user_and_url(
        current_user.id,
        job_url,
    )

    if not deleted:
        raise HTTPException(
            status_code=404,
            detail="Saved job not found",
        )

    return {
        "deleted": True,
        "job_url": job_url,
    }


def _recommendation(score: float) -> str:
    if score >= 70:
        return "good_fit"

    if score >= 40:
        return "possible_fit"

    return "low_fit"