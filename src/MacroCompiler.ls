require! {
    \util
    'fs'
    './Macro'
    './ast': Ast
    './runtime-patch'
    './check'
    './ASTCompiler'
    './TypeSelector'
    './SelectorManipulator'
    './AndSelector'
    './SeriesSelector'
    './TypeSelector'
    './selectors' : { node-selector }
}

macro-expansion-selector = new AndSelector
    ..append new TypeSelector 'Chain'
    ..append new SeriesSelector
        ..captures.start = ->
            it{line:first_line, column:first_column}
        ..append new TypeSelector 'Var'
            ..captures.name = (.value)
        ..append new TypeSelector 'Call'
        ..append new TypeSelector 'Call'
            ..captures
                ..args = -> [..value for it.args]
                ..end = -> it{line:last_line, column:last_column}


macro-definition-selector = new AndSelector
    ..append new TypeSelector 'Assign'
    ..append new SeriesSelector
        ..append new AndSelector
            ..append new TypeSelector 'Chain'
            ..append new SeriesSelector
                ..append new TypeSelector 'Var'
                    ..captures.name = (.value)
                ..append new TypeSelector 'Call'
        ..append new TypeSelector 'Fun'
            ..captures.ast = -> it


# those sholud be declarative equivalent of above
macro-definition-selector = node-selector do
    type: \Assign
    series:
        *   type: \Chain
            series:
                *   type: \Var
                    capture:
                        name: -> it.value
                *   type: \Call
        *   type: \Fun
            capture:
                ast: -> it


macro-expansion-selector = node-selector do
    type: \Chain
    series:
        *   type: \Var
            capture:
                name: -> it.value
                start: -> it{line:first_line, column:first_column}
        *   type: \Call
        *   type: \Call
            capture:
                args: -> [..value for it.args]
                end: -> it{line:last_line, column:last_column}



class MacroCompiler
    module.exports = @

    !->
        # track available macros
        @macros = {}
        @_need_replacing = []


    compile-code: (code, {filename, map = true}) ->
        ast = ASTCompiler.compile code
        @search-for-macros ast
        @remove-macros-definitions ast
        ast = @compile ast
        file-name-js = filename.replace /.ls$/, '.js'
        file-name-map = file-name-js + '.map'
        output = ast.compile-root {filename}
        output.set-file filename
        if map
        then output.to-string-with-source-map!
        else output.to-string!

    check-if-macro-definition: (ast, parent) !->
        check.is-defined ast, \ast
        maybe-macro = macro-definition-selector.match ast
        if maybe-macro
            new Macro maybe-macro.name, maybe-macro.ast, parent
                @macros[maybe-macro.name] = ..
                ..original-node = ast


    check-if-macro-expansion: (ast, parent) !->
        check.is-defined ast, \ast
        maybe-macro = macro-expansion-selector.match ast
        if maybe-macro
            unless @macros[maybe-macro.name]
                return
            children = if parent.children.0 == 'lines'
                then parent.lines
                else parent.children

            @_need_replacing.push do
                loc:
                    start: maybe-macro.start
                    end: maybe-macro.end
                node: parent
                child: ast
                children: children
                child-idx: children.index-of ast
                macro: @macros[maybe-macro.name]
                args: maybe-macro.args
                is-block: parent.children.0 == 'lines'

    # searching for macros definition
    search-for-macros: (ast) ->
        ast.traverse-children @~check-if-macro-definition

    remove-macros-definitions: (ast) ->
        for n, macro of @macros
            macro.parent.remove-child macro.original-node

    _copy_location: (src, dest) !-->
        # don't copy 'source' because I don't know where is it used
        dest{first_line,first_column,last_line,last_column,line,column} = src

    copy-location: (src, dest, {recursive}) !->
        @_copy_location src, dest
        if recursive
            dest.traverse-children @_copy_location src

    _set-location: (loc, node) !-->
        node
            ..line = loc.start.line
            ..column = loc.start.column
            ..first_line = loc.start.line
            ..first_column = loc.start.column
            ..last_line = loc.end.line
            ..last_column = loc.end.column


    set-location: (loc, node, {recursive} = check.is-argument 'options', {}) !->
        set-location = @_set-location loc
        set-location node
        if recursive
            node.traverse-children set-location


    expand-macro: ({node, child, child-idx,children,macro,args, loc}) ->
        o = &0
        new-ast = macro.to-ast ...args
        @set-location loc, new-ast, {+recursive}
        check.has-method 'removeChild', node
        node.replace-child child, new-ast

    find-macros-expressions: (ast) ->
        ast.traverse-children @~check-if-macro-expansion
        result = @_need_replacing
        @_need_replacing = []
        result

    compile: (ast) ->
        while (expressions = @find-macros-expressions ast).length > 0
            for expression in expressions
                try
                    @expand-macro expression
                catch
                    e.message = "Expanding macro #{expression.macro.name}: #{e.message}"
                    throw e
        ast

    transform-ast: (ast) ->
        while (expressions = @find-macros-expressions ast).length > 0
            # console.log 'Expanding pass'
            for expression in expressions
                # console.log "expanding #{expression.macro.name}"
                try
                    @expand-macro expression
                catch
                    e.message = "Expanding macro #{expression.macro.name}: #{e.message}"
                    throw e
        ast
