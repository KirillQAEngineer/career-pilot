from app.services.parsers.pdf_parser import extract_pdf_text
from app.services.parsers.docx_parser import extract_docx_text


def extract_text(filename: str, content: bytes) -> str:

    filename = filename.lower()

    if filename.endswith(".pdf"):
        return extract_pdf_text(content)

    if filename.endswith(".docx"):
        return extract_docx_text(content)

    raise ValueError("Unsupported file type")