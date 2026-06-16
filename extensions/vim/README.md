# GenAI Codebase Search - Vim Plugin

Search your codebase with AI directly from Vim.

## Installation

### Using Vim-Plug

Add to your .vimrc:

```vim
Plug 'saitarrun/genai-dev-assistant', { 'rtp': 'extensions/vim' }
```

Then run `:PlugInstall`

### Using Pathogen

```bash
cd ~/.vim/bundle
git clone https://github.com/saitarrun/genai-dev-assistant.git
cd genai-dev-assistant/extensions/vim
```

### Manual Installation

Copy plugin and autoload files to your Vim config:

```bash
cp extensions/vim/plugin/genai.vim ~/.vim/plugin/
cp extensions/vim/autoload/genai.vim ~/.vim/autoload/
```

## Configuration

Add to your `.vimrc`:

```vim
" API Gateway URL from deployment
let g:genai_api_url = 'https://your-api-gateway.execute-api.us-east-1.amazonaws.com/prod/ask'

" Default repository namespace
let g:genai_namespace = 'my-repo'

" Number of documents to retrieve (default: 6)
let g:genai_top_k = 6

" Keybinding (default: <Leader>gs)
map <Leader>g :call genai#open_search()<CR>
```

## Usage

### Quick Search

```vim
:GenaiSearch How does authentication work?
```

Or press `<Leader>gs` (default: `\gs`)

Type your question and press Enter.

### Configure Settings

```vim
:GenaiConfig
```

Shows current configuration and setup instructions.

### Index Repository

```vim
:GenaiIndex
```

Shows command to index your repository.

## Examples

### Search from Vim

```vim
" In normal mode
:GenaiSearch
" Type: How does the database connection work?
" Results appear in a new buffer

" Or search directly with a question
:GenaiSearch What are the main modules?
```

### Configure for Your Project

```vim
" Add to .vimrc for your project
autocmd VimEnter * let g:genai_namespace = 'my-project'
```

### Keybindings

Add to your `.vimrc`:

```vim
" Quick search with <Leader>s
nmap <Leader>s :call genai#open_search()<CR>

" Or use custom keybinding
nmap <C-g> :call genai#open_search()<CR>
```

## Commands

| Command | Description |
|---------|-------------|
| `:GenaiSearch [question]` | Search with optional question |
| `:GenaiConfig` | Show current configuration |
| `:GenaiIndex` | Show indexing instructions |

## Keybindings

| Default | Description |
|---------|-------------|
| `<Leader>gs` | Open search prompt |

## Requirements

- Vim 8.0+
- `curl` command-line tool
- GenAI Lambda deployed with API Gateway
- Python for indexing repositories

## Troubleshooting

### "API URL not configured"
```vim
:GenaiConfig
" See instructions for setting g:genai_api_url
```

### "Connection refused"
- Check API URL is correct in .vimrc
- Verify Lambda is deployed
- Ensure namespace matches indexed repository

### Results not showing
- Make sure repository has been indexed
- Check namespace is correct
- Try a different search query

## Configuration Example

Full `.vimrc` setup:

```vim
" GenAI Configuration
let g:genai_api_url = 'https://your-api.execute-api.us-east-1.amazonaws.com/prod/ask'
let g:genai_namespace = 'my-repo'
let g:genai_top_k = 8

" Keybindings
nmap <silent> <Leader>s :call genai#open_search()<CR>
nmap <silent> <Leader>c :GenaiConfig<CR>

" Auto-complete based on selected text
vnoremap <silent> <Leader>s :<C-U>call genai#search(v:selection)<CR>
```

## Tips

1. **Indexed Repos** — Make sure your repository is indexed before searching
2. **Namespace Matching** — Use the same namespace you used during indexing
3. **Query Quality** — Be specific in your questions for better results
4. **Top K** — Increase `g:genai_top_k` for more context (slower)

## Development

To contribute or modify the plugin:

```bash
# Clone the repository
git clone https://github.com/saitarrun/genai-dev-assistant.git
cd genai-dev-assistant/extensions/vim

# Test in Vim
vim -u NONE -N -S plugin/genai.vim
```

## License

MIT
