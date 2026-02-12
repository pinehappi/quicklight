local result = require(script.Parent.Parent.result)
local types = require(script.Parent.Parent.types)

return {
	update = function(_, current)
		return result.ok({ direction = current.mouseDirection } :: any)
	end,
} :: types.Tool