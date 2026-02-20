local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local vide = require(script.Parent.Parent.Packages.vide)

type LightEntry = {
    light: Light,
    adornee: Instance,
    icon: Frame,
}

local function createIcon(light: Light): (Frame, TextButton)
    local icon = Instance.new("Frame")
    icon.BackgroundColor3 = light.Color
    icon.Size = UDim2.fromOffset(12, 12)
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

return function(on: () -> boolean)
    vide.effect(function()
        if not on() then return end

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "LightVisualizers"
        screenGui.DisplayOrder = -1
        screenGui.Parent = CoreGui

        local activeEntries: {[Light]: LightEntry} = {}
        local activeConnections: {[Light]: {RBXScriptConnection}} = {}
        local entryList: {LightEntry} = {}

        local function removeLight(light: Light)
            local entry = activeEntries[light]
            if entry then
                entry.icon:Destroy()
                activeEntries[light] = nil
                
                local index = table.find(entryList, entry)
                if index then
                    table.remove(entryList, index)
                end
            end
            
            local connections = activeConnections[light]
            if connections then
                for _, conn in connections do
                    conn:Disconnect()
                end
                activeConnections[light] = nil
            end
        end

        local function addLight(light: Light)
            if activeEntries[light] then return end
            
            local adornee = light.Parent
            if not adornee or (not adornee:IsA("BasePart") and not adornee:IsA("Attachment")) then
                return 
            end

            local icon, button = createIcon(light)
            icon.Parent = screenGui
            
            local entry: LightEntry = {
                light = light,
                adornee = adornee,
                icon = icon,
            }
            
            activeEntries[light] = entry
            table.insert(entryList, entry)

            local connections = table.create(3)
            
            table.insert(connections, light:GetPropertyChangedSignal("Color"):Connect(function()
                icon.BackgroundColor3 = light.Color
            end))
            
            table.insert(connections, light:GetPropertyChangedSignal("Parent"):Connect(function()
                local newParent = light.Parent
                if newParent and (newParent:IsA("BasePart") or newParent:IsA("Attachment")) then
                    entry.adornee = newParent
                else
                    removeLight(light)
                end
            end))

            table.insert(connections, button.Activated:Connect(function()
                Selection:Set({light})
            end))
            
            activeConnections[light] = connections
        end

        -- Initial Scan using QueryDescendants
        for _, light in workspace:QueryDescendants("Light") do
            addLight(light :: Light)
        end

        -- Dynamic Tracking
        local descendantAdded = workspace.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("Light") then
                addLight(descendant)
            end
        end)

        local descendantRemoving = workspace.DescendantRemoving:Connect(function(descendant)
            if descendant:IsA("Light") then
                removeLight(descendant)
            end
        end)

        -- Projection Loop
        local camera = workspace.CurrentCamera
        if camera then
            vide.cleanup(RunService.RenderStepped:Connect(function()
                for _, entry in entryList do
                    local worldPos: Vector3
                    if entry.adornee:IsA("BasePart") then
                        worldPos = entry.adornee.Position
                    elseif entry.adornee:IsA("Attachment") then
                        worldPos = entry.adornee.WorldPosition
                    else
                        entry.icon.Visible = false
                        continue
                    end
                    
                    local screenPos, onScreen = camera:WorldToViewportPoint(worldPos)
                    if onScreen then
                        entry.icon.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
                        entry.icon.Visible = true
                    else
                        entry.icon.Visible = false
                    end
                end
            end))
        end

        vide.cleanup(function()
            screenGui:Destroy()
            descendantAdded:Disconnect()
            descendantRemoving:Disconnect()
            for _, connections in activeConnections do
                for _, connection in connections do
                    connection:Disconnect()
                end
            end
        end)
    end)
end
