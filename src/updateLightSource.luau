local Lighting = game:GetService("Lighting")
local types = require(script.Parent.types)

local function updateSkyFromDirection(direction: Vector3, longitudeFactor: number)
    local latitude = math.atan2(direction.Z, math.sqrt(direction.X^2 + direction.Y^2))
	local longitude = math.atan2(direction.Y * longitudeFactor, direction.X * longitudeFactor)

	local geographicLatitude = (latitude / math.pi / 2) * 360 + 23.5
	local clockTime = (longitude / math.pi / 2) * 24 - 6

	Lighting.ClockTime = clockTime % 24
	Lighting.GeographicLatitude = geographicLatitude 
end

return function(lightSource: string, placement: types.LightPlacement, state: types.ToolState, object: types.LightSourceObject?, distance: number)
    if lightSource == "object" then
        if object then
            local position = placement.position or state.mousePosition
            -- TODO: handle when it is not the front face
            local cframe = CFrame.lookAt(
                position + distance*placement.direction,
                position
            )

            if placement.angle then
                if (object.light:IsA("SpotLight") or object.light:IsA("SurfaceLight")) then
                    (object.light :: any).Angle = placement.angle
                elseif object.light:IsA("PointLight") then
                    object.light.Range = math.tan(math.rad(placement.angle/2)) * distance
                end
            end
            
            if object.container:IsA("BasePart") then
                object.container.CFrame = cframe
            elseif object.container:IsA("Attachment") then
                object.container.WorldCFrame = cframe
            end
        end
    elseif lightSource == "sun" then
        updateSkyFromDirection(placement.direction, -1)
    elseif lightSource == "moon" then
        updateSkyFromDirection(placement.direction, 1)
    end
end