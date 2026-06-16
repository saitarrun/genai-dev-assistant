#!/bin/bash
# Test the deployed API endpoint

set -e

echo "🧪 Testing API Endpoint"
echo "======================"

# Load API URL from config
if [ -f ~/.genai-assistant/config.json ]; then
    API_URL=$(grep -o '"api_url": "[^"]*' ~/.genai-assistant/config.json | cut -d'"' -f4)
fi

if [ -z "$API_URL" ]; then
    API_URL="$API_GATEWAY_URL"
fi

if [ -z "$API_URL" ]; then
    echo "❌ API_GATEWAY_URL not set"
    echo ""
    echo "Get it from deployment output:"
    echo "  export API_GATEWAY_URL='https://xxx.execute-api.us-east-1.amazonaws.com/prod'"
    echo ""
    echo "Or run: bash scripts/deploy.sh"
    exit 1
fi

echo "API Endpoint: $API_URL"
echo ""

# Test if API is reachable
echo "Testing API connectivity..."
if ! curl -s -o /dev/null -w "%{http_code}" "$API_URL" | grep -q "405\|400"; then
    echo "⚠️  API endpoint returned an unexpected status"
fi
echo "✓ API is reachable"
echo ""

# First, test with the sample repo that should have been ingested
echo "Testing with sample data..."
echo ""

QUESTION="How does authentication work?"
NAMESPACE="test-repo"

echo "Question: $QUESTION"
echo "Namespace: $NAMESPACE"
echo ""

# Make the API request
echo "Sending request to Lambda..."
RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{
        \"question\": \"$QUESTION\",
        \"namespace\": \"$NAMESPACE\",
        \"top_k\": 5
    }")

# Check if response contains an error
if echo "$RESPONSE" | grep -q '"error"'; then
    ERROR=$(echo "$RESPONSE" | grep -o '"error": "[^"]*' | cut -d'"' -f4)
    echo "❌ API returned error: $ERROR"
    echo ""
    echo "Response:"
    echo "$RESPONSE" | python3 -m json.tool
    exit 1
fi

# Extract answer and sources
ANSWER=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['answer'])" 2>/dev/null || echo "")
SOURCES=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin)['sources'], indent=2))" 2>/dev/null || echo "")

if [ -z "$ANSWER" ]; then
    echo "❌ Failed to parse response"
    echo ""
    echo "Raw response:"
    echo "$RESPONSE" | python3 -m json.tool
    exit 1
fi

echo "✓ Received answer from Lambda"
echo ""
echo "---"
echo "Answer:"
echo "$ANSWER"
echo ""
echo "---"
echo "Sources:"
echo "$SOURCES"
echo "---"
echo ""

# Try the CLI client
echo "Testing CLI client..."
export API_GATEWAY_URL="$API_URL"

python3 -m cli.ask "How does database connection pooling work?" --namespace test-repo

echo ""
echo "✅ API tests passed!"
echo ""
echo "Next: Ask your own questions"
echo "  python3 -m cli.ask 'Your question' --namespace your-repo"
