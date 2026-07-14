from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.models.base import Base
from app.db.models.job_comment import JobComment
from app.db.models.user import User
from app.db.repositories.job_comment_repository import JobCommentRepository


def build_session():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    Base.metadata.create_all(engine)

    return sessionmaker(bind=engine)()


def create_user(db, email="comment-test@example.com"):
    user = User(
        email=email,
        hashed_password="test-password",
        full_name="Comment Test User",
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return user


def test_upsert_creates_normalized_job_comment():
    db = build_session()
    user = create_user(db)
    repository = JobCommentRepository(db)

    comment = repository.upsert(
        user.id,
        {
            "job_source": " Adzuna ",
            "job_external_id": " 123 ",
            "comment": "  Follow up on Friday.  ",
        },
    )

    assert isinstance(comment, JobComment)
    assert comment.job_source == "adzuna"
    assert comment.job_external_id == "123"
    assert comment.comment == "Follow up on Friday."

    db.close()


def test_upsert_updates_existing_comment_for_same_identity():
    db = build_session()
    user = create_user(db)
    repository = JobCommentRepository(db)

    first = repository.upsert(
        user.id,
        {
            "job_source": "adzuna",
            "job_external_id": "123",
            "comment": "First note",
        },
    )
    second = repository.upsert(
        user.id,
        {
            "job_source": "ADZUNA",
            "job_external_id": "123",
            "comment": "Updated note",
        },
    )

    assert isinstance(first, JobComment)
    assert isinstance(second, JobComment)
    assert first.id == second.id
    assert second.comment == "Updated note"
    assert db.query(JobComment).count() == 1

    db.close()


def test_empty_comment_removes_persisted_comment():
    db = build_session()
    user = create_user(db)
    repository = JobCommentRepository(db)

    repository.upsert(
        user.id,
        {
            "job_source": "adzuna",
            "job_external_id": "123",
            "comment": "Temporary note",
        },
    )

    result = repository.upsert(
        user.id,
        {
            "job_source": "adzuna",
            "job_external_id": "123",
            "comment": "   ",
        },
    )

    assert result["comment"] == ""
    assert repository.get_by_user_id(user.id) == []

    db.close()


def test_comments_are_isolated_by_user():
    db = build_session()
    first_user = create_user(db)
    second_user = create_user(db, "second-comment-test@example.com")
    repository = JobCommentRepository(db)

    for user, text in (
        (first_user, "First user note"),
        (second_user, "Second user note"),
    ):
        repository.upsert(
            user.id,
            {
                "job_source": "adzuna",
                "job_external_id": "123",
                "comment": text,
            },
        )

    first_comments = repository.get_by_user_id(first_user.id)
    second_comments = repository.get_by_user_id(second_user.id)

    assert [item.comment for item in first_comments] == ["First user note"]
    assert [item.comment for item in second_comments] == ["Second user note"]

    db.close()
