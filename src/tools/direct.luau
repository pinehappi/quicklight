local result = require(script.Parent.Parent.result)
local types = require(script.Parent.Parent.types)

return function(initial, object)
	return {
		update = function(current, distance)
			return result.ok({
				direction = current.mouseDirection
			})
		end,
	}
end :: types.Tool