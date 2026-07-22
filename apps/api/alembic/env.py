import os
from logging.config import fileConfig

from alembic import context
from sqlalchemy import create_engine, pool

from app.core.config import settings
from app.db.models.base import Base

# Import every SQLAlchemy model that belongs to Base.metadata.
# Alembic autogenerate can compare only models imported here.
from app.db.models.application import Application  # noqa: F401
from app.db.models.application_analytics_adjustment import (  # noqa: F401
    ApplicationAnalyticsAdjustment,
)
from app.db.models.cached_job import CachedJob  # noqa: F401
from app.db.models.job_comment import JobComment  # noqa: F401
from app.db.models.job_interaction import JobInteraction  # noqa: F401
from app.db.models.payment import Payment  # noqa: F401
from app.db.models.resume_profile import ResumeProfile  # noqa: F401
from app.db.models.user import User  # noqa: F401


database_url = (
    settings.database_url_docker
    if os.path.exists("/.dockerenv") and settings.database_url_docker
    else settings.database_url
)

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    context.configure(
        url=database_url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={
            "paramstyle": "named",
        },
        compare_type=True,
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = create_engine(
        database_url,
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
