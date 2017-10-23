require! {
    './ast'
}

get-type = ->
    | it.type => that
    | it@@display-name => that
    | it@@name => that
    | otherwise => it.to-string!

# Node isn't exported so we can only access its prototype through from one of its derived classes
ast.Node-prototype = (Object.get-prototype-of ast.Chain::)

ast.Node-prototype.remove-child = ->
    throw Error "#{get-type @@} doesn't implement method remove-child"

ast.Node-prototype.replace-child = ->
    throw Error "#{get-type @} doesn't implement method replace-child"

ast.Node-prototype.to-macro-value = ->
    console.warn "Warning: #{get-type @} doesn't implement method to-macro-value"
    void

classes = <[ Assign Block Call Cascade Chain Literal Var Splat ]>
for name in classes
    ast[name]::type = name

ast.Block::[Symbol.iterator] = !->*
    for line in @lines
        yield line

ast.Chain::[Symbol.iterator] = !->*
    yield @head
    for @tails => yield ..

ast.Assign::[Symbol.iterator] = !->*
    yield @left
    yield @right

ast.Fun::[Symbol.iterator] = !->*
    yield @params if @params?
    yield @body

ast.Block::remove-child = (child) ->
    if @back == child
        delete @back
    idx = @lines.index-of child
    unless idx >= 0
        throw Error "Cannot remove [#{child@@name}] from [Block]"
    @lines.splice idx, 1

ast.Block::replace-child = (child, new-one) ->
    if @back? and @back == child
        @back = new-one
    idx = @lines.index-of child
    unless idx >= 0
        throw Error "Cannot replace [#{child@@name}] in [Block]"
    @lines.splice idx, 1, new-one

ast.Cascade::replace-child = (child, new-one) ->
    | @input == child => @input = new-one
    | @output == child => @output = new-one
    | otherwise => throw Error "Cannot replace [#{get-type child}] in [Cascade]"

ast.Assign::replace-child = (child, new-one) ->
    if @right == child
        @right = new-one
    else if  @left == child
        @left = new-one
    else
        throw Error "Cannot replace [#{get-type child}] in [Assign]"


ast.Var::[Symbol.iterator] = ->*
    yield @value

ast.Call::[Symbol.iterator] = ->*
    yield @args

ast.Splat::[Symbol.iterator] = ->*
    yield @it
ast.Splat::replace-child = (child, new-one) ->
    if child == @it
        @it = new-one
    else
        throw Error "Cannot replace [#{get-type child}] in [Splat]"

ast.Literal::to-macro-value = -> @value
ast.Var::to-macro-value = -> @value
