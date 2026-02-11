local Lighting = game:GetService("Lighting")
return function(direction: Vector3, longitudeFactor: number)
    local latitude = math.atan2(direction.Z, math.sqrt(direction.X^2 + direction.Y^2))
	local longitude = math.atan2(direction.Y * longitudeFactor, direction.X * longitudeFactor)

	local geographicLatitude = (latitude / math.pi / 2) * 360 + 23.5
	local clockTime = (longitude / math.pi / 2) * 24 - 6

	Lighting.ClockTime = clockTime % 24
	Lighting.GeographicLatitude = geographicLatitude 
end
