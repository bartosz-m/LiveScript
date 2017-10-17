require! {
    'fs'
    \path
    'diff-lines'

    '../lib/MacroCompiler'
}

test-compilation = ({ls-code,js-code,filename}) !->
    try
        macro-compiler = new MacroCompiler
        # console.log '##### Compiling:'
        # console.log ls-code
        generated-output = macro-compiler.compile-code ls-code, {filename, map: false}
        # console.log '##### Finished'
        if generated-output != js-code
            # Uwaga na nowe linie na końcu pliku źródła
            console.log "Generated output is different than expected"
            console.log diff-lines js-code, generated-output
    catch
        console.log '##### Error'
        console.error e.message
        console.error e.stack


tests = fs.readdir-sync './test/data/macros/' .filter (.match /\.ls$/)

for test in tests
    console.log "testing #{test}"
    code-file = path.join './test/data/macros/', test
    output-file = code-file.replace /\.ls$/ '.js'
    ls-code = fs.read-file-sync code-file, \utf8
    js-code = fs.read-file-sync output-file, \utf8
    test-compilation {ls-code, js-code, filename: code-file}
