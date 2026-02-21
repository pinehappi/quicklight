local result = require(script.Parent.Parent.result)
local types = require(script.Parent.Parent.types)
local arrowGizmo = require(script.Parent.Parent.app.gizmos.arrowGizmo)
local theme = require(script.Parent.Parent.app.theme)

return function(initial, object)
	return {
		update = function(current)
			local dir = CFrame.lookAt(
				current.mousePosition,
				initial.mousePosition
			).LookVector

			return result.ok({
				direction = dir,
			})
		end,
		gizmo = function(current, placement)
			return arrowGizmo {
				color = theme.accent.faint,
				from = initial.mousePosition,
				to = function()
					return current().mousePosition
				end,
				startRadius = 0.5,
				endRadius = 0.5,
				thickness = 0.05,
			}
		end,
	}
end :: types.Tool