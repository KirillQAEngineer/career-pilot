"""create application analytics adjustments

Revision ID: 7c1d8e2f4a6b
Revises: 3a8287b7287e
Create Date: 2026-07-14 00:00:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "7c1d8e2f4a6b"
down_revision: Union[str, Sequence[str], None] = "3a8287b7287e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "application_analytics_adjustments",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("total_applications", sa.Integer(), nullable=True),
        sa.Column("total_screenings", sa.Integer(), nullable=True),
        sa.Column("total_interviews", sa.Integer(), nullable=True),
        sa.Column("total_offers", sa.Integer(), nullable=True),
        sa.Column("total_rejected", sa.Integer(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "total_applications IS NULL OR total_applications >= 0",
            name="ck_analytics_total_applications_non_negative",
        ),
        sa.CheckConstraint(
            "total_screenings IS NULL OR total_screenings >= 0",
            name="ck_analytics_total_screenings_non_negative",
        ),
        sa.CheckConstraint(
            "total_interviews IS NULL OR total_interviews >= 0",
            name="ck_analytics_total_interviews_non_negative",
        ),
        sa.CheckConstraint(
            "total_offers IS NULL OR total_offers >= 0",
            name="ck_analytics_total_offers_non_negative",
        ),
        sa.CheckConstraint(
            "total_rejected IS NULL OR total_rejected >= 0",
            name="ck_analytics_total_rejected_non_negative",
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "user_id",
            name="uq_application_analytics_adjustments_user_id",
        ),
    )
    op.create_index(
        op.f("ix_application_analytics_adjustments_id"),
        "application_analytics_adjustments",
        ["id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_application_analytics_adjustments_user_id"),
        "application_analytics_adjustments",
        ["user_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_application_analytics_adjustments_user_id"),
        table_name="application_analytics_adjustments",
    )
    op.drop_index(
        op.f("ix_application_analytics_adjustments_id"),
        table_name="application_analytics_adjustments",
    )
    op.drop_table("application_analytics_adjustments")
