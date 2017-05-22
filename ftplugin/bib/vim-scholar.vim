if !has('python3')
    echo "Error: vim compiled with +python3 is required"
    finish
endif

let s:path = expand('<sfile>:p:h')

function! GScholarWizard()

python3 << EOF
import vim, os, sys
scriptDir = vim.eval("s:path")
sys.path.append(scriptDir)
from scholar import *

def pythonInput(message = ''):
    vim.command('call inputsave()')
    vim.command("let user_input = input('" + message + ": ')")
    vim.command('call inputrestore()')
    return vim.eval('user_input')

def pythonInputList(message, optionlist):
    vim.command('call inputsave()')
    vim.command("let user_input = inputlist(['" + message + ": ', '" + "', '".join(optionlist) + "'])")
    vim.command('call inputrestore()')
    return vim.eval('+user_input')

def conciseAsTxt(art):
    items = sorted([x for x in art.attrs.values() if x[2] in range(0,3)], key=lambda item: item[2])
    max_label_len = max([len(str(item[1])) for item in items])
    fmt = '%%%ds %%s' % max_label_len
    res = []
    for item in items:
        if item[0] is not None:
            res.append(fmt % (item[1], item[0]))
    return "\n".join(res)

def insertCitationData(art):
    citationLines = art.as_citation().split(b'\n')
    row, col = vim.current.window.cursor
    vim.current.buffer[row:row] = citationLines
    lines = len(citationLines)
    vim.current.window.cursor = (row + lines, col)

def retrieveCitationArticle(art):
    clusterID = art['cluster_id']
    
    querier = ScholarQuerier()
    settings = ScholarSettings()
    settings.set_citation_format(ScholarSettings.CITFORM_BIBTEX)
    querier.apply_settings(settings)
    query = ClusterScholarQuery(cluster=clusterID)
    querier.send_query(query)

    return querier.articles[0]

def insertURLatEOL(row, art):
    if (art['url_pdf'] is not None):
        vim.current.buffer[row] += '% ' + art['url_pdf']

author = pythonInput('Author(s)')
title = pythonInput('Title')

querier = ScholarQuerier()
query = SearchScholarQuery()
query.set_author(author)
query.set_words(title)
query.set_scope(True)
querier.send_query(query)
articles = querier.articles
noOfArticles = len(articles)

if noOfArticles == 0:
    print("No result found.")
elif noOfArticles == 1:
    insertCitationData(retrieveCitationArticle(articles[0]))
    row, col = vim.current.window.cursor
    insertURLatEOL(row-2, articles[0])
else:
    print('\nResults:')
    for i in range(0,noOfArticles):
        print(i+1)
        print(conciseAsTxt(articles[i]))
    articleChoice = pythonInputList('Choose the desired article number', [str(i) for i in range(1,noOfArticles+1)])
    articleNo = int(articleChoice) - 1
    if (articleNo != -1):
        art = articles[articleNo]
        lines = insertCitationData(retrieveCitationArticle(art))
        row, col = vim.current.window.cursor
        insertURLatEOL(row-2, art)



EOF

endfunction

:map <Leader>gs :call GScholarWizard()<CR>
