#!/bin/bash
# Deploy GenAI VS Code Extension to Marketplace

set -e

echo "🚀 GenAI Codebase Search - Marketplace Deployment"
echo "=================================================="
echo ""

# Check if vsce is installed
if ! command -v vsce &> /dev/null; then
    echo "❌ VSCE not found"
    echo ""
    echo "Install with:"
    echo "  npm install -g @vscode/vsce"
    exit 1
fi

echo "✓ VSCE installed: $(vsce --version)"
echo ""

# Get version from package.json
VERSION=$(grep '"version"' package.json | head -1 | cut -d'"' -f4)
echo "📦 Extension version: $VERSION"
echo ""

# Get publisher from package.json
PUBLISHER=$(grep '"publisher"' package.json | head -1 | cut -d'"' -f4)
echo "👤 Publisher: $PUBLISHER"
echo ""

# Confirm deployment
echo "Ready to deploy genai-codebase-search v$VERSION"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 1
fi

echo ""
echo "🔨 Building extension..."
npm run vscode:prepublish

echo ""
echo "📤 Publishing to Marketplace..."
vsce publish

echo ""
echo "✅ Deployment successful!"
echo ""
echo "🎯 Your extension is now live on the Marketplace"
echo ""
echo "View on Marketplace:"
echo "https://marketplace.visualstudio.com/items?itemName=$PUBLISHER.genai-codebase-search"
echo ""
echo "📊 Monitor downloads:"
echo "https://marketplace.visualstudio.com/manage"
