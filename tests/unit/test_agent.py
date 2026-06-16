import json
from unittest.mock import patch, MagicMock

from aws_lambda.agent import CodeQAAgent


@patch("aws_lambda.agent.ChatBedrock")
@patch("aws_lambda.agent.BedrockEmbeddings")
@patch("aws_lambda.agent.PineconeRetriever")
def test_agent_no_results(mock_retriever_class, mock_embeddings_class, mock_llm_class):
    """Test agent when no results are found."""
    mock_embeddings = MagicMock()
    mock_embeddings.embed_query.return_value = [0.1, 0.2, 0.3]
    mock_embeddings_class.return_value = mock_embeddings

    mock_retriever = MagicMock()
    mock_retriever.retrieve.return_value = []
    mock_retriever_class.return_value = mock_retriever

    mock_llm = MagicMock()
    mock_llm_class.return_value = mock_llm

    agent = CodeQAAgent()
    result = agent.run("What does hello do?", "test-repo")

    assert result["answer"]
    assert "couldn't find" in result["answer"].lower()
    assert result["sources"] == []
