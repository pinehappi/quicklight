local vide = require(script.Parent.Parent.Packages.vide)
local result = require(script.Parent.Parent.result)
local types = require(script.Parent.Parent.types)
local arrowGizmo = require(script.Parent.Parent.app.gizmos.arrowGizmo)
local theme = require(script.Parent.Parent.app.theme)
local reflect = require(script.Parent.Parent.utils.reflect)

return {
	update = function(_, current)
		local reflection = reflect(current.mouseDirection, Vector3.new(0,1,0))
		local dir = CFrame.lookAt(
			current.mousePosition,
			current.mousePosition + reflection
		).LookVector

		return result.ok({ direction = dir } :: any)
	end,
	gizmo = function(initial, current, direction)
		local horizontalDirection = function()
			local result = direction():Cross(Vector3.new(0, 1, 0))
			if math.abs(direction().Unit.Y) > 0.995 then
				result = Vector3.new(1, 0, 0)
			end
			return result
		end

		return vide.create "Folder" {
			arrowGizmo {
				color = theme.accent.faint,
				from = function()
					return current().mousePosition
				end,
				to = function()
					return current().mousePosition + Vector3.new(0, 4, 0)
				end,
				startRadius = 0,
				endRadius = 0.5,
				thickness = 0.05,
			},
			arrowGizmo {
				color = theme.accent.faint,
				from = function()
					return current().mousePosition - 4*horizontalDirection()
				end,
				to = function()
					return current().mousePosition + 4*horizontalDirection()
				end,
				startRadius = 0,
				endRadius = 0,
				thickness = 0.05,
			}
		}
	end,
} :: types.Tool