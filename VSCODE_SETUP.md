# VS Code Extension - Complete Setup Guide

Get GenAI Codebase Search working in VS Code in 5 minutes.

---

## 📋 Prerequisites

- VS Code 1.80+
- Node.js 16+ (for building from source)
- GenAI Lambda deployed with API Gateway URL

---

## 🚀 Option 1: From VS Code Marketplace (Future)

When published to the marketplace:

1. Open VS Code
2. Press `Ctrl+Shift+X` (Extensions)
3. Search: `"GenAI Codebase Search"`
4. Click **Install**
5. Go to settings and configure API URL

---

## 🛠️ Option 2: Build from Source (Now)

Use this if you want to build and install the extension immediately.

### Step 1: Install Dependencies

```bash
cd extensions/vscode
npm install
```

### Step 2: Compile TypeScript

```bash
npm run compile
```

This generates `out/extension.js` and `out/extension.js.map`

### Step 3: Package Extension

```bash
npm run vscode:prepublish
```

This creates `genai-codebase-search-0.1.0.vsix`

### Step 4: Install in VS Code

```bash
code --install-extension genai-codebase-search-0.1.0.vsix
```

Or manually:
1. Open VS Code
2. Press `Ctrl+Shift+X` (Extensions)
3. Click **⋯** (three dots) → Install from VSIX
4. Select `genai-codebase-search-0.1.0.vsix`

### Step 5: Reload VS Code

Restart VS Code or press `Ctrl+Shift+P` → "Developer: Reload Window"

---

## 🔧 Option 3: Development Mode

Use this if you want to modify the extension code.

### Step 1: Install Dependencies

```bash
cd extensions/vscode
npm install
```

### Step 2: Watch for Changes

```bash
npm run watch
```

This watches TypeScript files and recompiles on save.

### Step 3: Open Debug Session

1. Press `Ctrl+Shift+D` (Debug panel)
2. Select "Extension" from dropdown
3. Press `F5` or click **Run**

VS Code opens a new window with the extension loaded.

### Step 4: Test Changes

- Make changes to `src/extension.ts`
- Press `Ctrl+Shift+P` → "Developer: Reload Window"
- Test your changes

### Step 5: Stop Debugging

Press `Shift+F5` or click Stop button.

---

## ⚙️ Configuration

### Option A: VS Code Settings UI

1. Press `Ctrl+,` (Settings)
2. Search: `"genai"`
3. Fill in:
   - **API URL**: `https://your-api.execute-api.us-east-1.amazonaws.com/prod`
   - **Default Namespace**: `my-repo`

### Option B: settings.json

1. Press `Ctrl+Shift+P` → "Preferences: Open Settings (JSON)"
2. Add:

```json
{
  "genai.apiUrl": "https://your-api.execute-api.us-east-1.amazonaws.com/prod",
  "genai.defaultNamespace": "my-repo"
}
```

### Option C: Workspace Settings

For project-specific settings, create `.vscode/settings.json`:

```json
{
  "genai.apiUrl": "https://your-api.execute-api.us-east-1.amazonaws.com/prod",
  "genai.defaultNamespace": "my-current-project"
}
```

---

## 🎯 Usage

### Quick Search

Press **`Ctrl+Shift+G`** (or `Cmd+Shift+G` on Mac)

Type your question:
```
How does authentication work?
```

Select repository namespace:
```
[my-repo] ▼
```

Results appear in the **Output** panel.

### From Command Palette

Press `Ctrl+Shift+P` and type:
```
GenAI: Search Codebase
```

### From Status Bar

Click the **GenAI Search** button in the bottom-right status bar.

---

## 📊 Features

| Feature | Shortcut | Menu |
|---------|----------|------|
| Search | `Ctrl+Shift+G` | Command Palette |
| Settings | - | Settings (Ctrl+,) |
| Index Repo | - | Command Palette |

---

## 📤 Output Panel

Results display in the **Output** panel showing:

```
Question: How does authentication work?

Answer:
The authentication module in auth.py handles...

Sources:
  1. auth.py (92%)
  2. config.py (78%)
  3. utils.py (65%)
```

Click file paths to open them in the editor.

---

## 🐛 Troubleshooting

### "Extension not found"

Make sure you installed it correctly:

```bash
# Check installed extensions
code --list-extensions | grep genai
```

If not listed, reinstall:

```bash
code --install-extension genai-codebase-search-0.1.0.vsix --force
```

### "API URL not configured"

1. Press `Ctrl+,` (Settings)
2. Search: `genai.apiUrl`
3. Enter your API Gateway URL

### "Connection refused"

Check:
- API URL is correct (ends without `/ask`)
- Lambda is deployed: `aws lambda list-functions`
- You're in the correct region (us-east-1)

### "No results found"

- Make sure repository is indexed
- Check namespace matches what you indexed
- Try a different search query

### "API Key invalid" (if authentication enabled)

Add to settings:

```json
{
  "genai.apiKey": "your-api-key"
}
```

---

## 📁 Project Structure

```
extensions/vscode/
├── src/
│   └── extension.ts       ← Extension code
├── package.json           ← Metadata
├── tsconfig.json          ← TypeScript config
├── .vscodeignore           ← Files to exclude
└── README.md              ← User guide
```

---

## 🔨 Development

### Build Commands

```bash
# Compile TypeScript
npm run compile

# Watch for changes (dev mode)
npm run watch

# Package for distribution
npm run vscode:prepublish

# Lint code
npm run lint

# Run tests
npm run test
```

### File Structure

```
src/extension.ts
├── activate()           - Called when extension loads
├── handleSearch()       - Search command handler
├── statusBar            - Status bar button
└── deactivate()         - Called on unload
```

### Adding New Features

To add a new command:

1. Add to `package.json`:
```json
{
  "command": "genai.newFeature",
  "title": "GenAI: New Feature"
}
```

2. Register in `src/extension.ts`:
```typescript
let newCommand = vscode.commands.registerCommand('genai.newFeature', () => {
  // Handle command
});
context.subscriptions.push(newCommand);
```

---

## 📦 Publishing to Marketplace

When ready to publish:

```bash
# Install VSCE globally
npm install -g @vscode/vsce

# Login to marketplace
vsce login

# Publish
vsce publish
```

Requires:
- Microsoft account
- Publisher account
- Version bump in package.json

---

## 🔐 Security

Settings are stored in VS Code's secure storage:

- `genai.apiUrl` - Visible in settings
- `genai.apiKey` - Encrypted by VS Code
- `genai.defaultNamespace` - Visible in settings

Never commit API keys to git!

---

## 📚 Resources

- [VS Code Extension API](https://code.visualstudio.com/api)
- [Extension Examples](https://github.com/microsoft/vscode-extension-samples)
- [Marketplace Guidelines](https://code.visualstudio.com/api/extension-guides/extension-manifest)

---

## ✅ Verification Checklist

- [ ] Node.js installed: `node --version`
- [ ] Dependencies installed: `npm install`
- [ ] Code compiles: `npm run compile`
- [ ] Extension packaged: `npm run vscode:prepublish`
- [ ] Installed in VS Code: `code --list-extensions | grep genai`
- [ ] API URL configured in settings
- [ ] Namespace configured in settings
- [ ] `Ctrl+Shift+G` opens search dialog
- [ ] Lambda endpoint is reachable
- [ ] Repository is indexed

---

## 🎉 Next Steps

1. ✅ Install the extension (Option 1, 2, or 3)
2. ✅ Configure API URL and namespace
3. ✅ Press `Ctrl+Shift+G` and search
4. ✅ Get source-cited answers in VS Code

**Happy searching!** 🚀
