from sqlalchemy import (
    CheckConstraint,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    UniqueConstraint,
)
from sqlalchemy.sql import func

from app.db.models.base import Base


class ApplicationAnalyticsAdjustment(Base):
    __tablename__ = "application_analytics_adjustments"

    __table_args__ = (
        UniqueConstraint(
            "user_id",
            name="uq_application_analytics_adjustments_user_id",
        ),
        CheckConstraint(
            "total_applications IS NULL OR total_applications >= 0",
            name="ck_analytics_total_applications_non_negative",
        ),
        CheckConstraint(
            "total_screenings IS NULL OR total_screenings >= 0",
            name="ck_analytics_total_screenings_non_negative",
        ),
        CheckConstraint(
            "total_interviews IS NULL OR total_interviews >= 0",
            name="ck_analytics_total_interviews_non_negative",
        ),
        CheckConstraint(
            "total_offers IS NULL OR total_offers >= 0",
            name="ck_analytics_total_offers_non_negative",
        ),
        CheckConstraint(
            "total_rejected IS NULL OR total_rejected >= 0",
            name="ck_analytics_total_rejected_non_negative",
        ),
    )

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )

    total_applications = Column(Integer, nullable=True)
    total_screenings = Column(Integer, nullable=True)
    total_interviews = Column(Integer, nullable=True)
    total_offers = Column(Integer, nullable=True)
    total_rejected = Column(Integer, nullable=True)

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
