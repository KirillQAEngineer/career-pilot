from datetime import datetime

from sqlalchemy import ForeignKey, String, Text, DateTime
from sqlalchemy.orm import Mapped, mapped_column

from app.db.models.base import Base


class ResumeProfile(Base):
    __tablename__ = "resume_profiles"

    id: Mapped[int] = mapped_column(primary_key=True)

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id")
    )

    profession: Mapped[str] = mapped_column(String(255))

    level: Mapped[str] = mapped_column(String(100))

    skills: Mapped[str] = mapped_column(Text)

    technologies: Mapped[str] = mapped_column(Text)

    english_level: Mapped[str] = mapped_column(String(100))

    preferred_roles: Mapped[str] = mapped_column(Text)

    resume_text: Mapped[str] = mapped_column(Text)

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
    )