# Deployment Checklist & Process

Complete deployment of GenAI Assistant to AWS Lambda.

## Pre-Deployment Checklist

- [ ] AWS account created
- [ ] Bedrock models enabled (Titan + Claude 3.5 Haiku) in us-east-1
- [ ] AWS CLI installed and configured (`aws configure`)
- [ ] AWS SAM CLI installed (`brew install aws-sam-cli`)
- [ ] Python 3.9+ installed
- [ ] Pinecone account created
- [ ] Pinecone index created ("genai-assistant")
- [ ] Pinecone API key obtained
- [ ] Project dependencies installed (`pip install -r requirements.txt`)

---

## Deployment Steps

### Phase 1: Setup (5 minutes)

Run the environment setup script:
```bash
bash scripts/setup-env.sh
```

This will:
1. Prompt for Pinecone API key
2. Create `~/.genai-assistant/config.json`
3. Test Pinecone connection
4. Export environment variables

**Verify**: Check that `~/.genai-assistant/config.json` exists and contains your API key.

### Phase 2: Test Locally (3 minutes)

Test the ingestion pipeline with sample data:
```bash
bash scripts/test-ingestion.sh
```

This will:
1. Create a temporary test repository
2. Run ingestion with `--dry-run` to verify chunking
3. Optionally ingest to Pinecone
4. Show sample chunks

**Verify**: See "Chunked into X documents" and sample chunks display.

### Phase 3: Deploy to AWS (10 minutes)

Deploy the Lambda function and API Gateway:
```bash
bash scripts/deploy.sh
```

This will:
1. Verify AWS credentials and Bedrock access
2. Build the Lambda function with SAM
3. Deploy to CloudFormation
4. Output API endpoint URL
5. Update config file with API URL

**Expected output**:
```
✅ Deployment successful!

API Endpoint: https://abc123.execute-api.us-east-1.amazonaws.com/prod/ask
Lambda ARN:   arn:aws:lambda:us-east-1:123456789012:function:genai-ask
```

**Verify**: 
- Copy the API Endpoint URL
- Set environment variable: `export API_GATEWAY_URL="https://..."`

### Phase 4: Test API (2 minutes)

Test the deployed API endpoint:
```bash
bash scripts/test-api.sh
```

This will:
1. Verify API is reachable
2. Send a sample question to Lambda
3. Test the CLI client
4. Display answer and sources

**Verify**: See an answer about authentication with sources listed.

### Phase 5: Ingest Your Codebase (varies)

Ingest a real repository:
```bash
python3 -m ingestion.pipeline \
  --repo ~/path/to/your/repo \
  --namespace my-awesome-project
```

**Options**:
- `--dry-run`: Show chunks without uploading
- `--repo`: Path to repository (required)
- `--namespace`: Pinecone namespace (required)

**Verify**: See "Successfully ingested X documents"

### Phase 6: Start Using It

Ask questions about your codebase:
```bash
python3 -m cli.ask "How does authentication work?" --namespace my-awesome-project
python3 -m cli.ask "What's the database schema?" --namespace my-awesome-project
python3 -m cli.ask "How are API endpoints structured?" --namespace my-awesome-project
```

---

## All-in-One Deployment

Run the complete pipeline with one command:
```bash
bash scripts/run-all.sh
```

This runs all phases sequentially (Phase 1-4). After completion, you'll have:
- ✅ Environment configured
- ✅ Ingestion tested with sample data
- ✅ Lambda deployed to AWS
- ✅ API endpoint verified and working

---

## Configuration Files

### `~/.genai-assistant/config.json`
```json
{
  "pinecone_api_key": "xxx-xxx-xxx",
  "pinecone_index": "genai-assistant",
  "bedrock_region": "us-east-1",
  "api_url": "https://abc123.execute-api.us-east-1.amazonaws.com/prod",
  "lambda_arn": "arn:aws:lambda:us-east-1:123456789012:function:genai-ask"
}
```

### Environment Variables
```bash
export PINECONE_API_KEY="your-api-key"
export PINECONE_INDEX="genai-assistant"
export AWS_REGION="us-east-1"
export API_GATEWAY_URL="https://abc123.execute-api.us-east-1.amazonaws.com/prod"
```

Add to `~/.zshrc` or `~/.bash_profile` to persist:
```bash
echo 'export PINECONE_API_KEY="..."' >> ~/.zshrc
echo 'export API_GATEWAY_URL="..."' >> ~/.zshrc
source ~/.zshrc
```

---

## AWS Resources Created

The deployment creates these AWS resources:

| Resource | Name | Type |
|----------|------|------|
| Lambda Function | `genai-ask` | Function (512 MB, 30s timeout) |
| API Gateway | `genai-ask-api` | HTTP API with /ask endpoint |
| IAM Role | Auto-generated | Lambda execution role |
| CloudWatch Logs | `/aws/lambda/genai-ask` | Function logs |
| CloudFormation Stack | `genai-dev-assistant` | Template (infrastructure-as-code) |

---

## Post-Deployment

### Monitor Lambda
```bash
# View logs
aws logs tail /aws/lambda/genai-ask --follow

# Check metrics
aws lambda get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=genai-ask \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-12-31T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

### Monitor Costs
- AWS Console → Cost Management → Cost Explorer
- Pinecone Console → Usage tab

### Update Deployment
After code changes:
```bash
cd infra
sam build
sam deploy  # Uses previous settings
```

### Delete Deployment
To remove everything (caution: deletes all Lambda data):
```bash
aws cloudformation delete-stack --stack-name genai-dev-assistant --region us-east-1
```

---

## Troubleshooting Deployment

**Issue**: "Bedrock access not available"
- Wait 5-10 minutes after enabling models
- Ensure you're in us-east-1 region

**Issue**: "Could not connect to API"
- Verify deployment completed successfully
- Check API_GATEWAY_URL environment variable
- View logs: `aws logs tail /aws/lambda/genai-ask`

**Issue**: "PINECONE_API_KEY not set"
- Set environment variable or update config.json
- Verify API key is correct in Pinecone console

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more issues and fixes.

---

## Success Criteria

You've successfully deployed when:
1. ✅ `bash scripts/deploy.sh` completes without errors
2. ✅ API endpoint URL is displayed and saved
3. ✅ `bash scripts/test-api.sh` returns an answer with sources
4. ✅ `python3 -m ingestion.pipeline` works
5. ✅ `python3 -m cli.ask` gets answers from Lambda

---

## Next Steps

1. **Ingest more repositories** — repeat Phase 5 for each repo
2. **Share with team** — add API authentication in Lambda handler
3. **Monitor quality** — track which questions get good answers
4. **Iterate** — adjust chunk_size/overlap for better retrieval
5. **Scale** — add caching, pagination, filtering

See [README.md](README.md) for feature details and [SETUP.md](SETUP.md) for detailed instructions.
