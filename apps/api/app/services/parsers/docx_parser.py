from io import BytesIO
from docx import Document


def extract_docx_text(file_bytes: bytes) -> str:
    document = Document(BytesIO(file_bytes))

    return "\n".join(
        paragraph.text
        for paragraph in document.paragraphs
    )