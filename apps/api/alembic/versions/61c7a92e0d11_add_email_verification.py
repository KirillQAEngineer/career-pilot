"""add email verification state

Revision ID: 61c7a92e0d11
Revises: 4e8b2a1d6c90
Create Date: 2026-07-22 19:10:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "61c7a92e0d11"
down_revision: Union[str, Sequence[str], None] = "4e8b2a1d6c90"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("email_verified_at", sa.DateTime(), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column(
            "email_verification_required",
            sa.Boolean(),
            server_default=sa.false(),
            nullable=False,
        ),
    )
    op.add_column(
        "users",
        sa.Column(
            "email_verification_token_hash",
            sa.String(length=64),
            nullable=True,
        ),
    )
    op.add_column(
        "users",
        sa.Column(
            "email_verification_expires_at",
            sa.DateTime(),
            nullable=True,
        ),
    )
    op.add_column(
        "users",
        sa.Column(
            "email_verification_sent_at",
            sa.DateTime(),
            nullable=True,
        ),
    )
    op.create_index(
        op.f("ix_users_email_verification_token_hash"),
        "users",
        ["email_verification_token_hash"],
        unique=True,
    )
    op.alter_column(
        "users",
        "email_verification_required",
        server_default=sa.true(),
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_users_email_verification_token_hash"),
        table_name="users",
    )
    op.drop_column("users", "email_verification_sent_at")
    op.drop_column("users", "email_verification_expires_at")
    op.drop_column("users", "email_verification_token_hash")
    op.drop_column("users", "email_verification_required")
    op.drop_column("users", "email_verified_at")
