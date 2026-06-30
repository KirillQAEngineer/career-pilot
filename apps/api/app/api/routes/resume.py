from fastapi import APIRouter, UploadFile, File

router = APIRouter(
    prefix="/resume",
    tags=["Resume"],
)


@router.post("/upload")
async def upload_resume(file: UploadFile = File(...)):
    content = await file.read()

    return {
        "filename": file.filename,
        "content_type": file.content_type,
        "size": len(content),
    }