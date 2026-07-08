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


class JobInteraction(Base):
    __tablename__ = "job_interactions"

    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "job_source",
            "job_external_id",
            "action",
            name="uq_job_interactions_user_identity_action",
        ),
    )

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        index=True,
    )

    job_title = Column(String, index=True)
    job_company = Column(String, index=True)
    job_url = Column(String)

    job_source = Column(String, nullable=True, index=True)
    job_external_id = Column(String, nullable=True, index=True)

    action = Column(String)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
