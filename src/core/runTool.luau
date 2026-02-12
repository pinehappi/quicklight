local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local vide = require(script.Parent.Parent.Packages.vide)
local tools = require(script.Parent.Parent.tools)
local types = require(script.Parent.Parent.types)
local updateSkyFromDirection = require(script.Parent.Parent.utils.updateSkyFromDirection)

local function getToolState(): types.ToolState
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
    local result = workspace:Raycast(camera.CFrame.Position, ray.Direction * 10000)
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

local function updateLightSource(name: string, direction: Vector3)
    if name == "sun" then
        updateSkyFromDirection(direction, -1)
    else
        updateSkyFromDirection(direction, 1)
    end
end

-- returns a ToolActivity and a function to update it
return function(toolName: string, lightSourceName: string): (types.ToolActivity, (commit: boolean) -> ())
    local toolState = getToolState()
    local tool = tools[toolName]
    local activity: types.ToolActivity = {
        tool = toolName,
        lightSource = lightSourceName,
        initial = toolState,
        current = vide.source(toolState),
        direction = vide.source(Vector3.new(0, 0, 0)),
    }
    
    return activity, function(commit: boolean)
        local currentPlaceState = getToolState()
        local result = tool.update({} :: any, activity.initial, currentPlaceState)
        activity.current(currentPlaceState)

        if result.kind == "success" then
            local recording = commit and ChangeHistoryService:TryBeginRecording(`{lightSourceName} {toolName}`)
            if commit and not recording then return end

            activity.direction(result.data.direction)
            
            local success, err = pcall(function()
                updateLightSource(lightSourceName, result.data.direction)
            end)
                
            if success then
                if recording then
                    ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
                end
            else
                warn("Light placement failed: " .. err)
                if recording then
                    ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel)
                end
            end
        end
    end
end
