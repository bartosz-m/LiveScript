require! {
    './lexer'
    './parser': {parser}
    './ast'
    # 'source-map': {SourceNode}
    # path
}

# Override Jison's default lexer, so that it can accept
# the generic stream of tokens our lexer produces.
_parser = ^^parser
<<<
    yy: ast
    lexer:
        lex: ->
            [tag, @yytext, first_line, first_column] = @tokens[++@pos] or [''];
            [,, last_line, last_column] = @tokens[@pos+1] or [''];
            @yylineno = first_line
            @yylloc =
                first_line: first_line
                first_column: first_column
                last_line: last_line
                last_column: last_column
            tag
        set-input: ->
            @pos = -1
            @tokens = it
        upcoming-input: -> ''
# _parser <<<< parser

exports <<<
    VERSION: '1.5.0'

    # # Parses a string or tokens of LiveScript code,
    # returning the [AST](http://en.wikipedia.org/wiki/Abstract_syntax_tree).
    compile: ->
        _parser.parse (if typeof it is 'string' then lexer.lex it else it)
