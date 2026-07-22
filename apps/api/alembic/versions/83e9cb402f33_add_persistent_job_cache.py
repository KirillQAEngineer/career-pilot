"""add persistent job cache

Revision ID: 83e9cb402f33
Revises: 72d8ba3f1e22
Create Date: 2026-07-22 19:30:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "83e9cb402f33"
down_revision: Union[str, Sequence[str], None] = "72d8ba3f1e22"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "cached_jobs",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("query_key", sa.String(length=255), nullable=False),
        sa.Column("source", sa.String(length=100), nullable=False),
        sa.Column("external_id", sa.String(length=500), nullable=False),
        sa.Column("title", sa.String(length=500), nullable=False),
        sa.Column("company", sa.String(length=500), nullable=False),
        sa.Column("location", sa.String(length=500), nullable=False),
        sa.Column("url", sa.Text(), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("work_format", sa.String(length=100), nullable=True),
        sa.Column("published_at", sa.String(length=100), nullable=True),
        sa.Column(
            "first_seen_at",
            sa.DateTime(),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "last_seen_at",
            sa.DateTime(),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "query_key",
            "source",
            "external_id",
            name="uq_cached_jobs_query_identity",
        ),
    )
    op.create_index(
        op.f("ix_cached_jobs_last_seen_at"),
        "cached_jobs",
        ["last_seen_at"],
        unique=False,
    )
    op.create_index(
        op.f("ix_cached_jobs_query_key"),
        "cached_jobs",
        ["query_key"],
        unique=False,
    )
    op.create_index(
        op.f("ix_cached_jobs_source"),
        "cached_jobs",
        ["source"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_cached_jobs_source"), table_name="cached_jobs")
    op.drop_index(op.f("ix_cached_jobs_query_key"), table_name="cached_jobs")
    op.drop_index(
        op.f("ix_cached_jobs_last_seen_at"),
        table_name="cached_jobs",
    )
    op.drop_table("cached_jobs")
