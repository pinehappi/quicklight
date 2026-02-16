local result = require(script.Parent.Parent.result)
local types = require(script.Parent.Parent.types)

return {
	run = function()
		return function(current)
			return result.ok({
				lightInfo = { direction = current.mouseDirection }
			})
		end
	end,
} :: types.Tool