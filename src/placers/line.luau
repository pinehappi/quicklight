local result = require(script.Parent.Parent.result)
local types = require(script.Parent.Parent.types)
local arrowGizmo = require(script.Parent.Parent.ui.gizmos.arrowGizmo)
local theme = require(script.Parent.Parent.ui.theme)

return {
	update = function(lightSource, initial, current)
		local dir = CFrame.lookAt(
			current.mousePosition,
			initial.mousePosition
		).LookVector

		return result.ok({ direction = dir } :: any)
	end,
	gizmo = function(initial, current)
		return arrowGizmo {
			color = theme.accent.light,
			from = initial.mousePosition,
			to = function()
				return current().mousePosition
			end,
			startRadius = 0.5,
			endRadius = 0.5,
			thickness = 0.05,
		}
	end
} :: types.Placer