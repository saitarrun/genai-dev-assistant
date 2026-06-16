# GenAI Codebase Search - VS Code Extension

Search your codebase with AI directly from VS Code.

## Features

- 🔍 **Quick Search** — Ask questions about your code (Ctrl+Shift+G)
- 📚 **Source Citations** — See exactly where answers come from
- ⚡ **Fast** — Semantic search with vector embeddings
- 🎯 **Accurate** — Powered by Claude 3.5 Haiku

## Installation

1. Install the extension from VS Code Marketplace
2. Configure the API URL in settings:
   - Open VS Code Settings (Ctrl+,)
   - Search for "genai"
   - Enter your API Gateway URL

## Configuration

Add to VS Code settings.json:

```json
{
  "genai.apiUrl": "https://your-api-gateway.execute-api.us-east-1.amazonaws.com/prod",
  "genai.defaultNamespace": "my-repo"
}
```

## Usage

### Quick Search

Press **Ctrl+Shift+G** (Cmd+Shift+G on Mac) to open the search dialog.

Type your question:
```
How does authentication work?
```

Select the repository namespace and get results with source citations.

### Index Current Repository

1. Open a folder in VS Code
2. Run command: "GenAI: Index Current Repository"
3. Follow the instructions to index your code

### View Results

Results appear in the Output channel with:
- Full answer from Claude
- List of relevant source files
- Relevance scores for each source

## Commands

| Command | Keybinding | Description |
|---------|-----------|-------------|
| GenAI: Search Codebase | Ctrl+Shift+G | Open search dialog |
| GenAI: Index Repository | - | Index current workspace |
| GenAI: Settings | - | Open settings |

## Requirements

- VS Code 1.80+
- GenAI Assistant Lambda deployed with API Gateway
- PINECONE_API_KEY configured in GenAI backend

## Settings

| Setting | Type | Description |
|---------|------|-------------|
| `genai.apiUrl` | string | API Gateway endpoint URL |
| `genai.apiKey` | string | (Optional) API key if authentication enabled |
| `genai.defaultNamespace` | string | Default repository namespace |

## Architecture

```
VS Code Extension
    ↓
    POST /ask (HTTP)
    ↓
API Gateway
    ↓
Lambda Function (RAG Agent)
    ↓
Claude 3.5 Haiku + Pinecone
    ↓
Source-cited Answer
```

## Troubleshooting

### "API URL not configured"
- Open VS Code Settings (Ctrl+,)
- Search for "genai.apiUrl"
- Enter your API Gateway URL from deployment

### "Connection refused"
- Verify Lambda is deployed: `aws lambda list-functions`
- Check API URL is correct
- Ensure you're in the correct AWS region (us-east-1)

### "No results found"
- Make sure you've indexed your repository
- Check the namespace is correct
- Try a different search query

## Development

```bash
# Install dependencies
npm install

# Compile TypeScript
npm run compile

# Watch for changes
npm run watch

# Package for distribution
npm run vscode:prepublish
```

## Publishing

```bash
# Install VSCE
npm install -g @vscode/vsce

# Package extension
vsce package

# Publish to marketplace
vsce publish
```

## License

MIT
