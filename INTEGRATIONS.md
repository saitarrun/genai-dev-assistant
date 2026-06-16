# Integrations Guide

Complete setup for GitHub integration and IDE extensions.

---

## 🔌 GitHub Integration

Automatically index repositories from GitHub organizations or user accounts.

### Setup

```bash
# Set GitHub token (optional, for private repos)
export GITHUB_TOKEN="your-github-personal-access-token"

# Install requests library
pip install requests
```

### Usage

```python
from utils.github_integration import index_github_repos

# Index all repos from an organization
repos = index_github_repos(org="mycompany")

# Index specific repos only
repos = index_github_repos(org="mycompany", repos=["api", "frontend"])

# Index repos from a user
repos = index_github_repos(username="john-doe")
```

### CLI Usage

Create a script `scripts/index-github.py`:

```python
#!/usr/bin/env python3
import sys
from utils.github_integration import index_github_repos
from ingestion.pipeline import ingest_repos

org = sys.argv[1] if len(sys.argv) > 1 else None
repos = index_github_repos(org=org)

for repo_name, repo_path in repos:
    print(f"Indexing {repo_name}...")
    os.system(f"python3 -m ingestion.pipeline --repo {repo_path} --namespace {repo_name}")
```

Run:
```bash
python3 scripts/index-github.py mycompany
```

### Features

✅ Clone repositories from GitHub  
✅ Support organizations and users  
✅ Filter specific repositories  
✅ Skip archived repositories  
✅ Update existing clones (git pull)  
✅ Handle both public and private repos (with token)  

### GitHub Token

For private repositories, create a personal access token:

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate new token with `repo` scope
3. Export as environment variable: `export GITHUB_TOKEN="ghp_xxx"`

---

## 🔌 VS Code Extension

Search your codebase from VS Code.

### Installation

1. **From Marketplace:**
   - Open VS Code Extensions (Ctrl+Shift+X)
   - Search for "GenAI Codebase Search"
   - Click Install

2. **From Source:**
   ```bash
   cd extensions/vscode
   npm install
   npm run compile
   code --install-extension genai-codebase-search-0.1.0.vsix
   ```

### Configuration

1. Open VS Code Settings (Ctrl+,)
2. Search for "genai"
3. Set:
   - `genai.apiUrl`: Your API Gateway URL
   - `genai.defaultNamespace`: Your repository namespace

Or edit `.vscode/settings.json`:

```json
{
  "genai.apiUrl": "https://your-api.execute-api.us-east-1.amazonaws.com/prod",
  "genai.defaultNamespace": "my-repo"
}
```

### Usage

**Keyboard Shortcut:** `Ctrl+Shift+G` (Cmd+Shift+G on Mac)

Type your question and select the repository namespace.

Results appear in the Output panel with source files and relevance scores.

### Features

✅ Quick search with keyboard shortcut  
✅ Repository namespace selection  
✅ Source-cited answers  
✅ Integration with VS Code UI  
✅ Error handling with helpful messages  

---

## 🔌 JetBrains Plugin

Search from IntelliJ, PyCharm, WebStorm, and other JetBrains IDEs.

### Installation

1. **From Marketplace:**
   - Open IDE Settings → Plugins → Marketplace
   - Search for "GenAI Codebase Search"
   - Click Install and restart IDE

2. **From Source:**
   ```bash
   cd extensions/jetbrains
   gradle build
   # Install from build/distributions/genai-*.jar
   ```

### Configuration

1. Open IDE Settings → Tools → GenAI Search
2. Set:
   - API URL: Your API Gateway URL
   - Default Namespace: Your repository namespace

### Usage

**Keyboard Shortcut:** `Ctrl+Shift+G` (Cmd+Shift+G on Mac)

Or go to Search menu → "Search with GenAI"

Type your question and get results in the output panel.

### Features

✅ Native JetBrains integration  
✅ Keyboard shortcut support  
✅ Settings UI  
✅ Multiple IDE support (IntelliJ, PyCharm, WebStorm, etc.)  
✅ Background indexing  

---

## 🔌 Vim Plugin

Search your codebase from Vim.

### Installation

**With Vim-Plug:**

Add to `.vimrc`:
```vim
Plug 'saitarrun/genai-dev-assistant', { 'rtp': 'extensions/vim' }
```

Then run: `:PlugInstall`

**Manual:**

```bash
cp extensions/vim/plugin/genai.vim ~/.vim/plugin/
cp extensions/vim/autoload/genai.vim ~/.vim/autoload/
```

### Configuration

Add to `.vimrc`:

```vim
let g:genai_api_url = 'https://your-api.execute-api.us-east-1.amazonaws.com/prod/ask'
let g:genai_namespace = 'my-repo'
let g:genai_top_k = 6
```

### Usage

**Keyboard Shortcut:** `<Leader>gs` (default: `\gs`)

Or type: `:GenaiSearch How does auth work?`

Results appear in a new buffer with sources.

### Commands

| Command | Description |
|---------|-------------|
| `:GenaiSearch [question]` | Search codebase |
| `:GenaiConfig` | Show configuration |
| `:GenaiIndex` | Show indexing command |

### Features

✅ Vim/Neovim compatible  
✅ Customizable keybindings  
✅ JSON parsing  
✅ Formatted results buffer  
✅ Configuration UI  

---

## 📊 Comparison

| Feature | GitHub | VS Code | JetBrains | Vim |
|---------|--------|---------|-----------|-----|
| **Auto-index** | ✅ | - | - | - |
| **Keyboard search** | - | ✅ | ✅ | ✅ |
| **Native UI** | - | ✅ | ✅ | ✅ |
| **Settings UI** | - | ✅ | ✅ | Via .vimrc |
| **IDE Integration** | - | ✅ | ✅ | ✅ |
| **Supported IDEs** | - | 1 | 10+ | Vim/Neovim |

---

## 🚀 Complete Workflow

### 1. Index from GitHub

```bash
export GITHUB_TOKEN="your-token"
python3 << 'EOF'
from utils.github_integration import index_github_repos
from ingestion.pipeline import ingest

repos = index_github_repos(org="mycompany")
for name, path in repos:
    print(f"Indexing {name}...")
    os.system(f"python3 -m ingestion.pipeline --repo {path} --namespace {name}")
EOF
```

### 2. Configure IDE

For each IDE, set API URL and default namespace.

### 3. Search

Use the IDE extension to search your codebase immediately.

---

## 🔐 Security

### API Key Management

If you enable API authentication on Lambda:

**VS Code:**
```json
{
  "genai.apiUrl": "https://...",
  "genai.apiKey": "your-api-key"
}
```

**Vim:**
```vim
let g:genai_api_key = 'your-api-key'
```

**JetBrains:** Settings → Tools → GenAI Search → API Key

### GitHub Token

- Use personal access token with minimal scope
- Never commit to git
- Store in environment variable or secure vault

---

## 🐛 Troubleshooting

### Extension not connecting

1. Check API URL is correct
2. Verify Lambda is deployed: `aws lambda list-functions`
3. Test with curl: `curl -X POST <API_URL> -d '{"question":"test","namespace":"test"}'`

### No results

- Make sure repository is indexed
- Check namespace matches
- Verify vectors are in Pinecone

### Performance

- Reduce `top_k` for faster results
- Increase timeout if responses are slow
- Monitor Lambda execution time in CloudWatch

---

## 📚 Examples

### Index Organization Repos

```python
from utils.github_integration import index_github_repos

repos = index_github_repos(org="acme-corp", repos=["api", "worker", "frontend"])
for name, path in repos:
    print(f"Clone: {name} at {path}")
```

### Search from VS Code

```
Ctrl+Shift+G
> How does the payment processor work?
> Namespace: payment-service
> [Results in output panel]
```

### Search from Vim

```vim
:GenaiSearch What are the database migrations?
" Results in new buffer
```

### Search from JetBrains

```
Ctrl+Shift+G (or Search menu)
Type question
Select namespace
View results
```

---

## 📖 Full Setup Example

**1. Deploy Lambda**
```bash
bash scripts/deploy.sh
export API_GATEWAY_URL="https://..."
```

**2. Index Repos**
```bash
python3 -m ingestion.pipeline --repo ~/my-api --namespace my-api
python3 -m ingestion.pipeline --repo ~/my-web --namespace my-web
```

**3. Install VS Code Extension**
- Marketplace → GenAI Codebase Search → Install
- Settings → genai.apiUrl and genai.defaultNamespace

**4. Search**
- Ctrl+Shift+G
- Ask questions about your code
- Get instant answers with sources

---

**All extensions are open-source and can be extended or customized for your needs!** 🚀
