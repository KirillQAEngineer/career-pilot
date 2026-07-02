from pathlib import Path

import fitz


def extract_pdf_text(file_path: Path) -> str:
    text = ""

    with fitz.open(file_path) as pdf:
        for page in pdf:
            text += page.get_text()

    return text