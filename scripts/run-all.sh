#!/bin/bash
# Run the complete setup and deployment pipeline

set -e

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPTS_DIR")"

echo "🎯 GenAI Assistant - Complete Setup Pipeline"
echo "==========================================="
echo ""

# Step 1: Environment setup
echo "Step 1: Environment Setup"
echo "========================"
bash "$SCRIPTS_DIR/setup-env.sh"

# Step 2: Test ingestion
echo ""
echo "Step 2: Test Ingestion Pipeline"
echo "==============================="
bash "$SCRIPTS_DIR/test-ingestion.sh"

# Step 3: Deploy to AWS
echo ""
echo "Step 3: Deploy to AWS"
echo "===================="
bash "$SCRIPTS_DIR/deploy.sh"

# Step 4: Test API
echo ""
echo "Step 4: Test API Endpoint"
echo "========================"
bash "$SCRIPTS_DIR/test-api.sh"

echo ""
echo "🎉 Complete setup finished!"
echo ""
echo "Your GenAI Assistant is now live:"
echo "  • Backend: AWS Lambda"
echo "  • Vector Store: Pinecone"
echo "  • Ready to ingest your codebases"
echo ""
echo "Next steps:"
echo "  1. Ingest your codebase:"
echo "     python3 -m ingestion.pipeline --repo ~/your-repo --namespace your-repo"
echo "  2. Ask questions:"
echo "     python3 -m cli.ask 'Your question' --namespace your-repo"
