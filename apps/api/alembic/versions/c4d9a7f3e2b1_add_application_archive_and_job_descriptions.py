"""add application archive and job descriptions

Revision ID: c4d9a7f3e2b1
Revises: b92f4d7a1c3e
Create Date: 2026-07-14 00:00:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c4d9a7f3e2b1"
down_revision: Union[str, Sequence[str], None] = "b92f4d7a1c3e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "applications",
        sa.Column("job_description", sa.String(), nullable=True),
    )
    op.add_column(
        "applications",
        sa.Column("archived_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "job_interactions",
        sa.Column("job_description", sa.String(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("job_interactions", "job_description")
    op.drop_column("applications", "archived_at")
    op.drop_column("applications", "job_description")
