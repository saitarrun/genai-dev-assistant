# GenAI Developer Productivity Assistant

An AI-powered CLI tool that answers natural-language questions about your codebases using LLMs and RAG (Retrieval-Augmented Generation).

## Features

- **Code-aware chunking**: Language-aware text splitting for Python, JavaScript, Markdown, and more
- **Vector search**: Pinecone-powered semantic search over your codebase
- **Source citation**: Answers include file paths and relevance scores
- **Serverless backend**: AWS Lambda + API Gateway for scalable inference
- **Local CLI client**: Lightweight client for asking questions

## Architecture

```
Local Repository
        ↓
  [Ingestion Pipeline] ← chunks code with language-aware splitting
        ↓
  [Bedrock Embeddings] ← amazon.titan-embed-text-v2:0
        ↓
  [Pinecone Vector Store] ← stores vectors per repository namespace
        ↓
  [AWS Lambda] ← runs RAG chain with Claude 3.5 Haiku
        ↓
  [CLI Client] ← asks questions, gets source-cited answers
```

## Quick Start

### Prerequisites

- Python 3.9+
- AWS Account with Bedrock access (us-east-1)
- Pinecone account and index named `genai-assistant`
- AWS SAM CLI (for deployment)

### Installation

```bash
pip install -r requirements.txt
```

### Configuration

Set environment variables:

```bash
export PINECONE_API_KEY="your-pinecone-api-key"
export PINECONE_INDEX="genai-assistant"
```

### Ingest a Repository

```bash
python -m ingestion.pipeline --repo ~/projects/my-app --namespace my-app
```

Options:
- `--dry-run`: Preview chunks without embedding/upserting

### Ask a Question

```bash
python -m cli.ask "How does authentication work?" --namespace my-app
```

The answer includes source file paths and relevance scores.

## Development

### Run Unit Tests

```bash
pytest tests/unit/ -v
```

### Run Integration Tests

```bash
INTEGRATION=1 pytest tests/integration/ -v
```

### Deploy to AWS

```bash
cd infra
sam build
sam deploy --guided
```

The deployment will prompt for:
- Stack name
- AWS region
- Pinecone API key

After deployment, set the API Gateway URL:

```bash
export API_GATEWAY_URL="https://xxx.execute-api.us-east-1.amazonaws.com/prod"
```

## Debugging

Enable verbose logs:

```bash
VERBOSE=1 python -m cli.ask "Your question" --namespace repo
DEBUG=1 python -m cli.ask "Your question" --namespace repo
```

Logs are written to `~/.genai-assistant/debug.log`.

## Project Structure

```
genai-dev-assistant/
├── ingestion/          # Repository ingestion pipeline
│   ├── chunker.py      # Language-aware text splitting
│   ├── embedder.py     # Bedrock embeddings wrapper
│   └── pipeline.py     # CLI ingestion command
├── lambda/             # AWS Lambda backend
│   ├── handler.py      # Lambda entry point
│   ├── retriever.py    # Pinecone query wrapper
│   └── agent.py        # LangChain RAG chain
├── cli/                # Local CLI client
│   └── ask.py          # Question answering CLI
├── tests/              # Unit and integration tests
└── infra/              # AWS SAM infrastructure
    └── template.yaml   # CloudFormation template
```

## Retrieval Quality

The retrieval pipeline includes several tuning knobs:

1. **Chunk overlap** (default: 200 tokens) — prevents answers split across boundaries
2. **Score threshold** (default: 0.75) — filters low-relevance chunks
3. **Top-k** (default: 6) — number of documents to send to the LLM
4. **Chunk size** (default: 1000 tokens) — balance between granularity and context

Adjust these in `ingestion/chunker.py` and `lambda/agent.py`.

## Limitations

- Requires Bedrock access in us-east-1
- Limited to publicly-accessible codebases (no secret management yet)
- Claude 3.5 Haiku may hallucinate on complex multi-file questions
- No caching of embeddings (re-embedding on each query)

## Future Improvements

- [ ] Multi-repository cross-searching
- [ ] Incremental updates (only re-index changed files)
- [ ] Conversation context (remember prior questions)
- [ ] Cost tracking per repository
- [ ] Web UI dashboard
