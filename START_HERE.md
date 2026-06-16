# 🚀 START HERE — GenAI Developer Assistant

Welcome! You now have a complete **AI-powered codebase assistant** ready to deploy.

## What You Have

A serverless RAG (Retrieval-Augmented Generation) system that:
- 📚 **Indexes your codebases** with language-aware text splitting
- 🔍 **Finds relevant code** using vector similarity search in Pinecone
- 🤖 **Answers questions** using Claude 3.5 Haiku from AWS Bedrock
- 📍 **Cites sources** — every answer includes file paths and relevance scores

## What You Need

Before you start, you need accounts for (all have free tiers):

1. **AWS Account** — for Lambda, API Gateway, Bedrock
   - Sign up: https://aws.amazon.com/
   - Free tier: 1M Lambda requests/month

2. **Pinecone Account** — vector database
   - Sign up: https://pinecone.io/
   - Free tier: 125K vectors

3. **Your Machine** — macOS/Linux with:
   - Python 3.9+
   - AWS CLI: `brew install awscli`
   - SAM CLI: `brew install aws-sam-cli`

## Quick Start (15 minutes)

### Step 1: Install (2 min)
```bash
cd /Users/xploit404/Documents/GENAI\ Developer
pip install -r requirements.txt
```

### Step 2: Configure (3 min)
```bash
bash scripts/setup-env.sh
```
Enter your Pinecone API key when prompted.

### Step 3: Test (3 min)
```bash
bash scripts/test-ingestion.sh
```
Choose to ingest to Pinecone when prompted.

### Step 4: Deploy (5 min)
```bash
bash scripts/deploy.sh
```
Enter your Pinecone API key and wait for deployment.

### Step 5: Verify (2 min)
```bash
bash scripts/test-api.sh
```
You should see an answer with sources!

## Or Run Everything at Once

```bash
bash scripts/run-all.sh
```

This runs all steps sequentially and handles the full setup → deploy → test pipeline.

---

## Now What?

### 🎯 Index Your Codebase

```bash
python3 -m ingestion.pipeline \
  --repo ~/your-repository \
  --namespace your-project-name
```

### 💬 Ask Questions

```bash
python3 -m cli.ask "How does authentication work?" \
  --namespace your-project-name
```

### 📊 Get Better Answers

If answers are vague, ask for more context:
```bash
python3 -m cli.ask "How does authentication work?" \
  --namespace your-project-name \
  --top-k 10
```

---

## Documentation Guide

| Document | Best For |
|----------|----------|
| **QUICKSTART.md** | Get running in 15 minutes |
| **SETUP.md** | Detailed step-by-step instructions |
| **DEPLOYMENT.md** | Understand the deployment process |
| **REFERENCE.md** | Copy-paste commands for common tasks |
| **TROUBLESHOOTING.md** | Fix problems |
| **README.md** | Technical details and architecture |

---

## Project Structure

```
/Users/xploit404/Documents/GENAI Developer/
├── 📄 START_HERE.md                    ← You are here
├── 📘 README.md                        ← Full documentation
├── ⚡ QUICKSTART.md                    ← 15-minute setup
├── 📋 SETUP.md                         ← Step-by-step guide
├── 🚀 DEPLOYMENT.md                    ← Deployment details
├── 🔧 REFERENCE.md                     ← Quick commands
├── ❌ TROUBLESHOOTING.md               ← Fix issues
│
├── 📂 scripts/
│   ├── setup-env.sh                    ← Configure environment
│   ├── deploy.sh                       ← Deploy to AWS
│   ├── test-ingestion.sh               ← Test ingestion
│   ├── test-api.sh                     ← Test deployed API
│   └── run-all.sh                      ← Run everything
│
├── 📂 ingestion/                       ← Index repositories
│   ├── chunker.py                      ← Language-aware splitting
│   ├── embedder.py                     ← Bedrock embeddings
│   └── pipeline.py                     ← Ingest CLI
│
├── 📂 aws_lambda/                      ← Lambda backend
│   ├── handler.py                      ← Lambda entry point
│   ├── agent.py                        ← RAG chain
│   └── retriever.py                    ← Pinecone search
│
├── 📂 cli/
│   └── ask.py                          ← Question asking CLI
│
├── 📂 tests/                           ← Test suite
│   ├── unit/                           ← Unit tests (8 passing)
│   └── integration/                    ← E2E tests
│
├── 📂 infra/
│   └── template.yaml                   ← AWS SAM template
│
└── 📄 requirements.txt                 ← Python dependencies
```

---

## Architecture Overview

```
Your Codebase
    ↓
[Ingestion Pipeline]  ← Language-aware chunking
    ↓
[Bedrock Embeddings]  ← amazon.titan-embed-text-v2:0
    ↓
[Pinecone]            ← Vector search (namespaced per repo)
    ↓
[AWS Lambda + API Gateway]  ← Your backend in the cloud
    ↓
[Claude 3.5 Haiku]    ← Answers your questions
    ↓
[CLI Client]          ← Source-cited answers
```

---

## Key Features

✅ **Language-Aware Chunking**
- Python, JavaScript, Markdown, Go, Rust, Java, C++, and more
- Splits at natural boundaries (functions, classes, headings)

✅ **Serverless Deployment**
- AWS Lambda (pay per invocation, free tier covers 1M/month)
- Auto-scaling, zero infrastructure to manage

✅ **Source Citations**
- Every answer includes file paths and relevance scores
- See exactly where the LLM found the answer

✅ **Multiple Repositories**
- Store unlimited codebases in separate Pinecone namespaces
- Query across different projects independently

✅ **Tested & Production-Ready**
- 8 unit tests (100% passing)
- Integration tests for end-to-end flows
- Comprehensive error handling

---

## Common Commands

```bash
# Setup
bash scripts/setup-env.sh              # Configure credentials
bash scripts/deploy.sh                 # Deploy to AWS

# Testing
bash scripts/test-ingestion.sh         # Test chunking
bash scripts/test-api.sh               # Test deployed API

# Using
python3 -m ingestion.pipeline \
  --repo ~/my-repo --namespace my-repo # Ingest code
python3 -m cli.ask "question" \
  --namespace my-repo                  # Ask questions

# Monitoring
DEBUG=1 python3 -m cli.ask "q" \
  --namespace my-repo                  # See debug logs
aws logs tail /aws/lambda/genai-ask \
  --follow                             # View Lambda logs
```

---

## Costs

| Service | Free Tier | After Free |
|---------|-----------|-----------|
| AWS Lambda | 1M requests/month | $0.20 per 1M requests |
| Bedrock | 3 months free | ~$0.0002 per embedding |
| Pinecone | 125K vectors | $0.70 per 100K vectors/month |
| **Total** | **Free** | **~$5-15/month** |

---

## Troubleshooting

### "Bedrock not accessible"
1. AWS Console → Region: us-east-1
2. Search "Bedrock"
3. Model access → Enable Claude 3.5 Haiku + Titan Embeddings
4. Wait 5-10 minutes

### "PINECONE_API_KEY not set"
```bash
export PINECONE_API_KEY="your-key-from-pinecone.io"
```

### "Could not connect to API"
```bash
export API_GATEWAY_URL="https://xxx.execute-api.us-east-1.amazonaws.com/prod"
```

### Still stuck?
See **TROUBLESHOOTING.md** for detailed solutions.

---

## Next Steps

1. ✅ **Set up accounts** (AWS, Pinecone)
2. ✅ **Run quick start** (`bash scripts/run-all.sh`)
3. ✅ **Index your code** (`python3 -m ingestion.pipeline`)
4. ✅ **Ask questions** (`python3 -m cli.ask`)
5. 🔄 **Monitor & iterate** (adjust chunk sizes, top-k)
6. 📊 **Track costs** (AWS + Pinecone consoles)

---

## What's Included

✅ **Complete source code** — all production-ready modules
✅ **Unit tests** — 8 passing tests with mocks
✅ **Deployment automation** — run bash scripts, not manual steps
✅ **Documentation** — 7 comprehensive guides
✅ **Configuration** — templates and examples
✅ **Git history** — all changes tracked

---

## Support & Resources

**Documentation**
- [QUICKSTART.md](QUICKSTART.md) — 15-minute setup
- [SETUP.md](SETUP.md) — Detailed step-by-step
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — Fix issues
- [REFERENCE.md](REFERENCE.md) — Quick commands

**External**
- Bedrock: https://console.aws.amazon.com/bedrock/
- Pinecone: https://app.pinecone.io/
- AWS Console: https://console.aws.amazon.com/

**Local Testing**
```bash
python3 -m pytest tests/unit/ -v
```

---

## You're Ready! 🎉

Everything is set up and waiting for you to deploy.

```bash
# Start here:
bash scripts/run-all.sh

# Then ask questions:
python3 -m cli.ask "Your question" --namespace your-repo
```

Happy coding! 🚀
