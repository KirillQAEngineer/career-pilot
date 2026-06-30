from fastapi import APIRouter, UploadFile, File, HTTPException

from app.services.parsers.parser import extract_text

router = APIRouter(
    prefix="/resume",
    tags=["Resume"],
)


@router.post("/upload")
async def upload_resume(file: UploadFile = File(...)):
    content = await file.read()

    try:
        text = extract_text(file.filename, content)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error))

    return {
        "filename": file.filename,
        "size": len(content),
        "characters": len(text),
        "preview": text[:500],
    }