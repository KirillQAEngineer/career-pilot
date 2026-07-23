from sqlalchemy.orm import Session

from app.db.models.resume_profile import ResumeProfile
from app.schemas.resume_profile import ResumeProfile as ResumeProfileSchema
from app.schemas.resume_profile_update import ResumeProfileUpdate


def _serialize(values: list[str]) -> str:
    return ", ".join(values)


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
            skills=_serialize(profile.skills),
            technologies=_serialize(profile.technologies),
            english_level=profile.english_level,
            preferred_roles=_serialize(profile.preferred_roles),
            resume_text=resume_text,
        )

        self.db.add(db_profile)
        self.db.commit()
        self.db.refresh(db_profile)

        return db_profile

    def get_by_user_id(
        self,
        user_id: int,
    ) -> ResumeProfile | None:

        return (
            self.db.query(ResumeProfile)
            .filter(
                ResumeProfile.user_id == user_id,
            )
            .first()
        )

    def update(
        self,
        profile: ResumeProfile,
        data: ResumeProfileUpdate,
    ) -> ResumeProfile:

        profile.profession = data.profession
        profile.level = data.level
        profile.skills = _serialize(data.skills)
        profile.technologies = _serialize(data.technologies)
        profile.english_level = data.english_level
        profile.preferred_roles = _serialize(data.preferred_roles)

        self.db.commit()
        self.db.refresh(profile)

        return profile

    def upsert_from_resume(
        self,
        user_id: int,
        profile: ResumeProfileSchema,
        resume_text: str,
    ) -> ResumeProfile:

        db_profile = self.get_by_user_id(user_id)

        if db_profile is None:
            db_profile = ResumeProfile(
                user_id=user_id,
                profession=profile.profession,
                level=profile.level,
                skills=_serialize(profile.skills),
                technologies=_serialize(profile.technologies),
                english_level=profile.english_level,
                preferred_roles=_serialize(profile.preferred_roles),
                resume_text=resume_text,
            )

            self.db.add(db_profile)

        else:
            db_profile.profession = profile.profession
            db_profile.level = profile.level
            db_profile.skills = _serialize(profile.skills)
            db_profile.technologies = _serialize(profile.technologies)
            db_profile.english_level = profile.english_level
            db_profile.preferred_roles = _serialize(profile.preferred_roles)
            db_profile.resume_text = resume_text

        self.db.commit()
        self.db.refresh(db_profile)

        return db_profile

    def delete(
        self,
        profile: ResumeProfile,
    ) -> None:

        self.db.delete(profile)
        self.db.commit()

    def clear_resume(
        self,
        profile: ResumeProfile,
    ) -> ResumeProfile:
        profile.resume_text = ""

        self.db.commit()
        self.db.refresh(profile)

        return profile
