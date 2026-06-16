#!/bin/bash
# Health check and auto-fix script for GenAI Assistant

set -e

echo "🏥 GenAI Assistant - Health Check"
echo "=================================="
echo ""

PASSED=0
FAILED=0
FIXED=0

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helper functions
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

check_fixed() {
    echo -e "${YELLOW}⚡${NC} $1 (AUTO-FIXED)"
    ((FIXED++))
}

# 1. Python version
echo "Checking Python..."
PYTHON_VERSION=$(python3 --version 2>&1 | grep -oP '\d+\.\d+')
if [[ $PYTHON_VERSION == 3.* ]]; then
    check_pass "Python 3.$PYTHON_VERSION installed"
else
    check_fail "Python 3.9+ required (found $PYTHON_VERSION)"
fi
echo ""

# 2. Dependencies
echo "Checking dependencies..."
if python3 -c "import langchain" 2>/dev/null; then
    check_pass "LangChain installed"
else
    check_fail "LangChain not installed"
    echo "  Fix: pip install -r requirements.txt"
fi

if python3 -c "import pinecone" 2>/dev/null; then
    check_pass "Pinecone installed"
else
    check_fail "Pinecone not installed"
    echo "  Fix: pip install pinecone"
fi

if python3 -c "import boto3" 2>/dev/null; then
    check_pass "boto3 installed"
else
    check_fail "boto3 not installed"
    echo "  Fix: pip install boto3"
fi
echo ""

# 3. AWS CLI
echo "Checking AWS..."
if command -v aws &> /dev/null; then
    check_pass "AWS CLI installed"

    if aws sts get-caller-identity &>/dev/null; then
        ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
        check_pass "AWS credentials valid (Account: $ACCOUNT)"
    else
        check_fail "AWS credentials not configured"
        echo "  Fix: Run 'aws configure' and enter your credentials"
    fi
else
    check_fail "AWS CLI not installed"
    echo "  Fix: brew install awscli"
fi
echo ""

# 4. SAM CLI
echo "Checking SAM..."
if command -v sam &> /dev/null; then
    check_pass "AWS SAM CLI installed"
else
    check_fail "AWS SAM CLI not installed"
    echo "  Fix: brew install aws-sam-cli"
fi
echo ""

# 5. Configuration files
echo "Checking configuration..."
if [ -f ~/.genai-assistant/config.json ]; then
    check_pass "Configuration file exists"

    # Check for required fields
    if grep -q "pinecone_api_key" ~/.genai-assistant/config.json; then
        PINECONE_KEY=$(grep -o '"pinecone_api_key": "[^"]*' ~/.genai-assistant/config.json | cut -d'"' -f4)
        if [ -n "$PINECONE_KEY" ] && [ "$PINECONE_KEY" != "YOUR_PINECONE_API_KEY_HERE" ]; then
            check_pass "Pinecone API key configured"
        else
            check_fail "Pinecone API key not set or placeholder"
            echo "  Fix: Update ~/.genai-assistant/config.json with real API key"
        fi
    fi
else
    check_fail "Configuration file missing"
    echo "  Fix: Run 'bash scripts/setup-env.sh'"
fi
echo ""

# 6. Environment variables
echo "Checking environment variables..."
if [ -n "$PINECONE_API_KEY" ]; then
    check_pass "PINECONE_API_KEY is set"
else
    check_fail "PINECONE_API_KEY not set"
    echo "  Fix: export PINECONE_API_KEY='your-api-key'"
fi

if [ -n "$API_GATEWAY_URL" ]; then
    check_pass "API_GATEWAY_URL is set"
else
    if [ -f ~/.genai-assistant/config.json ] && grep -q "api_url" ~/.genai-assistant/config.json; then
        API_URL=$(grep -o '"api_url": "[^"]*' ~/.genai-assistant/config.json | cut -d'"' -f4)
        if [ -n "$API_URL" ]; then
            export API_GATEWAY_URL="$API_URL"
            check_fixed "API_GATEWAY_URL loaded from config"
        fi
    else
        echo -e "${YELLOW}ℹ${NC} API_GATEWAY_URL not set (needed for CLI queries)"
    fi
fi
echo ""

# 7. Pinecone connection
echo "Checking Pinecone..."
if [ -n "$PINECONE_API_KEY" ]; then
    if python3 << 'EOF' 2>/dev/null
import os
from pinecone import Pinecone
try:
    pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
    index = pc.Index("genai-assistant")
    stats = index.describe_index_stats()
    print(f"vectors:{stats['total_vector_count']}")
except Exception as e:
    print(f"error:{str(e)}")
EOF
    then
        RESULT=$(python3 << 'EOF' 2>/dev/null
import os
from pinecone import Pinecone
try:
    pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
    index = pc.Index("genai-assistant")
    stats = index.describe_index_stats()
    print(f"vectors:{stats['total_vector_count']}")
except Exception as e:
    print(f"error:{str(e)}")
EOF
)

        if [[ $RESULT == vectors:* ]]; then
            VECTOR_COUNT=$(echo $RESULT | cut -d':' -f2)
            check_pass "Pinecone connected (Vectors: $VECTOR_COUNT)"
        else
            ERROR=$(echo $RESULT | cut -d':' -f2)
            if [[ $ERROR == *"401"* ]]; then
                check_fail "Pinecone API key invalid"
                echo "  Fix: Get correct API key from https://app.pinecone.io/"
            elif [[ $ERROR == *"genai-assistant"* ]]; then
                check_fail "Pinecone index 'genai-assistant' not found"
                echo "  Fix: Create index at https://app.pinecone.io/"
            else
                check_fail "Pinecone error: $ERROR"
            fi
        fi
    else
        check_fail "Cannot connect to Pinecone"
        echo "  Fix: Verify PINECONE_API_KEY is set correctly"
    fi
else
    echo -e "${YELLOW}ℹ${NC} Skipping Pinecone check (API key not set)"
fi
echo ""

# 8. Bedrock access
echo "Checking AWS Bedrock..."
if aws bedrock list-foundation-models --region us-east-1 &>/dev/null 2>&1; then
    check_pass "Bedrock models accessible"
else
    check_fail "Bedrock models not accessible"
    echo "  Fix: Go to AWS Console → Region: us-east-1 → Bedrock"
    echo "       → Model access → Manage model access"
    echo "       → Enable Claude 3.5 Haiku + Titan Embeddings"
    echo "       → Wait 5-10 minutes"
fi
echo ""

# 9. Project structure
echo "Checking project structure..."
REQUIRED_DIRS=("ingestion" "aws_lambda" "cli" "tests" "scripts" "infra")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        check_pass "Directory: $dir/"
    else
        check_fail "Missing directory: $dir/"
    fi
done
echo ""

# 10. Lambda deployment
echo "Checking AWS Lambda..."
if aws lambda list-functions --region us-east-1 --query 'Functions[?FunctionName==`genai-ask`]' --output json 2>/dev/null | grep -q "genai-ask"; then
    check_pass "Lambda function 'genai-ask' deployed"

    if [ -n "$API_GATEWAY_URL" ]; then
        if curl -s -o /dev/null -w "%{http_code}" "$API_GATEWAY_URL" | grep -qE "400|405"; then
            check_pass "API endpoint is reachable"
        else
            check_fail "API endpoint not responding"
            echo "  Fix: Check Lambda logs: aws logs tail /aws/lambda/genai-ask --follow"
        fi
    fi
else
    echo -e "${YELLOW}ℹ${NC} Lambda not deployed yet (run: bash scripts/deploy.sh)"
fi
echo ""

# Summary
echo "=================================="
echo "Health Check Summary"
echo "=================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FIXED -gt 0 ]; then
    echo -e "${YELLOW}Fixed:  $FIXED${NC}"
fi
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
fi
echo ""

if [ $FAILED -eq 0 ]; then
    echo "✅ All systems healthy! Ready to deploy."
    exit 0
else
    echo "⚠️  Some issues detected. See fixes above."
    exit 1
fi
