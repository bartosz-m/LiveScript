swap! = (a,b) -> """
    tmp = #a
    #a = #b
    #b = tmp
"""
define! = (x) ->
    "var #x"

import-all! = (_module) ->
    "for k, v of #{_module} => eval " + '"var #k = v"'

esm-export! = (a,b) ->
    if b?
      if a != "'default'"
          throw Error "Cannot rename export #b to #a. Renaming exports is not supported yet"
      "``export default #b``"
    else
        "export #a"

define! d
x = 12
y = 1
swap! x, y
console.log x, y
import-all! system
esm-export! \default, d
