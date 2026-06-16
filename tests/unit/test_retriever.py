import os
from unittest.mock import patch, MagicMock

import pytest

from aws_lambda.retriever import PineconeRetriever


@pytest.fixture
def mock_pinecone():
    """Mock Pinecone client."""
    with patch("aws_lambda.retriever.Pinecone") as mock:
        yield mock


def test_retriever_init_no_api_key(mock_pinecone):
    """Test that retriever raises error without API key."""
    with patch.dict(os.environ, {}, clear=True):
        with pytest.raises(ValueError, match="PINECONE_API_KEY"):
            PineconeRetriever()


def test_retriever_init_with_api_key(mock_pinecone):
    """Test retriever initialization with API key."""
    with patch.dict(os.environ, {"PINECONE_API_KEY": "test-key"}):
        retriever = PineconeRetriever()
        assert retriever.index is not None


def test_retrieve_basic(mock_pinecone):
    """Test basic retrieval."""
    mock_index = MagicMock()
    mock_index.query.return_value = {
        "matches": [
            {
                "id": "doc-1",
                "score": 0.9,
                "metadata": {
                    "file_path": "src/main.py",
                    "text": "def main(): pass",
                    "language": "python",
                },
            },
            {
                "id": "doc-2",
                "score": 0.5,
                "metadata": {
                    "file_path": "src/utils.py",
                    "text": "def util(): pass",
                    "language": "python",
                },
            },
        ]
    }
    mock_pinecone.return_value.Index.return_value = mock_index

    with patch.dict(os.environ, {"PINECONE_API_KEY": "test-key"}):
        retriever = PineconeRetriever()
        results = retriever.retrieve(
            query_vector=[0.1, 0.2, 0.3],
            namespace="test",
            top_k=6,
            score_threshold=0.75,
        )

    assert len(results) == 1
    assert results[0]["metadata"]["file_path"] == "src/main.py"
    assert results[0]["score"] == 0.9


def test_retrieve_filters_below_threshold(mock_pinecone):
    """Test that scores below threshold are filtered."""
    mock_index = MagicMock()
    mock_index.query.return_value = {
        "matches": [
            {
                "id": "doc-1",
                "score": 0.8,
                "metadata": {"file_path": "src/main.py", "text": "code"},
            },
        ]
    }
    mock_pinecone.return_value.Index.return_value = mock_index

    with patch.dict(os.environ, {"PINECONE_API_KEY": "test-key"}):
        retriever = PineconeRetriever()
        results = retriever.retrieve(
            query_vector=[0.1, 0.2, 0.3],
            namespace="test",
            top_k=6,
            score_threshold=0.85,
        )

    assert len(results) == 0
