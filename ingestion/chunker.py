import os
from pathlib import Path
from typing import List, Optional

from langchain.schema import Document
from langchain.text_splitter import RecursiveCharacterTextSplitter, Language

LANGUAGE_EXTENSIONS = {
    ".py": Language.PYTHON,
    ".js": Language.JS,
    ".jsx": Language.JS,
    ".ts": Language.JS,
    ".tsx": Language.JS,
    ".md": Language.MARKDOWN,
    ".mdx": Language.MARKDOWN,
    ".java": Language.JAVA,
    ".c": Language.C,
    ".cpp": Language.CPP,
    ".go": Language.GO,
    ".rs": Language.RUST,
    ".rb": Language.RUBY,
}

SKIP_DIRS = {".git", "node_modules", "__pycache__", ".venv", "venv", ".env", "dist", "build"}
SKIP_FILES = {".gitignore", ".env", ".env.local", ".DS_Store"}
BINARY_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".zip", ".tar", ".gz", ".pyc", ".o", ".so"}


def is_text_file(filepath: str) -> bool:
    ext = Path(filepath).suffix.lower()
    return ext not in BINARY_EXTENSIONS


def get_language(filepath: str) -> Optional[Language]:
    ext = Path(filepath).suffix.lower()
    return LANGUAGE_EXTENSIONS.get(ext)


def chunk_repository(repo_path: str, namespace: str) -> List[Document]:
    """Walk a repository, chunk text files with language-aware splitting."""
    repo_path = Path(repo_path).resolve()
    if not repo_path.is_dir():
        raise ValueError(f"Repository path does not exist: {repo_path}")

    documents = []
    splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)

    for root, dirs, files in os.walk(repo_path):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]

        for filename in files:
            if filename in SKIP_FILES:
                continue

            filepath = Path(root) / filename
            if not is_text_file(str(filepath)):
                continue

            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()
            except (UnicodeDecodeError, PermissionError):
                continue

            if not content.strip():
                continue

            language = get_language(str(filepath))
            separators = None
            if language:
                try:
                    separators = RecursiveCharacterTextSplitter.get_separators_for_language(
                        language
                    )
                except Exception:
                    pass

            if separators:
                file_splitter = RecursiveCharacterTextSplitter(
                    separators=separators, chunk_size=1000, chunk_overlap=200
                )
            else:
                file_splitter = splitter

            chunks = file_splitter.split_text(content)
            relative_path = str(filepath.relative_to(repo_path))

            for i, chunk in enumerate(chunks):
                doc = Document(
                    page_content=chunk,
                    metadata={
                        "file_path": relative_path,
                        "repo": namespace,
                        "language": language.value if language else "text",
                        "chunk_index": i,
                        "absolute_path": str(filepath),
                    },
                )
                documents.append(doc)

    return documents
