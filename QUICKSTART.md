# Quick Start Guide

Get GenAI Assistant running in 15 minutes.

## Prerequisites

- AWS account
- Pinecone account
- `python3`, `aws-cli`, `sam-cli`

## 1. Clone and Install (2 min)

```bash
cd /Users/xploit404/Documents/GENAI\ Developer
pip install -r requirements.txt
```

## 2. Set Up Accounts (5 min)

### AWS
1. Go to AWS Console → Search "Bedrock"
2. Click "Bedrock" → "Model access" → "Manage model access"
3. Enable:
   - Amazon Titan Embeddings (amazon.titan-embed-text-v2:0)
   - Claude 3.5 Haiku (anthropic.claude-3-5-haiku-*)
4. Save changes and wait 5-10 minutes

### Pinecone
1. Go to https://pinecone.io
2. Create account and log in
3. Click "Create index":
   - Name: `genai-assistant`
   - Dimensions: `1536`
   - Metric: `cosine`
4. Wait for "Ready" status
5. Copy your API key (click your name → API keys)

## 3. Configure Environment (2 min)

```bash
bash scripts/setup-env.sh
```

When prompted:
- Enter your Pinecone API key
- Enter AWS region (default: us-east-1)
- Leave API URL blank for now

## 4. Test Locally (2 min)

```bash
bash scripts/test-ingestion.sh
```

This creates a sample repo and tests the ingestion pipeline.

## 5. Deploy to AWS (4 min)

```bash
bash scripts/deploy.sh
```

When prompted:
- Enter your Pinecone API key again
- Enter stack name (default: genai-dev-assistant)

**Save the API Endpoint URL** — you'll need it for queries.

## 6. Test the API (2 min)

```bash
bash scripts/test-api.sh
```

You should see an answer about authentication from the sample repo.

---

## Done! 🎉

Now ask questions about your own codebase:

```bash
# Ingest your repo
python3 -m ingestion.pipeline \
  --repo ~/path/to/your/repo \
  --namespace my-awesome-project

# Ask questions
python3 -m cli.ask "How does authentication work?" \
  --namespace my-awesome-project
```

---

## Troubleshooting

### "Bedrock access not available"
Wait 5-10 minutes after enabling models. Try again.

### "Could not connect to API"
Make sure you set `API_GATEWAY_URL` from deployment output:
```bash
export API_GATEWAY_URL="https://xxx.execute-api.us-east-1.amazonaws.com/prod"
```

### "PINECONE_API_KEY not set"
```bash
export PINECONE_API_KEY="your-api-key"
```

---

## Cost Estimate

- **AWS Lambda**: Free tier covers 1M requests/month
- **Bedrock**: Free tier 3 months, then ~$0.0002 per embedding
- **Pinecone**: Free tier covers 125K vectors

**Total**: Free first 3 months, then ~$5-15/month depending on usage

---

## Next Steps

1. Ingest multiple codebases (different namespaces)
2. Monitor costs in AWS Console and Pinecone
3. Iterate on chunk size and top-k for better results
4. Add authentication if sharing with team (see SETUP.md)

See [SETUP.md](SETUP.md) for detailed instructions and advanced configuration.
