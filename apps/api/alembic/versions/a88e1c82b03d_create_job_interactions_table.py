"""create job interactions table

Revision ID: a88e1c82b03d
Revises: bc88c21f53d4
Create Date: 2026-07-07 11:18:29.405164

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "a88e1c82b03d"
down_revision: Union[str, Sequence[str], None] = "bc88c21f53d4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "job_interactions",
        sa.Column(
            "id",
            sa.Integer(),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            sa.Integer(),
            nullable=True,
        ),
        sa.Column(
            "job_title",
            sa.String(),
            nullable=True,
        ),
        sa.Column(
            "job_company",
            sa.String(),
            nullable=True,
        ),
        sa.Column(
            "job_url",
            sa.String(),
            nullable=True,
        ),
        sa.Column(
            "action",
            sa.String(),
            nullable=True,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_index(
        op.f("ix_job_interactions_id"),
        "job_interactions",
        ["id"],
        unique=False,
    )

    op.create_index(
        op.f("ix_job_interactions_user_id"),
        "job_interactions",
        ["user_id"],
        unique=False,
    )

    op.create_index(
        op.f("ix_job_interactions_job_title"),
        "job_interactions",
        ["job_title"],
        unique=False,
    )

    op.create_index(
        op.f("ix_job_interactions_job_company"),
        "job_interactions",
        ["job_company"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_job_interactions_job_company"),
        table_name="job_interactions",
    )

    op.drop_index(
        op.f("ix_job_interactions_job_title"),
        table_name="job_interactions",
    )

    op.drop_index(
        op.f("ix_job_interactions_user_id"),
        table_name="job_interactions",
    )

    op.drop_index(
        op.f("ix_job_interactions_id"),
        table_name="job_interactions",
    )

    op.drop_table("job_interactions")