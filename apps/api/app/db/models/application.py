from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.sql import func

from app.db.models.base import Base


APPLICATION_STATUSES = (
    "applied",
    "screening",
    "interview",
    "technical_interview",
    "offer",
    "rejected",
)


class Application(Base):
    __tablename__ = "applications"

    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "job_source",
            "job_external_id",
            name="uq_applications_user_job_identity",
        ),
    )

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )

    job_title = Column(String, nullable=False, index=True)
    job_company = Column(String, nullable=False, index=True)
    job_url = Column(String, nullable=False)

    job_location = Column(String, nullable=True)
    job_work_format = Column(String, nullable=True)
    job_published_at = Column(String, nullable=True)
    job_description = Column(String, nullable=True)

    job_source = Column(String, nullable=False, index=True)
    job_external_id = Column(String, nullable=False, index=True)

    status = Column(
        String,
        nullable=False,
        default="applied",
        server_default="applied",
        index=True,
    )

    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    archived_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )
