#!/bin/bash
# Deploy GenAI Assistant to AWS Lambda

set -e

echo "🚀 GenAI Assistant - AWS Deployment"
echo "==================================="

# Check prerequisites
echo ""
echo "Checking prerequisites..."

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Install with: brew install awscli"
    exit 1
fi

if ! command -v sam &> /dev/null; then
    echo "❌ AWS SAM CLI not found. Install with: brew install aws-sam-cli"
    exit 1
fi

echo "✓ AWS CLI version: $(aws --version | cut -d' ' -f1)"
echo "✓ SAM CLI version: $(sam --version | cut -d' ' -f1)"

# Verify AWS credentials
echo ""
echo "Verifying AWS credentials..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS credentials not configured. Run: aws configure"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✓ AWS Account: $ACCOUNT_ID"

# Verify Bedrock access
echo ""
echo "Verifying Bedrock access..."
if ! aws bedrock list-foundation-models --region us-east-1 &> /dev/null; then
    echo "❌ Bedrock not accessible in us-east-1"
    echo ""
    echo "To fix:"
    echo "  1. Go to AWS Console → Region: us-east-1"
    echo "  2. Search for 'Bedrock' → Click 'Bedrock'"
    echo "  3. Click 'Model access' → 'Manage model access'"
    echo "  4. Enable 'Amazon Titan Embeddings' and 'Claude 3.5 Haiku'"
    echo "  5. Click 'Save changes' and wait 5-10 minutes"
    exit 1
fi
echo "✓ Bedrock is accessible"

# Get Pinecone API key
echo ""
echo "Pinecone Configuration"
if [ -f ~/.genai-assistant/config.json ]; then
    PINECONE_KEY=$(grep -o '"pinecone_api_key": "[^"]*' ~/.genai-assistant/config.json | cut -d'"' -f4)
    if [ -n "$PINECONE_KEY" ]; then
        echo "Found Pinecone API key in config"
        read -p "Use existing key? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            read -p "Enter your Pinecone API Key: " PINECONE_KEY
        fi
    fi
else
    read -p "Enter your Pinecone API Key: " PINECONE_KEY
fi

if [ -z "$PINECONE_KEY" ]; then
    echo "❌ Pinecone API key is required"
    exit 1
fi

# Get stack name
echo ""
echo "AWS CloudFormation Stack"
read -p "Enter stack name (default: genai-dev-assistant): " STACK_NAME
STACK_NAME=${STACK_NAME:-genai-dev-assistant}

# Navigate to infra directory
cd "$(dirname "$0")/../infra" || exit 1

echo ""
echo "Building Lambda function..."
sam build

echo ""
echo "Deploying to AWS..."
echo "Region: us-east-1"
echo "Stack: $STACK_NAME"
echo ""

sam deploy \
    --template-file .aws-sam/build/template.yaml \
    --stack-name "$STACK_NAME" \
    --region us-east-1 \
    --parameter-overrides \
        PineconeApiKey="$PINECONE_KEY" \
        PineconeIndexName="genai-assistant" \
    --capabilities CAPABILITY_IAM \
    --no-fail-on-empty-changeset

# Get deployment outputs
echo ""
echo "Retrieving deployment outputs..."

OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region us-east-1 \
    --query 'Stacks[0].Outputs' \
    --output json)

API_ENDPOINT=$(echo "$OUTPUTS" | grep -o '"ApiEndpoint","Value":"[^"]*' | cut -d'"' -f4)
LAMBDA_ARN=$(echo "$OUTPUTS" | grep -o '"AskFunctionArn","Value":"[^"]*' | cut -d'"' -f4)

echo ""
echo "✅ Deployment successful!"
echo ""
echo "Outputs:"
echo "--------"
echo "API Endpoint: $API_ENDPOINT"
echo "Lambda ARN:   $LAMBDA_ARN"
echo ""

# Update config file with API endpoint
echo ""
echo "Updating configuration file..."

python3 << PYEOF
import json

config_path = "$HOME/.genai-assistant/config.json"

try:
    with open(config_path, 'r') as f:
        config = json.load(f)
except FileNotFoundError:
    config = {}

config['api_url'] = "$API_ENDPOINT"
config['pinecone_api_key'] = "$PINECONE_KEY"
config['pinecone_index'] = "genai-assistant"
config['bedrock_region'] = "us-east-1"
config['lambda_arn'] = "$LAMBDA_ARN"

import os
os.makedirs(os.path.dirname(config_path), exist_ok=True)

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print(f"✓ Updated {config_path}")
PYEOF

# Export environment variable
export API_GATEWAY_URL="$API_ENDPOINT"

echo ""
echo "Next steps:"
echo "1. Test ingestion: bash scripts/test-ingestion.sh"
echo "2. Test API: bash scripts/test-api.sh"
echo "3. Ask questions:"
echo "   python3 -m cli.ask 'Your question' --namespace test-repo"
echo ""
echo "To persist API_GATEWAY_URL in your shell, add to ~/.zshrc:"
echo "  export API_GATEWAY_URL='$API_ENDPOINT'"
