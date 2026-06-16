#!/bin/bash
# Setup environment variables for GenAI Assistant

set -e

echo "🔧 GenAI Assistant - Environment Setup"
echo "======================================"

# Check if credentials are already set
if [ -f ~/.genai-assistant/config.json ]; then
    echo "✓ Configuration file already exists at ~/.genai-assistant/config.json"
    echo ""
    echo "Current configuration:"
    cat ~/.genai-assistant/config.json
    echo ""
    read -p "Do you want to update it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping configuration update."
        exit 0
    fi
fi

# Create config directory
mkdir -p ~/.genai-assistant
echo "✓ Created ~/.genai-assistant directory"

# Prompt for Pinecone API key
echo ""
echo "📍 Pinecone Setup"
echo "Get your API key from: https://app.pinecone.io/ (click your name → API keys)"
read -p "Enter your Pinecone API Key: " pinecone_key

if [ -z "$pinecone_key" ]; then
    echo "❌ Pinecone API key is required"
    exit 1
fi

# Prompt for API Gateway URL (optional at setup time)
echo ""
echo "🌐 API Gateway URL (Optional)"
echo "You'll get this after AWS deployment"
read -p "Enter API Gateway URL (or leave blank): " api_url

# Prompt for AWS region
echo ""
echo "🔑 AWS Configuration"
read -p "Enter AWS region (default: us-east-1): " aws_region
aws_region=${aws_region:-us-east-1}

# Create config file
cat > ~/.genai-assistant/config.json << EOF
{
  "pinecone_api_key": "$pinecone_key",
  "pinecone_index": "genai-assistant",
  "bedrock_region": "$aws_region",
  "api_url": "$api_url"
}
EOF

echo ""
echo "✓ Configuration saved to ~/.genai-assistant/config.json"
echo ""
echo "Configuration:"
cat ~/.genai-assistant/config.json
echo ""

# Export environment variables
export PINECONE_API_KEY="$pinecone_key"
export PINECONE_INDEX="genai-assistant"
export AWS_REGION="$aws_region"

echo "✓ Environment variables set for this session"
echo ""
echo "To make these persistent, add to your ~/.zshrc or ~/.bash_profile:"
echo ""
echo "  export PINECONE_API_KEY='$pinecone_key'"
echo "  export PINECONE_INDEX='genai-assistant'"
echo "  export AWS_REGION='$aws_region'"
echo ""

# Test Pinecone connection
echo "Testing Pinecone connection..."
python3 << 'PYEOF'
import os
import sys

try:
    from pinecone import Pinecone

    api_key = os.getenv("PINECONE_API_KEY")
    if not api_key:
        print("❌ PINECONE_API_KEY not set")
        sys.exit(1)

    pc = Pinecone(api_key=api_key)
    index = pc.Index("genai-assistant")
    stats = index.describe_index_stats()

    print("✓ Successfully connected to Pinecone")
    print(f"  Index: genai-assistant")
    print(f"  Dimension: {stats['dimension']}")
    print(f"  Total vectors: {stats['total_vector_count']}")

except Exception as e:
    print(f"❌ Failed to connect to Pinecone: {e}")
    print("")
    print("Make sure:")
    print("  1. Your Pinecone API key is correct")
    print("  2. You have created an index named 'genai-assistant'")
    print("  3. The index status is 'Ready'")
    sys.exit(1)
PYEOF

echo ""
echo "✅ Environment setup complete!"
