#!/bin/bash
# Auto-fix script for common issues

set -e

echo "🔧 GenAI Assistant - Auto-Fix Common Issues"
echo "==========================================="
echo ""

FIXED=0

# Helper function
fix() {
    echo "⚡ Fixing: $1"
    ((FIXED++))
}

# 1. Install missing dependencies
echo "1. Checking Python dependencies..."
if ! python3 -c "import langchain" 2>/dev/null; then
    fix "Installing Python dependencies"
    pip install -q -r requirements.txt
fi
echo ""

# 2. Fix wrong Pinecone package
echo "2. Checking Pinecone package..."
if python3 -c "import pinecone_client" 2>/dev/null; then
    fix "Removing old pinecone-client package"
    pip uninstall -y -q pinecone-client
    pip install -q pinecone
fi
echo ""

# 3. Create config directory
echo "3. Checking configuration directory..."
if [ ! -d ~/.genai-assistant ]; then
    fix "Creating ~/.genai-assistant directory"
    mkdir -p ~/.genai-assistant
fi
echo ""

# 4. Fix invalid config file
echo "4. Checking configuration file..."
if [ -f ~/.genai-assistant/config.json ]; then
    if ! python3 -m json.tool ~/.genai-assistant/config.json > /dev/null 2>&1; then
        fix "Fixing invalid JSON in config.json"
        cp ~/.genai-assistant/config.json ~/.genai-assistant/config.json.backup
        cat > ~/.genai-assistant/config.json << 'EOF'
{
  "pinecone_api_key": "",
  "pinecone_index": "genai-assistant",
  "bedrock_region": "us-east-1",
  "api_url": ""
}
EOF
        echo "  Backed up to config.json.backup"
    fi
fi
echo ""

# 5. Fix AWS CLI not configured
echo "5. Checking AWS CLI configuration..."
if ! aws sts get-caller-identity &>/dev/null 2>&1; then
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI not installed. Install with: brew install awscli"
        exit 1
    else
        echo "⚠️  AWS credentials not configured. Run: aws configure"
    fi
fi
echo ""

# 6. Install AWS SAM if missing
echo "6. Checking AWS SAM CLI..."
if ! command -v sam &> /dev/null; then
    echo "⚠️  AWS SAM CLI not installed"
    read -p "Install AWS SAM CLI? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        fix "Installing AWS SAM CLI"
        brew install aws-sam-cli
    fi
fi
echo ""

# 7. Fix environment variable issues
echo "7. Checking environment variables..."
if [ -z "$PINECONE_API_KEY" ] && [ -f ~/.genai-assistant/config.json ]; then
    if grep -q '"pinecone_api_key":' ~/.genai-assistant/config.json; then
        fix "Loading PINECONE_API_KEY from config"
        export PINECONE_API_KEY=$(grep -o '"pinecone_api_key": "[^"]*' ~/.genai-assistant/config.json | cut -d'"' -f4)
    fi
fi

if [ -z "$API_GATEWAY_URL" ] && [ -f ~/.genai-assistant/config.json ]; then
    if grep -q '"api_url":' ~/.genai-assistant/config.json; then
        API_URL=$(grep -o '"api_url": "[^"]*' ~/.genai-assistant/config.json | cut -d'"' -f4)
        if [ -n "$API_URL" ]; then
            fix "Loading API_GATEWAY_URL from config"
            export API_GATEWAY_URL="$API_URL"
        fi
    fi
fi
echo ""

# 8. Clean up Python cache
echo "8. Cleaning Python cache..."
find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
echo "✓ Cache cleaned"
echo ""

# 9. Fix file permissions
echo "9. Fixing script permissions..."
for script in scripts/*.sh; do
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        fix "Making $script executable"
        chmod +x "$script"
    fi
done
echo ""

# 10. Verify test suite
echo "10. Verifying test suite..."
if ! python3 -m pytest tests/unit/ -q 2>/dev/null; then
    echo "⚠️  Some tests may be failing. Run: python3 -m pytest tests/unit/ -v"
fi
echo ""

# Summary
echo "=================================="
if [ $FIXED -gt 0 ]; then
    echo "✅ Fixed $FIXED issues"
else
    echo "✅ No issues found"
fi
echo ""
echo "Next steps:"
echo "1. Run health check: bash scripts/health-check.sh"
echo "2. Deploy: bash scripts/deploy.sh"
echo "3. Test: bash scripts/test-api.sh"
