# Quick Reference Card

Copy-paste commands for common tasks.

## Setup

```bash
# Install dependencies
pip install -r requirements.txt

# Configure environment
bash scripts/setup-env.sh

# Or manually:
export PINECONE_API_KEY="your-api-key"
export PINECONE_INDEX="genai-assistant"
export AWS_REGION="us-east-1"
```

## Local Testing

```bash
# Test ingestion pipeline
bash scripts/test-ingestion.sh

# Run unit tests
python3 -m pytest tests/unit/ -v

# Run integration tests
INTEGRATION=1 python3 -m pytest tests/integration/ -v

# Test with sample repo (dry-run)
python3 -m ingestion.pipeline --repo /tmp/test-repo --namespace test --dry-run
```

## Deployment

```bash
# One-command deployment
bash scripts/run-all.sh

# Or step-by-step:
bash scripts/setup-env.sh      # Configure
bash scripts/deploy.sh          # Deploy to AWS
bash scripts/test-api.sh        # Verify deployment
```

## Using the Tool

```bash
# Ingest a repository
python3 -m ingestion.pipeline --repo ~/my-repo --namespace my-repo

# Ask a question
python3 -m cli.ask "How does auth work?" --namespace my-repo

# Ask with more context
python3 -m cli.ask "How does auth work?" --namespace my-repo --top-k 10

# With debug output
DEBUG=1 python3 -m cli.ask "How does auth work?" --namespace my-repo
```

## Monitoring

```bash
# View Lambda logs
aws logs tail /aws/lambda/genai-ask --follow

# Check deployment status
aws cloudformation describe-stacks \
  --stack-name genai-dev-assistant \
  --query 'Stacks[0].StackStatus'

# View Pinecone index stats
python3 << 'EOF'
from pinecone import Pinecone
import os

pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
index = pc.Index("genai-assistant")
print(index.describe_index_stats())
EOF
```

## Configuration

```bash
# View current config
cat ~/.genai-assistant/config.json

# Update API URL
cat > ~/.genai-assistant/config.json << 'EOF'
{
  "pinecone_api_key": "xxx",
  "api_url": "https://xxx.execute-api.us-east-1.amazonaws.com/prod"
}
EOF
```

## Troubleshooting

```bash
# Test AWS credentials
aws sts get-caller-identity

# Test Pinecone connection
python3 << 'EOF'
from pinecone import Pinecone
import os
pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
print(pc.describe_index_stats())
EOF

# Check if Lambda is deployed
aws lambda list-functions --region us-east-1 | grep genai-ask

# Get Lambda logs
aws logs tail /aws/lambda/genai-ask --max-items 50
```

## Cost Management

```bash
# Check Lambda invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=genai-ask \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-12-31T23:59:59Z \
  --period 86400 \
  --statistics Sum

# View Bedrock usage
aws bedrock list-foundation-models --region us-east-1

# Delete deployment (careful!)
aws cloudformation delete-stack --stack-name genai-dev-assistant
```

## API

### Request Format
```json
{
  "question": "Your question here",
  "namespace": "repo-name",
  "top_k": 6
}
```

### Direct API Call
```bash
curl -X POST https://xxx.execute-api.us-east-1.amazonaws.com/prod/ask \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How does authentication work?",
    "namespace": "my-repo",
    "top_k": 5
  }'
```

### Response Format
```json
{
  "answer": "Based on the codebase...",
  "sources": [
    {
      "file_path": "src/auth.py",
      "score": 0.92,
      "language": "python"
    }
  ]
}
```

## File Locations

```
~/.genai-assistant/config.json     - Configuration
~/.genai-assistant/debug.log       - Debug logs

/Users/xploit404/Documents/GENAI Developer/
├── README.md                       - Main documentation
├── QUICKSTART.md                   - 15-min quick start
├── SETUP.md                        - Detailed setup guide
├── DEPLOYMENT.md                   - Deployment process
├── TROUBLESHOOTING.md              - Issues & solutions
├── REFERENCE.md                    - This file
├── scripts/
│   ├── setup-env.sh                - Environment setup
│   ├── deploy.sh                   - Deploy to AWS
│   ├── test-ingestion.sh           - Test ingestion
│   ├── test-api.sh                 - Test API
│   └── run-all.sh                  - Complete pipeline
├── ingestion/                      - Ingestion modules
├── aws_lambda/                     - Lambda backend
├── cli/                            - CLI client
├── tests/                          - Test suite
├── infra/                          - AWS infrastructure
└── requirements.txt                - Dependencies
```

## Environment Variables

| Variable | Required | Example |
|----------|----------|---------|
| `PINECONE_API_KEY` | Yes | `xxx-xxx-xxx` |
| `PINECONE_INDEX` | No | `genai-assistant` |
| `API_GATEWAY_URL` | Yes (for CLI) | `https://abc.execute-api.us-east-1.amazonaws.com/prod` |
| `AWS_REGION` | No | `us-east-1` |
| `DEBUG` | No | `1` (enables debug logging) |
| `VERBOSE` | No | `1` (enables verbose output) |

## Tips

- Use `--dry-run` to preview chunks before ingesting
- Adjust `--top-k` if answers are irrelevant (try 8-10)
- Enable `VERBOSE=1` to see retrieved documents
- Enable `DEBUG=1` to see detailed logs
- Store large repos in separate namespaces
- Re-ingest after changing chunk size (edit ingestion/chunker.py)

## Links

- **Docs**: See README.md, SETUP.md, QUICKSTART.md
- **Troubleshooting**: See TROUBLESHOOTING.md
- **Code**: See source in ingestion/, aws_lambda/, cli/
- **Bedrock**: https://console.aws.amazon.com/bedrock/
- **Pinecone**: https://app.pinecone.io/
- **AWS**: https://console.aws.amazon.com/

## Version Info

- Python: 3.9+
- LangChain: 0.1.0+
- Bedrock: Claude 3.5 Haiku, Titan Embeddings
- Pinecone: 3.0.0+
- AWS Lambda: 512 MB, 30s timeout
