"""create job comments

Revision ID: b92f4d7a1c3e
Revises: 7c1d8e2f4a6b
Create Date: 2026-07-14 00:00:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "b92f4d7a1c3e"
down_revision: Union[str, Sequence[str], None] = "7c1d8e2f4a6b"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "job_comments",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("job_source", sa.String(), nullable=False),
        sa.Column("job_external_id", sa.String(), nullable=False),
        sa.Column("comment", sa.Text(), nullable=False),
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
            "length(comment) <= 2000",
            name="ck_job_comments_length",
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "user_id",
            "job_source",
            "job_external_id",
            name="uq_job_comments_user_identity",
        ),
    )
    op.create_index(
        op.f("ix_job_comments_id"),
        "job_comments",
        ["id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_job_comments_job_external_id"),
        "job_comments",
        ["job_external_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_job_comments_job_source"),
        "job_comments",
        ["job_source"],
        unique=False,
    )
    op.create_index(
        op.f("ix_job_comments_user_id"),
        "job_comments",
        ["user_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_job_comments_user_id"),
        table_name="job_comments",
    )
    op.drop_index(
        op.f("ix_job_comments_job_source"),
        table_name="job_comments",
    )
    op.drop_index(
        op.f("ix_job_comments_job_external_id"),
        table_name="job_comments",
    )
    op.drop_index(
        op.f("ix_job_comments_id"),
        table_name="job_comments",
    )
    op.drop_table("job_comments")
