"""use stable job interaction identity

Revision ID: e31ac4f79082
Revises: d55e45c32951
Create Date: 2026-07-08 12:24:47.856367

"""

from typing import Sequence, Union

from alembic import op


revision: str = "e31ac4f79082"
down_revision: Union[str, Sequence[str], None] = "d55e45c32951"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


OLD_CONSTRAINT_NAME = "uq_job_interactions_user_url_action"
NEW_CONSTRAINT_NAME = "uq_job_interactions_user_identity_action"


def upgrade() -> None:
    op.drop_constraint(
        OLD_CONSTRAINT_NAME,
        "job_interactions",
        type_="unique",
    )

    op.create_unique_constraint(
        NEW_CONSTRAINT_NAME,
        "job_interactions",
        [
            "user_id",
            "job_source",
            "job_external_id",
            "action",
        ],
    )


def downgrade() -> None:
    op.drop_constraint(
        NEW_CONSTRAINT_NAME,
        "job_interactions",
        type_="unique",
    )

    op.create_unique_constraint(
        OLD_CONSTRAINT_NAME,
        "job_interactions",
        [
            "user_id",
            "job_url",
            "action",
        ],
    )
