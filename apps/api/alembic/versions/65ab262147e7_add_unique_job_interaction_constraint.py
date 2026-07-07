"""add unique job interaction constraint

Revision ID: 65ab262147e7
Revises: a88e1c82b03d
Create Date: 2026-07-07 12:02:39.370847

"""

from typing import Sequence, Union

from alembic import op


revision: str = "65ab262147e7"
down_revision: Union[str, Sequence[str], None] = "a88e1c82b03d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


CONSTRAINT_NAME = "uq_job_interactions_user_url_action"


def upgrade() -> None:
    op.create_unique_constraint(
        CONSTRAINT_NAME,
        "job_interactions",
        [
            "user_id",
            "job_url",
            "action",
        ],
    )


def downgrade() -> None:
    op.drop_constraint(
        CONSTRAINT_NAME,
        "job_interactions",
        type_="unique",
    )