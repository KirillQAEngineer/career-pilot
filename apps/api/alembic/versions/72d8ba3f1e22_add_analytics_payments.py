"""add analytics lifetime payments

Revision ID: 72d8ba3f1e22
Revises: 61c7a92e0d11
Create Date: 2026-07-22 19:20:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "72d8ba3f1e22"
down_revision: Union[str, Sequence[str], None] = "61c7a92e0d11"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "analytics_lifetime_access",
            sa.Boolean(),
            server_default=sa.false(),
            nullable=False,
        ),
    )
    op.create_table(
        "payments",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("public_id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("provider", sa.String(length=32), nullable=False),
        sa.Column("provider_invoice_id", sa.String(length=128), nullable=True),
        sa.Column("provider_payment_id", sa.String(length=128), nullable=True),
        sa.Column("idempotency_key", sa.Uuid(), nullable=False),
        sa.Column("product", sa.String(length=64), nullable=False),
        sa.Column("amount_minor_units", sa.Integer(), nullable=False),
        sa.Column("currency", sa.String(length=16), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("confirmation_url", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("paid_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("idempotency_key"),
    )
    op.create_index(
        op.f("ix_payments_provider_invoice_id"),
        "payments",
        ["provider_invoice_id"],
        unique=True,
    )
    op.create_index(
        op.f("ix_payments_provider_payment_id"),
        "payments",
        ["provider_payment_id"],
        unique=True,
    )
    op.create_index(
        op.f("ix_payments_public_id"),
        "payments",
        ["public_id"],
        unique=True,
    )
    op.create_index(
        op.f("ix_payments_user_id"),
        "payments",
        ["user_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_payments_user_id"), table_name="payments")
    op.drop_index(op.f("ix_payments_public_id"), table_name="payments")
    op.drop_index(
        op.f("ix_payments_provider_payment_id"),
        table_name="payments",
    )
    op.drop_index(
        op.f("ix_payments_provider_invoice_id"),
        table_name="payments",
    )
    op.drop_table("payments")
    op.drop_column("users", "analytics_lifetime_access")
