from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings
import os

database_url = (
    settings.database_url_docker
    if os.path.exists("/.dockerenv")
    else settings.database_url
)

engine = create_engine(
    database_url,
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()