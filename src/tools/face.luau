local result = require(script.Parent.Parent.result)
local types = require(script.Parent.Parent.types)
local arrowGizmo = require(script.Parent.Parent.app.gizmos.arrowGizmo)
local theme = require(script.Parent.Parent.app.theme)
local reflect = require(script.Parent.Parent.utils.reflect)

return {
	update = function(_, current)
		local rayDirection = CFrame.lookAt(current.cameraPosition, current.mousePosition)

		if not current.mouseNormal then
			return result.error("Cursor must be on a face!")
		end

		local reflection = reflect(rayDirection.LookVector, current.mouseNormal)
		local dir = CFrame.lookAt(
			current.cameraPosition,
			current.cameraPosition + reflection
		).LookVector

		return result.ok({ direction = dir } :: any)
	end,
	gizmo = function(initial, current, direction)
		return arrowGizmo {
			color = theme.accent.faint,
			from = function()
				return current().mousePosition
			end,
			to = function()
				local normal = current().mouseNormal
				if normal then
					return current().mousePosition + 4 * normal
				else
					return current().mousePosition
				end
			end,
			startRadius = 0.2,
			endRadius = 0.5,
			thickness = 0.05,
		}
	end,
} :: types.Tool