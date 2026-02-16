local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local result = require(script.Parent.Parent.result)
local tools = require(script.Parent.Parent.tools)
local types = require(script.Parent.Parent.types)

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

local function updateSkyFromDirection(direction: Vector3, longitudeFactor: number)
    local latitude = math.atan2(direction.Z, math.sqrt(direction.X^2 + direction.Y^2))
	local longitude = math.atan2(direction.Y * longitudeFactor, direction.X * longitudeFactor)

	local geographicLatitude = (latitude / math.pi / 2) * 360 + 23.5
	local clockTime = (longitude / math.pi / 2) * 24 - 6

	Lighting.ClockTime = clockTime % 24
	Lighting.GeographicLatitude = geographicLatitude 
end

local function updateLightSource(name: string, direction: Vector3, state: types.ToolState, object: types.LightSourceObject?)
    if name == "object" then
        if object then
            local distance = 5
            local cframe = CFrame.lookAt(
                state.mousePosition + distance*direction,
                state.mousePosition
            )
            
            if object.container:IsA("BasePart") then
                object.container.CFrame = cframe
            elseif object.container:IsA("Attachment") then
                object.container.WorldCFrame = cframe
            end
        end
    elseif name == "sun" then
        updateSkyFromDirection(direction, -1)
    elseif name == "moon" then
        updateSkyFromDirection(direction, 1)
    end
end

export type UpdateToolResult = {
    currentState: types.ToolState,
    direction: Vector3,
}

export type UpdateToolCallback = (commit: boolean) -> result.Result<UpdateToolResult, string>

-- returns a ToolActivity and a function to update it
return function(
    toolName: string,
    lightSourceName: string,
    lightSourceObject: types.LightSourceObject?
): (types.ToolState, UpdateToolCallback)
    local tool = tools[toolName]
    local initial = getToolState()
    local object = lightSourceName == "object" and lightSourceObject or nil
    
    return initial, function(commit: boolean)
        local current = getToolState()
        local updateResult = tool.update(initial, current, object)

        if updateResult.kind == "success" then
            local recording = commit and ChangeHistoryService:TryBeginRecording(`{lightSourceName} {toolName}`)
            if commit and not recording then return result.error("failed to record") end
            
            local success, err = pcall(function()
                updateLightSource(lightSourceName, updateResult.data.direction, current, object)
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

            return result.ok({
                currentState = current,
                direction = updateResult.data.direction,
            })
        else
            return result.error(updateResult.error)
        end
    end
end
