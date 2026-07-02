from pathlib import Path

from app.services.parsers.docx_parser import extract_docx_text
from app.services.parsers.pdf_parser import extract_pdf_text


def extract_text(file_path: Path) -> str:

    suffix = file_path.suffix.lower()

    if suffix == ".pdf":
        return extract_pdf_text(file_path)

    if suffix == ".docx":
        return extract_docx_text(file_path)

    raise ValueError("Unsupported file type")