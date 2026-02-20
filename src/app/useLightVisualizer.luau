local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local types = require("../types")
local vide = require(script.Parent.Parent.Packages.vide)

local SIZE = 30

type LightEntry = {
    light: Light,
    basePart: BasePart?,
    attachment: Attachment?,
    icon: any,
    connections: {RBXScriptConnection},
}

local function createIcon(light: Light): (Frame, TextButton)
    local icon = Instance.new("Frame")
    icon.BackgroundColor3 = light.Color
    icon.Size = UDim2.fromOffset(0, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Name = "LightVisualizerIcon"
    icon.Visible = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = icon
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    stroke.Parent = icon
    
    local button = Instance.new("TextButton")
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Size = UDim2.fromScale(1, 1)
    button.Parent = icon
    
    return icon, button
end

local function updateSelecting(entry: LightEntry, isSelecting: boolean)
    if isSelecting then
        entry.icon.UIStroke.Color = Color3.new(0, 0, 1)
    else
        entry.icon.UIStroke.Color = Color3.new(0, 0, 0)
    end
end

local function updateAdornee(entry: LightEntry)
    local parent = entry.light.Parent
    if parent and parent:IsA("BasePart") then
        entry.basePart = parent
        entry.attachment = nil
    elseif parent and parent:IsA("Attachment") then
        entry.basePart = nil
        entry.attachment = parent
    else
        entry.basePart = nil
        entry.attachment = nil
    end
end

local function updatePosition(camera: Camera, entry: LightEntry)
    local worldPos: Vector3
    if entry.basePart then
        worldPos = entry.basePart.Position
    elseif entry.attachment then
        worldPos = entry.attachment.WorldPosition
    else
        entry.icon.Visible = false
        return
    end
    
    local screenPos, onScreen = camera:WorldToViewportPoint(worldPos)
    if onScreen and 0 < screenPos.Z and screenPos.Z <= 1000 then
        entry.icon.Visible = true
        local scale = math.clamp(50 / screenPos.Z, 0.2, 1)
        entry.icon.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
        entry.icon.Size = UDim2.fromOffset(SIZE * scale, SIZE * scale)
    else
        entry.icon.Visible = false
    end
end

export type LightVisualizerOptions = {
    on: () -> boolean,
    lightSourceObject: () -> types.LightSourceObject?,
}

return function(options: LightVisualizerOptions)
    local activeEntries: {[Light]: LightEntry} = {}
    local entryList: {LightEntry} = {}

    vide.effect(function()
        if not options.on() then return end

        local camera = workspace.CurrentCamera

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "LightVisualizers"
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.DisplayOrder = -1
        screenGui.Parent = CoreGui

        local function removeLight(light: Light)
            local entry = activeEntries[light]
            if entry then
                entry.icon:Destroy()
                activeEntries[light] = nil
                
                local index = table.find(entryList, entry)
                if index then
                    table.remove(entryList, index)
                end

                for _, connection in entry.connections do
                    connection:Disconnect()
                end
            end
        end

        local function addLight(light: Light)
            if activeEntries[light] then return end
            
            local icon, button = createIcon(light)
            icon.Parent = screenGui
            
            local connections = table.create(3)
            local entry: LightEntry = {
                light = light,
                icon = icon,
                connections = connections,
            }

            activeEntries[light] = entry
            table.insert(entryList, entry)

            table.insert(connections, light:GetPropertyChangedSignal("Color"):Connect(function()
                icon.BackgroundColor3 = light.Color
            end))
            
            table.insert(connections, light:GetPropertyChangedSignal("Parent"):Connect(function()
                local newParent = light.Parent
                if newParent and (newParent:IsA("BasePart") or newParent:IsA("Attachment")) then
                    updateAdornee(entry)
                else
                    removeLight(light)
                end
            end))
            updateAdornee(entry)

            table.insert(connections, button.Activated:Connect(function()
                local current = Selection:Get()
                if #current == 1 and current[1] == light then
                    Selection:Set({})
                else
                    Selection:Set({light})
                end
            end))
        end

        -- Initial Scan using QueryDescendants
        for _, light in workspace:QueryDescendants("Light") do
            addLight(light :: Light)
        end

        -- Dynamic Tracking
        vide.cleanup(workspace.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("Light") then
                addLight(descendant)
            end
        end))

        vide.cleanup(workspace.DescendantRemoving:Connect(function(descendant)
            if descendant:IsA("Light") then
                removeLight(descendant)
            end
        end))

        -- Projection Loop
        if camera then
            vide.cleanup(RunService.PreRender:Connect(function()
                for _, entry in entryList do
                    updatePosition(camera, entry)
                end
            end))
        end

        vide.cleanup(function()
            screenGui:Destroy()
            for _, entries in activeEntries do
                for _, connection in entries.connections do
                    connection:Disconnect()
                end
            end
            
            activeEntries = {}
            entryList = {}
        end)
    end)

    local previousLight: Light? = nil
    vide.effect(function()
        local object = options.lightSourceObject()
        local currentLight = object and object.light or nil
        if currentLight ~= previousLight then
            if previousLight then
                local entry = activeEntries[previousLight]
                if entry then
                    updateSelecting(entry, false)
                end
            end

            if currentLight then
                local entry = activeEntries[currentLight]
                if entry then
                    updateSelecting(entry, true)
                end
            end
        end

        previousLight = currentLight
    end)
end
