require! {
    'util'
    './ASTCompiler'
    './ast': AST
    './check'
    './AndSelector'
    './AnySelector'
    './TypeSelector'
    './PropertySelector'
    './SeriesSelector'
}

and-selector = (selectors) ->
    new AndSelector
        for s in selectors => ..append s

property-selector = (name, inner) ->
    new PropertySelector name
        ..inner = inner if typeof inner == 'Object'

exists = -> it?
as-number = -> +it
flat-wrap-array = ->
    unless 'Array' == typeof! it
        [it]
    else
        it

require! \./selectors : { node-selector }

match-block-expr = node-selector do
    type: 'Fun'
    properties:
        params: null
        body:
            type: 'Block'
            capture: block: -> it
            series: [
                    type: 'Chain'
                    capture: to-delete: -> it
                    series: [
                        *   type: 'Literal'
                            properties:
                                value:# null
                                    capture: literal: -> it
                        *   type: 'Call'
                            capture: args: (.args)
                            properties:
                                args: null
                    ]
            ]

# Block można skompilować inne nie za bardzo
as-compilable-ast = ->
    unless it instanceof AST.Block
        new AST.Block
            ..add it
    else
        it

ast-to-source-node = -> it.compile-root {+bare}

as-source-node = ast-to-source-node << as-compilable-ast

source-node-to-js = -> it.to-string!

as-js = source-node-to-js << as-source-node

evaluate-ast = -> eval as-js it

class Macro
    module.exports = @

    (@name, @ast, @parent) ->
        check.args-length 3, &
        check.is-defined @ast, \ast
        @type = 'Macro'
        match-block-ast = match-block-expr.match @ast
        if match-block-ast
            matcher = evaluate-ast match-block-ast.args.0
            @matcher = node-selector matcher
            match-block-ast.block.remove-child match-block-ast.to-delete
        @block = new AST.Block
        @block.add @ast
        source-node =  eval @block.compile-root {+bare, -header}
        @implementation = eval source-node.to-string!

    eval: ->
        @implementation.apply {node-selector}, &

    to-ast: ->
        code = @eval ...&
        # console.log 'code: ', code
        ast = ASTCompiler.compile code
