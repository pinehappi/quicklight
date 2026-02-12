local types = require(script.Parent.types)
return {
    direct = require(script.direct),
    line = require(script.line),
    bounce = require(script.bounce),
    face = require(script.face),
    shadow = require(script.shadow),
} :: {[string]: types.Tool}