# Deploy VS Code Extension to Marketplace

Complete guide to publish GenAI Codebase Search to the VS Code Marketplace.

---

## 📋 Prerequisites

You'll need:
- ✅ VS Code Extension (source code) - **Already have this**
- ✅ npm & Node.js - **Already have this**
- ❌ Microsoft Account (free) - **Create if needed**
- ❌ Azure DevOps Organization - **Create if needed**
- ❌ Personal Access Token (PAT) - **Generate**
- ❌ Publisher Account - **Create on Marketplace**

---

## 🔑 Step 1: Create Microsoft Account

If you don't have one:

1. Go to: https://account.microsoft.com/
2. Click **"Create one"**
3. Fill in email and password
4. Complete verification

---

## 👤 Step 2: Create Azure DevOps Organization

1. Go to: https://dev.azure.com/
2. Sign in with Microsoft account
3. Click **"Create new organization"**
4. Choose a name: `genai-dev` (or your preference)
5. Click **Create**

---

## 🔐 Step 3: Generate Personal Access Token (PAT)

This is required for authentication.

### 3.1 Go to PAT Settings

1. Go to: https://dev.azure.com/
2. Click your **profile icon** (top-right)
3. Select **"Personal access tokens"**
4. Click **"+ New Token"**

### 3.2 Create Token

Fill in:
- **Name**: `vscode-marketplace` (or any name)
- **Organization**: Select your organization
- **Expiration**: 90 days (or longer)
- **Scopes**: Select **"Marketplace (manage)"**

Then:
1. Click **Create**
2. **Copy the token immediately** (you won't see it again!)
3. Save it somewhere safe (not in git!)

Example token (DON'T USE THIS):
```
abcdef123456789abcdef123456789abcdef
```

---

## 📦 Step 4: Create Publisher Account

### 4.1 Go to Marketplace Publisher Page

1. Go to: https://marketplace.visualstudio.com/manage
2. Sign in with Microsoft account
3. Click **"Create publisher"** (if first time)

### 4.2 Create Publisher

Fill in:
- **Publisher Name**: `genai-dev` (or your choice)
  - This will be part of the extension ID
  - Must be lowercase alphanumeric
- **Display Name**: `GenAI` (or company name)
- **Description**: `AI-powered codebase search`

Click **Create**.

Your publisher ID: `genai-dev.genai-codebase-search`

---

## 📝 Step 5: Update package.json

Make sure `package.json` has correct publisher info:

```json
{
  "name": "genai-codebase-search",
  "displayName": "GenAI Codebase Search",
  "version": "0.1.0",
  "publisher": "genai-dev",
  "engines": {
    "vscode": "^1.80.0"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/saitarrun/genai-dev-assistant"
  },
  "homepage": "https://github.com/saitarrun/genai-dev-assistant",
  "bugs": {
    "url": "https://github.com/saitarrun/genai-dev-assistant/issues"
  }
}
```

Key fields:
- `"publisher"`: Your publisher ID
- `"version"`: Bump for each release (e.g., 0.1.0 → 0.1.1)
- `"repository"`: Link to GitHub repo
- `"homepage"`: Project homepage

---

## 🔧 Step 6: Install VSCE Tool

VSCE is the official VS Code Extension CLI.

```bash
npm install -g @vscode/vsce
```

Verify installation:
```bash
vsce --version
```

---

## 🔐 Step 7: Login to Marketplace

```bash
vsce login genai-dev
```

When prompted:
- **Publisher name**: `genai-dev`
- **Personal Access Token**: Paste your PAT from Step 3

The token will be saved locally for future publishes.

---

## 📦 Step 8: Publish Extension

### 8.1 Navigate to Extension Directory

```bash
cd /Users/xploit404/Documents/GENAI\ Developer/extensions/vscode
```

### 8.2 Build for Production

```bash
npm run vscode:prepublish
```

### 8.3 Publish to Marketplace

```bash
vsce publish
```

This will:
1. Compile TypeScript
2. Package the extension
3. Upload to Marketplace
4. Make it searchable in 5-10 minutes

---

## ✅ Step 9: Verify Deployment

### 9.1 Check Marketplace

1. Go to: https://marketplace.visualstudio.com/search?term=genai
2. Look for **"GenAI Codebase Search"**
3. Verify publisher is `genai-dev`

### 9.2 Check in VS Code

1. Open VS Code
2. Press `Ctrl+Shift+X` (Extensions)
3. Search: `genai`
4. Should see your extension
5. Click **Install**

---

## 🔄 Step 10: Update in Future

When you update the extension:

### 10.1 Bump Version

Edit `extensions/vscode/package.json`:

```json
{
  "version": "0.1.1"  // Changed from 0.1.0
}
```

Versioning format: `MAJOR.MINOR.PATCH`
- `0.1.0` → `0.1.1` (bug fix)
- `0.1.0` → `0.2.0` (new feature)
- `0.1.0` → `1.0.0` (major update)

### 10.2 Publish Update

```bash
cd extensions/vscode
npm run vscode:prepublish
vsce publish
```

---

## 📊 Complete Deployment Checklist

- [ ] Microsoft Account created
- [ ] Azure DevOps Organization created
- [ ] Personal Access Token generated and saved
- [ ] Publisher Account created on Marketplace
- [ ] Publisher name noted (e.g., `genai-dev`)
- [ ] `package.json` updated with publisher
- [ ] VSCE CLI installed: `vsce --version`
- [ ] Logged in: `vsce login genai-dev`
- [ ] Extension built: `npm run vscode:prepublish`
- [ ] Published: `vsce publish`
- [ ] Verified on Marketplace
- [ ] Installed in VS Code

---

## 🐛 Troubleshooting

### "vsce: command not found"

Install VSCE globally:
```bash
npm install -g @vscode/vsce
```

### "Invalid publisher name"

Publisher name must be:
- ✅ Lowercase
- ✅ Alphanumeric (a-z, 0-9, -)
- ✅ No spaces
- ❌ Not `vscode` (reserved)

### "Authentication failed"

```bash
# Clear old token
vsce logout

# Login again with new PAT
vsce login your-publisher-id
```

### "Version already exists"

Bump version in `package.json`:
```json
{
  "version": "0.1.1"  // Was 0.1.0
}
```

### "Extension not appearing in search"

- Wait 5-10 minutes after publish
- Marketplace caches search results
- Refresh VS Code Extensions tab
- Check publisher name is correct

### "Cannot publish: 403 Forbidden"

- Verify Personal Access Token is valid
- Check token has "Marketplace (manage)" scope
- Verify publisher ID matches in `package.json`

---

## 📈 After Publishing

### Monitor Downloads

1. Go to: https://marketplace.visualstudio.com/manage
2. Select your extension
3. View:
   - Download count
   - Rating/reviews
   - Install trends

### View Extension Page

Visit your extension:
```
https://marketplace.visualstudio.com/items?itemName=genai-dev.genai-codebase-search
```

### Update Marketplace Listing

1. Go to Marketplace manage page
2. Edit:
   - Description
   - Icon
   - Gallery preview
   - FAQ
   - Change log

---

## 📝 Create Changelog

Create `extensions/vscode/CHANGELOG.md`:

```markdown
# Changelog

## [0.1.0] - 2024-06-15

### Added
- Initial release
- Quick search with Ctrl+Shift+G
- API Gateway integration
- Settings configuration
- Output panel results

### Features
- Search codebase with AI
- Source-cited answers
- Repository namespace support
- Keyboard shortcuts
```

---

## 🎯 Quick Deployment Script

Create `extensions/vscode/deploy.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Deploying to VS Code Marketplace..."
echo ""

# Check version
VERSION=$(grep '"version"' package.json | head -1 | cut -d'"' -f4)
echo "📦 Version: $VERSION"
echo ""

# Build
echo "🔨 Building extension..."
npm run vscode:prepublish

# Publish
echo "📤 Publishing to Marketplace..."
vsce publish

echo ""
echo "✅ Published successfully!"
echo ""
echo "View on Marketplace:"
echo "https://marketplace.visualstudio.com/items?itemName=genai-dev.genai-codebase-search"
```

Then:
```bash
bash extensions/vscode/deploy.sh
```

---

## 🎓 Advanced: Pre-publish Checks

Before publishing, verify:

```bash
# Build check
npm run compile

# Package check
npm run vscode:prepublish

# Test locally first
code --install-extension genai-codebase-search-0.1.0.vsix

# Test in VS Code
# Press Ctrl+Shift+G to verify it works
```

---

## 🔗 Useful Links

- [Marketplace Publisher Management](https://marketplace.visualstudio.com/manage)
- [VSCE Documentation](https://github.com/microsoft/vscode-vsce)
- [VS Code Extension Guidelines](https://code.visualstudio.com/api/extension-guides/extension-manifest)
- [Marketplace Quality Guidelines](https://code.visualstudio.com/api/working-with-extensions/publishing-extension)

---

## 📚 Summary

| Step | Task | Time |
|------|------|------|
| 1 | Create Microsoft Account | 5m |
| 2 | Create Azure DevOps Org | 5m |
| 3 | Generate PAT | 5m |
| 4 | Create Publisher Account | 5m |
| 5 | Update package.json | 2m |
| 6 | Install VSCE | 2m |
| 7 | Login to Marketplace | 1m |
| 8 | Publish | 5m |
| 9 | Verify | 5m |
| **Total** | | **~40 minutes** |

---

**You're ready to publish!** 🎉

Follow these steps and your extension will be available to millions of VS Code users!
