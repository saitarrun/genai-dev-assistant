# Troubleshooting Guide

## Installation & Setup

### "pip: command not found"

You need Python 3.9+. Install with:
```bash
brew install python@3.9
alias python3=$(brew --prefix python@3.9)/bin/python3.9
```

### "ModuleNotFoundError: No module named 'langchain'"

Reinstall dependencies:
```bash
pip install -r requirements.txt
```

### "aws: command not found"

Install AWS CLI:
```bash
brew install awscli
aws configure
```

### "sam: command not found"

Install AWS SAM CLI:
```bash
brew install aws-sam-cli
```

---

## AWS & Bedrock

### "An error occurred (ValidationException) when calling the GetModels operation"

**Cause**: You haven't enabled Bedrock access in us-east-1

**Fix**:
1. AWS Console → Region selector → select **us-east-1**
2. Search for "Bedrock"
3. Click "Bedrock" → "Model access"
4. Click "Manage model access"
5. Check the box for:
   - "Amazon Titan Embeddings" (amazon.titan-embed-text-v2:0)
   - "Claude 3.5 Haiku" (anthropic.claude-3-5-haiku-*)
6. Click "Save changes"
7. Wait 5-10 minutes for approval
8. Retry deployment

### "AccessDenied: User is not authorized to perform: bedrock:InvokeModel"

**Cause**: IAM role doesn't have Bedrock permissions

**Fix**:
1. Check Lambda execution role has `bedrock:InvokeModel` permission
2. Run: `aws iam get-role-policy --role-name <lambda-role> --policy-name <policy-name>`
3. Verify policy includes:
```json
{
  "Effect": "Allow",
  "Action": "bedrock:InvokeModel",
  "Resource": "arn:aws:bedrock:us-east-1::foundation-model/*"
}
```

### "Unable to locate credentials. You can configure credentials by running aws configure"

**Cause**: AWS credentials not set

**Fix**:
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output (json)
```

---

## Pinecone

### "Exception: The official Pinecone python package has been renamed"

**Cause**: Wrong package installed (`pinecone-client` instead of `pinecone`)

**Fix**:
```bash
pip uninstall pinecone-client
pip install pinecone
```

### "PINECONE_API_KEY environment variable not set"

**Fix**:
```bash
export PINECONE_API_KEY="your-api-key-here"
```

Or add to `~/.genai-assistant/config.json`:
```json
{
  "pinecone_api_key": "your-api-key-here"
}
```

### "Index genai-assistant does not exist"

**Cause**: You haven't created the Pinecone index

**Fix**:
1. Go to https://app.pinecone.io/
2. Click "Create index"
3. Name: `genai-assistant`
4. Dimensions: `1536`
5. Metric: `cosine`
6. Click "Create"
7. Wait for status to show "Ready"

### "Failed to connect to Pinecone: 401"

**Cause**: Invalid or expired API key

**Fix**:
1. Go to https://app.pinecone.io/
2. Click your name → "API keys"
3. Copy the correct API key
4. Update `~/.genai-assistant/config.json` or `PINECONE_API_KEY`

### "Failed to connect to Pinecone: 404"

**Cause**: Index doesn't exist or wrong index name

**Fix**:
1. Verify index name is `genai-assistant`
2. Check Pinecone console that index status is "Ready"
3. If not ready, wait a few minutes

---

## Ingestion

### "ModuleNotFoundError: No module named 'ingestion'"

**Cause**: Not running from project root directory

**Fix**:
```bash
cd /Users/xploit404/Documents/GENAI\ Developer
python3 -m ingestion.pipeline --repo ... --namespace ...
```

### "FileNotFoundError: Repository path does not exist: /path/to/repo"

**Cause**: Invalid repository path

**Fix**:
```bash
# Check the path exists
ls /path/to/repo

# Use absolute path
python3 -m ingestion.pipeline --repo ~/projects/my-app --namespace my-app
```

### "UnicodeDecodeError: 'utf-8' codec can't decode byte"

**Cause**: Binary file detected as text

**Fix**: This is normal — the chunker skips it automatically. Check logs to see which file.

### "Chunked into 0 documents"

**Cause**: Repository is empty or only contains unsupported file types

**Fix**:
- Add some `.py`, `.js`, `.md` files to the repository
- Check that the path is correct

---

## Lambda & Deployment

### "sam: error: unresolved S3 URI"

**Cause**: S3 bucket for SAM artifacts not specified

**Fix**:
```bash
cd infra
sam deploy --guided
# When asked about S3 bucket: let SAM create one (just press Enter)
```

### "Failed to create changeset for the stack"

**Cause**: CloudFormation template has errors

**Fix**:
1. Check `infra/template.yaml` syntax
2. Verify `PINECONE_API_KEY` parameter is provided
3. Try deleting and redeploying:
```bash
aws cloudformation delete-stack --stack-name genai-dev-assistant
sam deploy --guided
```

### "Stack creation/update failed"

**Cause**: Various CloudFormation errors

**Fix**:
```bash
# Check stack events
aws cloudformation describe-stack-events \
  --stack-name genai-dev-assistant \
  --region us-east-1

# Check Lambda logs
aws logs tail /aws/lambda/genai-ask --follow
```

---

## API & Queries

### "Could not connect to API at https://..."

**Cause**: Lambda not deployed or API URL is wrong

**Fix**:
```bash
# Verify deployment
aws lambda list-functions --region us-east-1 | grep genai-ask

# Get correct API URL
aws cloudformation describe-stacks \
  --stack-name genai-dev-assistant \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
  --output text

# Set environment variable
export API_GATEWAY_URL="https://xxx.execute-api.us-east-1.amazonaws.com/prod"
```

### "Error: 400 - Missing 'question' field"

**Cause**: Malformed API request

**Fix**:
```bash
# Correct usage
python3 -m cli.ask "Your question" --namespace my-repo

# Or raw API call
curl -X POST https://xxx.execute-api.us-east-1.amazonaws.com/prod/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "Your question", "namespace": "my-repo"}'
```

### "Error: 404 - No vectors found"

**Cause**: Repository not ingested or wrong namespace

**Fix**:
```bash
# Ingest the repository
python3 -m ingestion.pipeline --repo ~/your-repo --namespace your-repo

# Check Pinecone has vectors
python3 << 'EOF'
from pinecone import Pinecone
import os

pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
index = pc.Index("genai-assistant")
stats = index.describe_index_stats()
print(f"Namespaces: {stats['namespaces'].keys()}")
print(f"Total vectors: {stats['total_vector_count']}")
EOF
```

### "Answer is irrelevant or hallucinated"

**Cause**: Retrieval quality issue

**Fix**:
1. Increase `--top-k`:
```bash
python3 -m cli.ask "Your question" --namespace my-repo --top-k 10
```

2. Check what documents are retrieved:
```bash
VERBOSE=1 python3 -m cli.ask "Your question" --namespace my-repo
```

3. Adjust chunk size in `ingestion/chunker.py`:
```python
# Make chunks smaller for more granular retrieval
splitter = RecursiveCharacterTextSplitter(
    chunk_size=500,    # was 1000
    chunk_overlap=100  # was 200
)
```

4. Re-ingest after changing chunk size:
```bash
python3 -m ingestion.pipeline --repo ~/your-repo --namespace your-repo
```

---

## Logs & Debugging

### View Lambda Logs

```bash
# Real-time logs
aws logs tail /aws/lambda/genai-ask --follow

# Last 100 lines
aws logs tail /aws/lambda/genai-ask --max-items 100
```

### Enable Debug Logging

```bash
# Local testing
DEBUG=1 python3 -m cli.ask "Your question" --namespace my-repo
cat ~/.genai-assistant/debug.log

# Lambda (add to environment variables in template.yaml)
DEBUG=1 python3 -m cli.ask "Your question" --namespace my-repo
```

### Check Deployment Status

```bash
# Get stack status
aws cloudformation describe-stacks \
  --stack-name genai-dev-assistant \
  --query 'Stacks[0].StackStatus'

# Get all resources
aws cloudformation list-stack-resources \
  --stack-name genai-dev-assistant
```

---

## Cost Issues

### "Unexpected AWS charges"

**Check**:
1. Lambda invocation count: AWS Console → Lambda → Metrics
2. Bedrock usage: AWS Console → Bedrock → Usage
3. Pinecone usage: https://app.pinecone.io/ → Usage

**Reduce**:
- Limit ingestion to necessary repositories
- Use smaller chunk sizes (fewer vectors stored)
- Reduce --top-k parameter
- Set up CloudWatch alarms for spending

---

## Getting Help

1. Check logs: `aws logs tail /aws/lambda/genai-ask --follow`
2. Test locally first: `bash scripts/test-ingestion.sh`
3. Verify credentials: `aws sts get-caller-identity`
4. Check configuration: `cat ~/.genai-assistant/config.json`

Still stuck? Review the [SETUP.md](SETUP.md) guide or check the project README.
