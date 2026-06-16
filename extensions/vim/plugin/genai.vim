" GenAI Codebase Search Vim Plugin
" Search your codebase with AI from Vim

if exists('g:loaded_genai')
    finish
endif
let g:loaded_genai = 1

" Settings
let g:genai_api_url = get(g:, 'genai_api_url', '')
let g:genai_namespace = get(g:, 'genai_namespace', '')
let g:genai_top_k = get(g:, 'genai_top_k', 6)

" Commands
command! -nargs=+ GenaiSearch call genai#search(<q-args>)
command! -nargs=0 GenaiConfig call genai#config()
command! -nargs=0 GenaiIndex call genai#index()

" Keybindings
if !hasmapto('<Plug>(genai-search)')
    map <unique> <Leader>gs <Plug>(genai-search)
endif

noremap <unique> <script> <Plug>(genai-search) :call genai#open_search()<CR>

" Autocommands
augroup GenAI
    autocmd!
    autocmd FileType * call genai#on_filetype()
augroup END
