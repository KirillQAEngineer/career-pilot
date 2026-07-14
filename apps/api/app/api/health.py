from fastapi import APIRouter

router = APIRouter(tags=["Health"])


@router.get("/")
async def health_check():
    return {
        "status": "ok",
        "service": "JobCompass API",
        "version": "0.1.0",
    }