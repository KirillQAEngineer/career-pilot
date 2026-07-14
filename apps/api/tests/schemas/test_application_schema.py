import pytest
from pydantic import ValidationError
from typing import get_args

from app.db.models.application import APPLICATION_STATUSES
from app.schemas.application import (
    ApplicationAnalyticsUpdate,
    ApplicationStatus,
    ApplicationStatsResponse,
    ApplicationStatusUpdate,
)


@pytest.mark.parametrize(
    "status",
    APPLICATION_STATUSES,
)
def test_application_status_update_accepts_supported_statuses(
    status,
):
    request = ApplicationStatusUpdate(status=status)

    assert request.status == status


def test_application_status_update_rejects_unknown_status():
    with pytest.raises(ValidationError):
        ApplicationStatusUpdate(status="unknown_status")


def test_application_status_contract_matches_model_statuses():
    schema_statuses = set(get_args(ApplicationStatus))
    model_statuses = set(APPLICATION_STATUSES)

    assert schema_statuses == model_statuses

def test_application_stats_response_accepts_dashboard_counts():
    response = ApplicationStatsResponse(
        total_applications=10,
        total_screenings=4,
        total_interviews=3,
        total_offers=1,
        total_rejected=2,
        active_processes=6,
        screening_in_progress=2,
        interview_in_progress=1,
        technical_interview_in_progress=1,
        offer_in_progress=1,
        interviews=3,
        offers=1,
        rejected=2,
    )

    assert response.total_applications == 10
    assert response.active_processes == 6
    assert response.interviews == 3
    assert response.offers == 1
    assert response.rejected == 2


def test_application_analytics_update_accepts_partial_non_negative_values():
    request = ApplicationAnalyticsUpdate(total_interviews=4)

    assert request.model_dump(exclude_unset=True) == {
        "total_interviews": 4,
    }


def test_application_analytics_update_rejects_negative_values():
    with pytest.raises(ValidationError):
        ApplicationAnalyticsUpdate(total_offers=-1)
