#!/bin/bash
# VS Code Extension Installation Script

set -e

echo "🔧 GenAI Codebase Search - VS Code Extension"
echo "=============================================="
echo ""

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found"
    echo "Install from: https://nodejs.org/"
    exit 1
fi

echo "✓ Node.js: $(node --version)"

# Check npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm not found"
    exit 1
fi

echo "✓ npm: $(npm --version)"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Compile TypeScript
echo "🔨 Compiling TypeScript..."
npm run compile

# Package extension
echo "📦 Packaging extension..."
npm run vscode:prepublish

# Check if extension file exists
if [ ! -f "genai-codebase-search-0.1.0.vsix" ]; then
    echo "❌ Failed to create VSIX file"
    exit 1
fi

echo ""
echo "✅ Extension packaged: genai-codebase-search-0.1.0.vsix"
echo ""
echo "Next steps:"
echo "1. Install in VS Code:"
echo "   code --install-extension genai-codebase-search-0.1.0.vsix"
echo ""
echo "2. Configure settings:"
echo "   - Press Ctrl+, (Settings)"
echo "   - Search: genai"
echo "   - Enter API URL and namespace"
echo ""
echo "3. Use the extension:"
echo "   - Press Ctrl+Shift+G"
echo "   - Type your question"
echo "   - Get source-cited answers"
echo ""
