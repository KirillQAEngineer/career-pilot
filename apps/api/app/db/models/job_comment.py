from sqlalchemy import (
    CheckConstraint,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.sql import func

from app.db.models.base import Base


class JobComment(Base):
    __tablename__ = "job_comments"

    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "job_source",
            "job_external_id",
            name="uq_job_comments_user_identity",
        ),
        CheckConstraint(
            "length(comment) <= 2000",
            name="ck_job_comments_length",
        ),
    )

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )

    job_source = Column(String, nullable=False, index=True)
    job_external_id = Column(String, nullable=False, index=True)

    comment = Column(Text, nullable=False)

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
