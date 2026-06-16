#!/bin/bash
# Complete diagnostic report generator

set -e

echo "📊 GenAI Assistant - Complete Diagnostic Report"
echo "=============================================="
echo ""
echo "Timestamp: $(date)"
echo "System: $(uname -s) $(uname -r)"
echo ""

echo "🔍 System Information"
echo "===================="
echo "Python: $(python3 --version 2>&1)"
echo "pip: $(pip3 --version 2>&1)"
if command -v aws &> /dev/null; then
    echo "AWS CLI: $(aws --version 2>&1 | head -1)"
fi
if command -v sam &> /dev/null; then
    echo "SAM CLI: $(sam --version 2>&1 | head -1)"
fi
echo ""

echo "📦 Installed Packages"
echo "===================="
python3 -m pip list --format=columns 2>/dev/null | grep -E "langchain|pinecone|boto3|click|rich|pytest" || echo "No packages found"
echo ""

echo "🔐 AWS Configuration"
echo "==================="
if [ -f ~/.aws/config ]; then
    echo "AWS config file exists: ~/.aws/config"
    echo "Configured regions:"
    grep "region" ~/.aws/config | sed 's/^/  /'
fi
echo ""

echo "📝 GenAI Configuration"
echo "===================="
if [ -f ~/.genai-assistant/config.json ]; then
    echo "Config file exists: ~/.genai-assistant/config.json"
    echo "Contents (with API key redacted):"
    python3 -c "
import json
with open('~/.genai-assistant/config.json'.replace('~', '$HOME')) as f:
    config = json.load(f)
    config['pinecone_api_key'] = '***REDACTED***'
    config['api_url'] = config.get('api_url', '').replace('https://', 'https://***').replace('/prod/ask', '') if config.get('api_url') else ''
    print(json.dumps(config, indent=2))
" || cat ~/.genai-assistant/config.json
else
    echo "Config file NOT found at ~/.genai-assistant/config.json"
fi
echo ""

echo "🌍 Environment Variables"
echo "======================="
echo "PINECONE_API_KEY: ${PINECONE_API_KEY:-(not set)}"
echo "PINECONE_INDEX: ${PINECONE_INDEX:-(not set)}"
echo "API_GATEWAY_URL: ${API_GATEWAY_URL:-(not set)}"
echo "AWS_REGION: ${AWS_REGION:-(not set)}"
echo ""

echo "📂 Project Structure"
echo "==================="
echo "Total Python files: $(find . -name "*.py" -type f | wc -l)"
echo "Total test files: $(find tests -name "test_*.py" -type f 2>/dev/null | wc -l)"
echo "Total lines of code:"
find . -name "*.py" -type f ! -path "*/.git/*" ! -path "*/__pycache__/*" | xargs wc -l | tail -1 | awk '{print "  " $1}'
echo ""

echo "✅ Test Status"
echo "=============="
python3 -m pytest tests/unit/ -q --tb=no 2>/dev/null && echo "✓ All unit tests passing" || echo "⚠ Some tests failing"
echo ""

echo "🎯 Health Check"
echo "==============="
bash scripts/health-check.sh 2>&1 | tail -20
echo ""

echo "💡 Next Steps"
echo "============="
echo "1. Review any failures above"
echo "2. Run: bash scripts/fix-common-issues.sh"
echo "3. Run: bash scripts/health-check.sh"
echo "4. If still issues, check TROUBLESHOOTING.md"
echo ""
echo "Report complete at: $(date)"
