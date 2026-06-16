# GenAI Developer Assistant — Complete Setup Guide

Follow this guide to set up and deploy the GenAI Developer Productivity Assistant to AWS.

## Prerequisites

- AWS Account (free tier eligible)
- Pinecone Account (free tier available)
- macOS/Linux with `python3`, `pip`, `aws-cli`, `sam-cli`
- Git

---

## Step 1: Create AWS Account & Configure CLI

### 1.1 Create AWS Account (if needed)
- Go to https://aws.amazon.com/
- Sign up for free tier (includes Lambda free tier, Bedrock for 3 months)
- Verify email and set up billing

### 1.2 Request Bedrock Access
Bedrock is required for Claude and Titan embeddings.

1. Log into AWS Console → Region: **us-east-1** (required for this project)
2. Search for "Bedrock" → Click "Bedrock"
3. Click "Model access" (left sidebar)
4. Click "Manage model access" (orange button)
5. Enable:
   - **Amazon Titan Embeddings** (amazon.titan-embed-text-v2:0)
   - **Claude 3.5 Haiku** (anthropic.claude-3-5-haiku-*)
6. Click "Save changes"
7. Wait 5-10 minutes for approval (usually instant)

### 1.3 Create AWS Access Keys

1. AWS Console → Top-right menu → "Security credentials"
2. Under "Access keys" → "Create access key"
3. Choose "Command Line Interface (CLI)"
4. Accept terms → "Create access key"
5. **Download .csv file** (contains Access Key ID and Secret Access Key)
6. **Keep this secure** — don't commit to git

### 1.4 Configure AWS CLI

```bash
aws configure
```

When prompted, enter:
- **AWS Access Key ID**: (from Step 1.3)
- **Secret Access Key**: (from Step 1.3)
- **Default region name**: `us-east-1`
- **Default output format**: `json`

Verify configuration:
```bash
aws sts get-caller-identity
```

---

## Step 2: Create Pinecone Index

### 2.1 Create Pinecone Account
1. Go to https://www.pinecone.io/
2. Sign up (free tier: 1 index, 125K vectors)
3. Verify email

### 2.2 Create Your First Index

1. Log into Pinecone console
2. Click "Create index"
3. Enter details:
   - **Name**: `genai-assistant`
   - **Dimensions**: `1536` (Titan embedding size)
   - **Metric**: `cosine`
   - **Environment**: `gcp-starter` (free tier)
4. Click "Create index"
5. Wait for status to show "Ready" (1-2 minutes)

### 2.3 Get Pinecone API Key

1. Click your name (top-right) → "API keys"
2. Copy your API key (or create new if needed)
3. **Save this somewhere safe** — you'll need it soon

---

## Step 3: Install Dependencies

### 3.1 Clone/Navigate to Project

```bash
cd /Users/xploit404/Documents/GENAI\ Developer
```

### 3.2 Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 3.3 Install AWS SAM CLI (if needed)

```bash
brew install aws-sam-cli
```

Verify installation:
```bash
sam --version
```

---

## Step 4: Configure Environment

### 4.1 Create Configuration Directory

```bash
mkdir -p ~/.genai-assistant
```

### 4.2 Create Config File

```bash
cat > ~/.genai-assistant/config.json << 'EOF'
{
  "pinecone_api_key": "YOUR_PINECONE_API_KEY_HERE",
  "pinecone_index": "genai-assistant",
  "bedrock_region": "us-east-1"
}
EOF
```

**Replace** `YOUR_PINECONE_API_KEY_HERE` with your actual Pinecone API key from Step 2.3.

### 4.3 Set Environment Variables

```bash
export PINECONE_API_KEY="your-pinecone-api-key"
export PINECONE_INDEX="genai-assistant"
export AWS_REGION="us-east-1"
```

Verify Pinecone connection:
```bash
python3 << 'EOF'
import os
from pinecone import Pinecone

api_key = os.getenv("PINECONE_API_KEY")
pc = Pinecone(api_key=api_key)
index = pc.Index("genai-assistant")
print("✓ Successfully connected to Pinecone")
print(f"Index stats: {index.describe_index_stats()}")
EOF
```

---

## Step 5: Test Ingestion Locally

### 5.1 Create a Test Repository

```bash
mkdir -p /tmp/test-repo
cat > /tmp/test-repo/main.py << 'EOF'
def authenticate_user(username, password):
    """Verify user credentials against the database."""
    import hashlib
    hashed = hashlib.sha256(password.encode()).hexdigest()
    return db.verify(username, hashed)

def get_user_profile(user_id):
    """Retrieve user profile information."""
    user = db.query(f"SELECT * FROM users WHERE id = {user_id}")
    return {
        "name": user.name,
        "email": user.email,
        "created_at": user.created_at
    }
EOF

cat > /tmp/test-repo/database.py << 'EOF'
class Database:
    def __init__(self, connection_string):
        self.conn = self.create_connection(connection_string)
        self.pool = []

    def create_pool(self, size=10):
        """Initialize a connection pool for concurrent requests."""
        for i in range(size):
            self.pool.append(self.create_connection())

    def query(self, sql):
        """Execute a SQL query and return results."""
        return self.conn.execute(sql).fetchall()
EOF

cat > /tmp/test-repo/README.md << 'EOF'
# Test Application

Simple authentication and database module.

## Features

- User authentication with SHA256 hashing
- Database connection pooling
- User profile retrieval

## Usage

```python
from main import authenticate_user, get_user_profile

# Authenticate
if authenticate_user("alice", "password123"):
    profile = get_user_profile(1)
    print(profile)
```
EOF
```

### 5.2 Run Ingestion Pipeline

```bash
python3 -m ingestion.pipeline \
  --repo /tmp/test-repo \
  --namespace test-repo \
  --dry-run
```

You should see:
```
✓ Chunked into 8 documents

Sample chunks (--dry-run):
Chunk 0 (main.py)
def authenticate_user(username, password):
    """Verify user credentials against the database."""
...
```

### 5.3 Actually Ingest (with Pinecone)

```bash
python3 -m ingestion.pipeline \
  --repo /tmp/test-repo \
  --namespace test-repo
```

You should see:
```
✓ Successfully ingested 8 documents
```

---

## Step 6: Deploy to AWS

### 6.1 Build the Lambda Function

```bash
cd infra
sam build
```

Expected output:
```
Build Succeeded
Built Artifacts  : .aws-sam/build
Built Template   : .aws-sam/build/template.yaml
```

### 6.2 Deploy to AWS

```bash
sam deploy --guided
```

When prompted, enter:
```
Stack Name: genai-dev-assistant
Region: us-east-1
Confirm changes before deploy: y
Allow SAM CLI IAM role: y
AskFunction may not have authorization defined: y (OK for personal use)

Parameters:
  PineconeApiKey: <your-pinecone-api-key>
  PineconeIndexName: genai-assistant
```

Wait for deployment (5-10 minutes). You'll see:
```
✓ Deployment Successful

Outputs:
Key                 Value
---                 ------
AskFunctionArn      arn:aws:lambda:us-east-1:xxx:function:genai-ask
ApiEndpoint         https://abc123.execute-api.us-east-1.amazonaws.com/prod/ask
```

### 6.3 Save the API Endpoint

```bash
cat > ~/.genai-assistant/config.json << 'EOF'
{
  "pinecone_api_key": "your-pinecone-api-key",
  "pinecone_index": "genai-assistant",
  "bedrock_region": "us-east-1",
  "api_url": "https://xxx.execute-api.us-east-1.amazonaws.com/prod"
}
EOF
```

Replace `xxx` with the actual endpoint from the deployment output.

---

## Step 7: Test the Deployed System

### 7.1 Ask a Question

```bash
export API_GATEWAY_URL="https://xxx.execute-api.us-east-1.amazonaws.com/prod"

python3 -m cli.ask "How does authentication work?" --namespace test-repo
```

You should see:
```
## Answer

Based on the codebase, authentication is handled in the main.py file...

Sources:
┏━━━━━━━━━━━━┳━━━━━━━━━━┳━━━━━━━━━━┓
┃ File       ┃ Language ┃ Relevance┃
┡━━━━━━━━━━━━╇━━━━━━━━━━╇━━━━━━━━━━┩
│ main.py    │ python   │ 92%      │
│ README.md  │ markdown │ 78%      │
└────────────┴──────────┴──────────┘
```

### 7.2 Enable Debug Logging

```bash
DEBUG=1 python3 -m cli.ask "How is the database connected?" --namespace test-repo
cat ~/.genai-assistant/debug.log
```

---

## Step 8: Ingest Your Own Codebase

### 8.1 Ingest a Real Repository

```bash
python3 -m ingestion.pipeline \
  --repo ~/path/to/your/repo \
  --namespace my-awesome-project
```

Example:
```bash
python3 -m ingestion.pipeline \
  --repo ~/projects/my-app \
  --namespace my-app
```

### 8.2 Ask Questions

```bash
python3 -m cli.ask "How does the authentication module work?" --namespace my-app
python3 -m cli.ask "What's the database schema?" --namespace my-app
python3 -m cli.ask "How are API endpoints structured?" --namespace my-app
```

---

## Troubleshooting

### Issue: "ModuleNotFoundError: No module named 'langchain'"

**Fix:**
```bash
pip install -r requirements.txt
```

### Issue: "PINECONE_API_KEY environment variable not set"

**Fix:**
```bash
export PINECONE_API_KEY="your-actual-pinecone-key"
```

### Issue: "Could not connect to API at https://..."

**Fix:** Check that:
1. Lambda is deployed: `aws lambda list-functions`
2. API Gateway endpoint is correct (from deployment output)
3. Set environment variable: `export API_GATEWAY_URL="https://..."`

### Issue: "Bedrock access not available"

**Fix:** Request access in AWS Console (Step 1.2) and wait 5-10 minutes

### Issue: "Index genai-assistant does not exist"

**Fix:** Create the index in Pinecone console (Step 2.2)

---

## Running Tests Locally

### Unit Tests
```bash
python3 -m pytest tests/unit/ -v
```

### Integration Tests
```bash
INTEGRATION=1 python3 -m pytest tests/integration/ -v
```

---

## Monitoring & Cost

### AWS Costs
- **Lambda**: Free tier covers 1M requests/month
- **Bedrock**: Free tier for first 3 months, then ~$0.0002 per embedding
- **API Gateway**: First 333K requests free per month
- **Estimate**: ~$0/month (free tier) → ~$5-10/month after

### Monitor Lambda Invocations
```bash
aws lambda list-functions
aws logs tail /aws/lambda/genai-ask --follow
```

### Monitor Pinecone Usage
Log into Pinecone console → "Usage" tab

---

## Advanced: Update Deployment

After making code changes:

```bash
cd infra
sam build
sam deploy  # Uses previous settings
```

---

## Next Steps

1. ✅ Set up AWS account & Bedrock access
2. ✅ Create Pinecone index
3. ✅ Deploy Lambda with SAM
4. ✅ Test with sample repository
5. 🎯 Ingest your actual codebases
6. 📊 Monitor retrieval quality and iterate
7. 🚀 Share with your team

---

## Support

For issues:
1. Check AWS CloudWatch logs: `aws logs tail /aws/lambda/genai-ask --follow`
2. Check debug logs: `cat ~/.genai-assistant/debug.log`
3. Verify Pinecone index: https://app.pinecone.io/
4. Test locally first with `--dry-run`

Good luck! 🚀
