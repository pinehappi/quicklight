local types = require(script.Parent.Parent.types)
local result = require(script.Parent.Parent.result)

return {
	update = function(lightSource, initial, current)
		local lightDirection = initial.sunDirection
		local wasMoonUp = (initial.sunDirection:Dot(Vector3.new(0, 1, 0))) < 0
		if wasMoonUp then
			lightDirection = initial.moonDirection
		end
		
		local negative = (current.mousePosition - initial.mousePosition)
		local otherDist = (current.cameraPosition - initial.mousePosition).Magnitude
		local dir = CFrame.lookAt(
			initial.mousePosition - lightDirection * otherDist,
			initial.mousePosition - negative
		).LookVector

		return result.ok({ direction = dir } :: any)
	end,
} :: types.Placer