" GenAI Autoload Functions

function! genai#open_search()
    " Open search prompt
    let question = input('GenAI Search: ')
    if empty(question)
        return
    endif

    call genai#search(question)
endfunction

function! genai#search(question)
    " Search with GenAI
    if empty(g:genai_api_url)
        echo 'Error: genai_api_url not configured. Run :GenaiConfig'
        return
    endif

    if empty(g:genai_namespace)
        let namespace = input('Namespace: ')
        if empty(namespace)
            return
        endif
    else
        let namespace = g:genai_namespace
    endif

    " Build request
    let request = {
        \ 'question': a:question,
        \ 'namespace': namespace,
        \ 'top_k': g:genai_top_k
    \ }

    " Make API call
    let cmd = 'curl -s -X POST ' . shellescape(g:genai_api_url) .
        \ ' -H "Content-Type: application/json"' .
        \ ' -d ' . shellescape(json_encode(request))

    let response_text = system(cmd)

    if v:shell_error != 0
        echo 'Error: API request failed'
        return
    endif

    " Parse response
    try
        let response = json_decode(response_text)
    catch
        echo 'Error: Invalid JSON response'
        return
    endtry

    " Display result
    call genai#display_result(response)
endfunction

function! genai#display_result(response)
    " Create buffer for result
    silent! bdelete GenAI
    new
    setlocal buftype=nofile
    setlocal noswapfile
    file GenAI

    " Add content
    call append(0, 'GenAI Search Result')
    call append(1, '===================')
    call append(2, '')

    " Add answer
    call append(3, 'Answer:')
    call append(4, '-------')
    let answer_lines = split(a:response['answer'], '\n')
    call append(5, answer_lines)

    " Add sources
    let source_line = len(answer_lines) + 7
    call append(source_line, '')
    call append(source_line + 1, 'Sources:')
    call append(source_line + 2, '--------')

    if has_key(a:response, 'sources') && len(a:response['sources']) > 0
        let line_num = source_line + 3
        for source in a:response['sources']
            let source_text = printf('  • %s (%.0f%%)',
                \ source['file_path'],
                \ source['score'] * 100)
            call append(line_num, source_text)
            let line_num += 1
        endfor
    else
        call append(source_line + 3, '  No sources found')
    endif

    " Set options
    setlocal readonly
    setlocal nomodifiable
    setlocal wrap
    normal gg
endfunction

function! genai#config()
    " Open configuration
    echo 'GenAI Configuration'
    echo ''
    echo 'Current settings:'
    echo '  API URL: ' . (empty(g:genai_api_url) ? '(not set)' : g:genai_api_url)
    echo '  Namespace: ' . (empty(g:genai_namespace) ? '(not set)' : g:genai_namespace)
    echo '  Top K: ' . g:genai_top_k
    echo ''
    echo 'Set in your .vimrc:'
    echo '  let g:genai_api_url = "https://..."'
    echo '  let g:genai_namespace = "my-repo"'
    echo '  let g:genai_top_k = 6'
endfunction

function! genai#index()
    " Index current repository
    let repo_path = getcwd()
    echo 'To index this repository, run:'
    echo ''
    echo 'python3 -m ingestion.pipeline --repo ' . repo_path . ' --namespace ' . fnamemodify(repo_path, ':t')
endfunction

function! genai#on_filetype()
    " Called on filetype change
    " Can add language-specific shortcuts here
endfunction
