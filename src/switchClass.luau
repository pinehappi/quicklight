local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReflectionService = game:GetService("ReflectionService")

local longClassNames = {
    point = "PointLight",
    spot = "SpotLight",
    surface = "SurfaceLight",
}

return function(light: Light, shortClassName: string): Light?
    local recording = ChangeHistoryService:TryBeginRecording("convert light")
    if not recording then return end
    
    local longClassName = longClassNames[shortClassName]
    local oldProperties = ReflectionService:GetPropertiesOfClass(light.ClassName, {
        ExcludeDisplay = true,
    })
    local newProperties = ReflectionService:GetPropertiesOfClass(longClassName, {
        ExcludeDisplay = true,
    })

    local sharedProperties: {[string]: boolean} = {}
    
    for _, property in oldProperties do
        if sharedProperties[property.Name] == nil then
            sharedProperties[property.Name] = false
        end
    end
    
    for _, property in newProperties do
        if sharedProperties[property.Name] == false then
            sharedProperties[property.Name] = true
        end
    end

    local newLight = Instance.new(longClassName) :: Light

    for name, isShared in sharedProperties do
        if not isShared then continue end
        pcall(function()
            (newLight :: any)[name] = (light :: any)[name]
        end)
    end

    -- convert class name
    if newLight.Name == light.ClassName then
        newLight.Name = longClassName
    end

    light.Parent = nil

    ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)

    return newLight
end