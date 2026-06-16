import tempfile
from pathlib import Path

from ingestion.chunker import chunk_repository, get_language, is_text_file


def test_is_text_file():
    """Test binary file detection."""
    assert is_text_file("file.py")
    assert is_text_file("file.md")
    assert is_text_file("file.js")
    assert not is_text_file("file.png")
    assert not is_text_file("file.pyc")
    assert not is_text_file("file.zip")


def test_get_language():
    """Test language detection from file extension."""
    from langchain.text_splitter import Language

    assert get_language("file.py") == Language.PYTHON
    assert get_language("file.md") == Language.MARKDOWN
    assert get_language("file.js") == Language.JS
    assert get_language("file.ts") == Language.JS
    assert get_language("file.txt") is None


def test_chunk_repository():
    """Test repository chunking."""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)

        py_file = tmpdir / "example.py"
        py_file.write_text(
            """def hello():
    return "world"

def goodbye():
    return "farewell"
""",
            encoding="utf-8",
        )

        md_file = tmpdir / "README.md"
        md_file.write_text(
            """# Title

## Section 1

Some content here.

## Section 2

More content.
""",
            encoding="utf-8",
        )

        docs = chunk_repository(str(tmpdir), "test-namespace")

        assert len(docs) > 0

        for doc in docs:
            assert "file_path" in doc.metadata
            assert "repo" in doc.metadata
            assert "language" in doc.metadata
            assert "chunk_index" in doc.metadata
            assert doc.metadata["repo"] == "test-namespace"

        py_docs = [d for d in docs if "example.py" in d.metadata["file_path"]]
        assert len(py_docs) > 0
        assert py_docs[0].metadata["language"] == "python"

        md_docs = [d for d in docs if "README.md" in d.metadata["file_path"]]
        assert len(md_docs) > 0
        assert md_docs[0].metadata["language"] == "markdown"
