local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local result = require(script.Parent.Parent.result)
local tools = require(script.Parent.Parent.tools)
local types = require(script.Parent.Parent.types)

local function getToolState(ignore: {any}?): types.ToolState
    local camera = workspace.CurrentCamera
    if not workspace.CurrentCamera then
        -- how?!?!
        return {
            sunDirection = Lighting:GetSunDirection(),
            moonDirection = Lighting:GetMoonDirection(),
            cameraPosition = Vector3.zero,
            cameraDirection = Vector3.zero,
            mousePosition = Vector3.zero,
            mouseDirection = Vector3.zero,
            normal = nil,
        }
    end
    
    local mouseLocation = UserInputService:GetMouseLocation()
    local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y, 1)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    if ignore then
        params.FilterDescendantsInstances = ignore
    end
    local result = workspace:Raycast(camera.CFrame.Position, ray.Direction * 10000, params)
	return {
		sunDirection = Lighting:GetSunDirection(),
		moonDirection = Lighting:GetMoonDirection(),
		cameraPosition = workspace.CurrentCamera.CFrame.Position,
		cameraDirection = workspace.CurrentCamera.CFrame.LookVector,
		mousePosition = result and result.Position or camera.CFrame.Position + ray.Direction * 10000,
		mouseDirection = ray.Direction,
        mouseNormal = result and result.Normal,
	}
end

local function updateSkyFromDirection(direction: Vector3, longitudeFactor: number)
    local latitude = math.atan2(direction.Z, math.sqrt(direction.X^2 + direction.Y^2))
	local longitude = math.atan2(direction.Y * longitudeFactor, direction.X * longitudeFactor)

	local geographicLatitude = (latitude / math.pi / 2) * 360 + 23.5
	local clockTime = (longitude / math.pi / 2) * 24 - 6

	Lighting.ClockTime = clockTime % 24
	Lighting.GeographicLatitude = geographicLatitude 
end

local function updateLightSource(name: string, lightInfo: types.LightInfo, state: types.ToolState, object: types.LightSourceObject?)
    if name == "object" then
        if object then
            local distance = 5
            local position = lightInfo.position or state.mousePosition
            -- TODO: handle when it is not the front face
            local cframe = CFrame.lookAt(
                position + distance*lightInfo.direction,
                position
            )

            if lightInfo.angle then
                if (object.light:IsA("SpotLight") or object.light:IsA("SurfaceLight")) then
                    (object.light :: any).Angle = lightInfo.angle
                elseif object.light:IsA("PointLight") then
                    object.light.Range = math.tan(math.rad(lightInfo.angle/2)) * distance
                end
            end
            
            if object.container:IsA("BasePart") then
                object.container.CFrame = cframe
            elseif object.container:IsA("Attachment") then
                object.container.WorldCFrame = cframe
            end
        end
    elseif name == "sun" then
        updateSkyFromDirection(lightInfo.direction, -1)
    elseif name == "moon" then
        updateSkyFromDirection(lightInfo.direction, 1)
    end
end

export type UpdateToolResult = {
    currentState: types.ToolState,
    lightInfo: types.LightInfo,
    gizmoExtra: unknown,
}

export type UpdateToolCallback = () -> result.Result<UpdateToolResult, string>

-- returns a ToolActivity and a function to update it
return function(
    toolName: string,
    lightSourceName: string,
    lightSourceObject: types.LightSourceObject?
): (types.ToolState, UpdateToolCallback)
    local tool = tools[toolName]
    local shouldAppend = false
    local object: types.LightSourceObject
    if lightSourceName == "object" then
        if lightSourceObject then
            object = lightSourceObject
        else
            local recording = ChangeHistoryService:TryBeginRecording("create light")
            -- TODO: handle this error better instead of silently
            if recording then
                local container = Instance.new("Part")
                container.Size = Vector3.new(1, 1, 1)
                container.Transparency = 0.5
                container.Color = Color3.new(1, 1, 1)
                container.TopSurface = Enum.SurfaceType.Smooth
                container.BottomSurface = Enum.SurfaceType.Smooth
                container.Anchored = true
                container.CanCollide = false
                container.Name = "LightPart"
                container.Parent = workspace

                local light = Instance.new("SpotLight")
                light.Color = Color3.new(1, 1, 1)
                light.Brightness = 1
                light.Parent = container
                
                object = {
                    light = light,
                    container = container,
                }

                ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
                shouldAppend = true
            end
        end
    end
    
    local initial = getToolState(object and {object.container})
    local update = tool.run(initial, object)
    
    return initial, function()
        local current = getToolState(object and {object.container})
        local updateResult = update(current)

        if updateResult.kind == "success" then
            local recording = ChangeHistoryService:TryBeginRecording(`{lightSourceName} {toolName}`)
            if not recording then return result.error("failed to record") end
            
            local success, err = pcall(function()
                updateLightSource(lightSourceName, updateResult.data.lightInfo, current, object)
            end)
                
            if success then
                if shouldAppend then
                    ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Append)
                else
                    shouldAppend = true
                    ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
                end
            else
                warn("Light placement failed: " .. err)
                ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel)
            end

            return result.ok({
                currentState = current,
                lightInfo = updateResult.data.lightInfo,
                gizmoExtra = updateResult.data.gizmoExtra,
            })
        else
            return result.error(updateResult.error)
        end
    end
end
