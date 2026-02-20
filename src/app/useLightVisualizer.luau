local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local types = require("../types")
local vide = require(script.Parent.Parent.Packages.vide)

local SIZE = 60
local SELECTED_ATTRIBUTE = "selected"

local DRAGGER_ICON = "rbxassetid://6710235139"

local icons = {
    PointLight = {
        base = "rbxassetid://103397983899667",
        stroke = "rbxassetid://122499091104026",
    },
    SpotLight = {
        base = "rbxassetid://136480611134115",
        stroke = "rbxassetid://132148522699281",
    },
    SurfaceLight = {
        base = "rbxassetid://82988569343018",
        stroke = "rbxassetid://132048990155932",
    },
}

type LightEntry = {
    light: Light,
    basePart: BasePart?,
    attachment: Attachment?,
    icon: any,
    connections: {RBXScriptConnection},
}

local function updateButtonState(button: any)
    if button:GetAttribute(SELECTED_ATTRIBUTE) then
        button.Stroke.ImageTransparency = 0.3
        button.Drag.Visible = true
    elseif button.GuiState == Enum.GuiState.Hover or button.GuiState == Enum.GuiState.Press then
        button.Stroke.ImageTransparency = 0.8
        button.Drag.Visible = true
    else
        button.Stroke.ImageTransparency = 1
        button.Drag.Visible = false
    end
end

local function createIcon(light: Light, dragClicked: () -> ()): (any, any)
    local icon = Instance.new("Frame")
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.fromOffset(0, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Name = "LightVisualizerIcon"
    icon.Visible = false
    
    local button = Instance.new("ImageButton")
    button.Name = "Button"
    button.BackgroundTransparency = 1
    button.ImageTransparency = 0.2
    button.Image = icons[light.ClassName].base
    button.ImageColor3 = light.Color
    button.Size = UDim2.fromScale(1, 1)
    button.Parent = icon

    local stroke = Instance.new("ImageLabel")
    stroke.Name = "Stroke"
    stroke.BackgroundTransparency = 1
    stroke.ImageTransparency = 1
    stroke.Image = icons[light.ClassName].stroke
    stroke.ImageColor3 = light.Color
    stroke.Size = UDim2.fromScale(1, 1)
    stroke.Parent = button

    local dragButton = Instance.new("ImageButton")
    dragButton.BackgroundTransparency = 1
    dragButton.Size = UDim2.fromScale(0.3, 0.3)
    dragButton.Position = UDim2.fromScale(1, 0)
    dragButton.AnchorPoint = Vector2.new(1, 0)
    dragButton.Image = DRAGGER_ICON
    dragButton.Visible = false
    dragButton.Name = "Drag"
    dragButton.Parent = button
    
    button:GetPropertyChangedSignal("GuiState"):Connect(function()
        updateButtonState(button)
    end)

    dragButton.Activated:Connect(dragClicked)
    
    return icon, button
end

local function updateSelecting(entry: LightEntry, isSelecting: boolean)
    if isSelecting then
        entry.icon.Button:SetAttribute(SELECTED_ATTRIBUTE, true)
        updateButtonState(entry.icon.Button)
    else
        entry.icon.Button:SetAttribute(SELECTED_ATTRIBUTE, nil)
        updateButtonState(entry.icon.Button)
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

    local scale = math.clamp(50 / screenPos.Z, 0.2, 1)
    entry.icon.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
    entry.icon.Size = UDim2.fromOffset(SIZE * scale, SIZE * scale)
    entry.icon.Visible = onScreen and 0 < screenPos.Z and screenPos.Z <= 1000
end

export type LightVisualizerOptions = {
    plugin: Plugin,
    active: () -> boolean,
    lightSourceObject: () -> types.LightSourceObject?,
}

return function(options: LightVisualizerOptions)
    local plugin = options.plugin
    local activeEntries: {[Light]: LightEntry} = {}
    local entryList: {LightEntry} = {}

    vide.effect(function()
        if not options.active() then return end

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
            
            local icon, button = createIcon(light, function()
                local entry = activeEntries[light]
                if entry then
                    if entry.attachment or entry.basePart then
                        Selection:Set({entry.attachment or entry.basePart})
                        plugin:SelectRibbonTool(Enum.RibbonTool.Move, UDim2.fromOffset(0, 0))
                    end
                end
            end)

            icon.Parent = screenGui
            
            local connections = table.create(2)
            local entry: LightEntry = {
                light = light,
                icon = icon,
                connections = connections,
            }

            activeEntries[light] = entry
            table.insert(entryList, entry)

            table.insert(connections, light:GetPropertyChangedSignal("Color"):Connect(function()
                button.ImageColor3 = light.Color
                button.Stroke.ImageColor3 = light.Color
            end))
            
            table.insert(connections, light:GetPropertyChangedSignal("Parent"):Connect(function()
                updateAdornee(entry)
            end))
            updateAdornee(entry)

            button.Activated:Connect(function()
                local current = Selection:Get()
                if #current == 1 and current[1] == light then
                    Selection:Set({})
                else
                    Selection:Set({light})
                end
            end)
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
        if not options.active() then return end
        
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
