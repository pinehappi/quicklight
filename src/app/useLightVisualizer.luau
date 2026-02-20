local CoreGui = game:GetService("CoreGui")
local Selection = game:GetService("Selection")
local vide = require(script.Parent.Parent.Packages.vide)

local CIRCLE_ASSET = "rbxassetid://5552526748"

local function createdBillboard(light: Light): (BillboardGui, ImageLabel, TextLabel)
    local billboard = Instance.new("BillboardGui")
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromScale(2, 2)
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.MaxDistance = 1000
    billboard.Name = "LightVisualizer"
    
    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.fromScale(1, 1)
    container.Parent = billboard

    local icon = Instance.new("ImageLabel")
    icon.BackgroundTransparency = 1
    icon.Image = CIRCLE_ASSET
    icon.ImageColor3 = light.Color
    icon.Size = UDim2.fromScale(1, 1)
    icon.Parent = container
    
    -- Fallback/Stroke for visibility
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    stroke.Parent = icon
    
    local button = Instance.new("TextButton")
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Size = UDim2.fromScale(1, 1)
    button.Parent = container
    
    local brightnessLabel = Instance.new("TextLabel")
    brightnessLabel.BackgroundTransparency = 1
    brightnessLabel.TextColor3 = Color3.new(1, 1, 1)
    brightnessLabel.TextStrokeTransparency = 0
    brightnessLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    brightnessLabel.TextSize = 10
    brightnessLabel.Font = Enum.Font.BuilderSans
    brightnessLabel.Text = string.format("%.1f", light.Brightness)
    brightnessLabel.Position = UDim2.fromScale(0, 1)
    brightnessLabel.Size = UDim2.fromScale(1, 0.5)
    brightnessLabel.Parent = container

    button.Activated:Connect(function()
        Selection:Set({light})
    end)

    return billboard, icon, brightnessLabel
end

return function(on: () -> boolean)
    vide.effect(function()
        if not on() then return end

        local folder = Instance.new("Folder")
        folder.Parent = CoreGui
        folder.Name = "LightBillboards"

        local activeBillboards: {[Light]: BillboardGui} = {}
        local activeConnections: {[Light]: {RBXScriptConnection}} = {}

        local function removeLight(light: Light)
            local billboard = activeBillboards[light]
            if billboard then
                billboard:Destroy()
                activeBillboards[light] = nil
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
            if activeBillboards[light] then return end
            
            local adornee = light.Parent
            if not adornee or (not adornee:IsA("BasePart") and not adornee:IsA("Attachment")) then
                return 
            end

            local billboard, icon, brightnessLabel = createdBillboard(light)
            billboard.Adornee = adornee
            billboard.Parent = folder
            
            activeBillboards[light] = billboard

            local connections = table.create(3)
            
            table.insert(connections, light:GetPropertyChangedSignal("Color"):Connect(function()
                icon.ImageColor3 = light.Color
            end))

            table.insert(connections, light:GetPropertyChangedSignal("Brightness"):Connect(function()
                brightnessLabel.Text = string.format("%.1f", light.Brightness)
            end))
            
            table.insert(connections, light:GetPropertyChangedSignal("Parent"):Connect(function()
                local newParent = light.Parent
                if newParent and (newParent:IsA("BasePart") or newParent:IsA("Attachment")) then
                    billboard.Adornee = newParent
                else
                    removeLight(light)
                end
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

        vide.cleanup(function()
            folder:Destroy()
            descendantAdded:Disconnect()
            descendantRemoving:Disconnect()
            for light, _ in activeBillboards do
                removeLight(light)
            end
        end)
    end)
end
