"""add user roles and account creation time

Revision ID: 1d7f2a9c4b8e
Revises: c4d9a7f3e2b1
Create Date: 2026-07-15 19:15:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "1d7f2a9c4b8e"
down_revision: Union[str, Sequence[str], None] = "c4d9a7f3e2b1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "is_admin",
            sa.Boolean(),
            server_default=sa.false(),
            nullable=False,
        ),
    )
    op.add_column(
        "users",
        sa.Column(
            "created_at",
            sa.DateTime(),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.execute(
        sa.text(
            "UPDATE users SET is_admin = TRUE "
            "WHERE lower(email) = 'tester.gishko@gmail.com'"
        )
    )


def downgrade() -> None:
    op.drop_column("users", "created_at")
    op.drop_column("users", "is_admin")
