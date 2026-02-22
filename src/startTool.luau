local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local result = require(script.Parent.result)
local tools = require(script.Parent.tools)
local types = require(script.Parent.types)
local updateLightSource = require(script.Parent.updateLightSource)

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

export type UpdateToolResult = {
    currentState: types.ToolState,
    placement: types.LightPlacement,
}

export type UpdateToolCallback = (distance: number) -> result.Result<UpdateToolResult, string>

-- returns a ToolActivity and a function to update it
return function(
    toolName: string,
    lightSourceName: string,
    lightSourceObject: types.LightSourceObject?
): (types.ToolState, types.ToolHandle, UpdateToolCallback)
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
                container.Transparency = 0
                container.Material = Enum.Material.Neon
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
    local handle = tool(initial, object)
    
    return initial, handle, function(distance: number)
        local current = getToolState(object and {object.container})
        local updateResult = handle.update(current, distance, lightSourceName)

        if updateResult.kind == "success" then
            local recording = ChangeHistoryService:TryBeginRecording(`{lightSourceName} {toolName}`)
            if not recording then return result.error("failed to record") end
            
            local success, err = pcall(function()
                updateLightSource(lightSourceName, updateResult.data, current, object, distance)
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
                placement = updateResult.data,
            })
        else
            return result.error(updateResult.error)
        end
    end
end
