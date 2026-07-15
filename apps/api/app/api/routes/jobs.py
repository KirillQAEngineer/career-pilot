from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.db.models.user import User
from app.db.repositories.job_comment_repository import JobCommentRepository
from app.db.repositories.job_interaction_repository import (
    JobInteractionRepository,
    build_job_identity,
    normalize_job_url,
)
from app.db.repositories.resume_profile_repository import (
    ResumeProfileRepository,
)
from app.db.session import get_db
from app.schemas.job_interaction import JobInteractionRequest
from app.schemas.job_comment import JobCommentResponse, JobCommentUpsert
from app.schemas.job_cover_letter_response import JobCoverLetterResponse
from app.schemas.job_description_response import JobDescriptionResponse
from app.schemas.job_match import JobMatch
from app.schemas.job_match_request import JobMatchRequest
from app.schemas.job_requirements import JobRequirementsResponse
from app.schemas.job_resume_response import JobResumeResponse
from app.services.application.job_description_service import (
    JobDescriptionService,
)
from app.services.application.job_cover_letter_service import (
    JobCoverLetterService,
)
from app.services.application.job_resume_service import JobResumeService
from app.services.application.job_requirements_service import (
    JobRequirementsService,
)
from app.services.application.job_score_service import JobScoreService
from app.services.jobs.factory import get_jobs_provider

router = APIRouter(
    prefix="/jobs",
    tags=["Jobs"],
)


@router.post(
    "/match",
    response_model=JobMatch,
)
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

    score = JobScoreService().score(
        resume.resume_text,
        request.job,
    )

    return JobMatch(
        job=request.job,
        match=round(score),
        pros=[],
        cons=[],
    )


@router.post(
    "/requirements",
    response_model=JobRequirementsResponse,
)
def job_requirements(
    request: JobMatchRequest,
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

    return JobRequirementsService().extract(
        request.job,
    )


@router.post(
    "/description",
    response_model=JobDescriptionResponse,
)
def job_description(
    request: JobMatchRequest,
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

    return JobDescriptionService().format(
        request.job,
    )


@router.post(
    "/cover-letter",
    response_model=JobCoverLetterResponse,
)
def job_cover_letter(
    request: JobMatchRequest,
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

    cover_letter = JobCoverLetterService().generate(
        profile,
        request.job,
    )

    return JobCoverLetterResponse(
        cover_letter=cover_letter,
    )


@router.post(
    "/resume",
    response_model=JobResumeResponse,
)
def job_resume(
    request: JobMatchRequest,
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

    resume = JobResumeService().generate(
        profile,
        request.job,
    )

    return JobResumeResponse(
        resume=resume,
    )


@router.get("/search")
def search_jobs(
    limit: int = 150,
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
    limit: int = 150,
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

    interaction_repository = JobInteractionRepository(db)

    interacted_job_identities = (
        interaction_repository.get_interacted_job_identities(
            current_user.id,
        )
    )

    legacy_interacted_job_urls = (
        interaction_repository.get_legacy_interacted_job_urls(
            current_user.id,
        )
    )

    provider = get_jobs_provider()
    jobs = provider.search(profile.profession)

    scorer = JobScoreService()

    feed = []

    for job in jobs:
        job_identity = build_job_identity(
            job.source,
            job.external_id,
        )

        if (
            job_identity is not None
            and job_identity in interacted_job_identities
        ):
            continue

        normalized_job_url = normalize_job_url(job.url)

        if (
            normalized_job_url
            and normalized_job_url in legacy_interacted_job_urls
        ):
            continue

        score = scorer.score(
            profile.resume_text,
            job,
        )

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

    return feed[: min(limit, 150)]


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


@router.get(
    "/comments",
    response_model=list[JobCommentResponse],
)
def get_job_comments(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repository = JobCommentRepository(db)

    return repository.get_by_user_id(current_user.id)


@router.put(
    "/comments",
    response_model=JobCommentResponse,
)
def upsert_job_comment(
    request: JobCommentUpsert,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repository = JobCommentRepository(db)

    return repository.upsert(
        current_user.id,
        request.model_dump(),
    )


@router.delete("/saved")
def delete_saved_job(
    job_url: str,
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
    }


@router.get("/applied")
def applied_jobs(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repository = JobInteractionRepository(db)

    return repository.get_applied_by_user_id(
        current_user.id,
    )


def _recommendation(score: float) -> str:
    if score >= 70:
        return "good_fit"

    if score >= 40:
        return "possible_fit"

    return "low_fit"
