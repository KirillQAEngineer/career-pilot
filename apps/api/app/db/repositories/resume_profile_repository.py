from sqlalchemy.orm import Session

from app.db.models.resume_profile import ResumeProfile
from app.schemas.resume_profile import ResumeProfile as ResumeProfileSchema


class ResumeProfileRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(
        self,
        user_id: int,
        profile: ResumeProfileSchema,
        resume_text: str,
    ) -> ResumeProfile:

        db_profile = ResumeProfile(
            user_id=user_id,
            profession=profile.profession,
            level=profile.level,
            skills=",".join(profile.skills),
            technologies=",".join(profile.technologies),
            english_level=profile.english_level,
            preferred_roles=",".join(profile.preferred_roles),
            resume_text=resume_text,
        )

        self.db.add(db_profile)
        self.db.commit()
        self.db.refresh(db_profile)

        return db_profile