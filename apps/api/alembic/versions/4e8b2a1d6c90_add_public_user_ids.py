"""add public UUID identifiers to users

Revision ID: 4e8b2a1d6c90
Revises: 1d7f2a9c4b8e
Create Date: 2026-07-22 18:00:00.000000

"""

from typing import Sequence, Union
from uuid import uuid4

from alembic import op
import sqlalchemy as sa


revision: str = "4e8b2a1d6c90"
down_revision: Union[str, Sequence[str], None] = "1d7f2a9c4b8e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("public_id", sa.Uuid(), nullable=True),
    )

    connection = op.get_bind()
    user_ids = connection.execute(sa.text("SELECT id FROM users")).scalars()

    for user_id in user_ids:
        connection.execute(
            sa.text(
                "UPDATE users SET public_id = :public_id WHERE id = :user_id"
            ),
            {"public_id": uuid4(), "user_id": user_id},
        )

    op.alter_column("users", "public_id", nullable=False)
    op.create_index(
        op.f("ix_users_public_id"),
        "users",
        ["public_id"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_users_public_id"), table_name="users")
    op.drop_column("users", "public_id")
