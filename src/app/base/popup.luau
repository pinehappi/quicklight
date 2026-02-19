local vide = require(script.Parent.Parent.Parent.Packages.vide)
local layerContext = require(script.Parent.Parent.layerContext)

export type Props = {
    closed: () -> (),
    size: (Vector2) -> UDim2,
    position: (pos: Vector2, size: Vector2) -> UDim2,
    children: any,
    native: any,
}

return function(props: Props)
    local size = vide.source(Vector2.new(0, 0))
    local position = vide.source(Vector2.new(0, 0))
    
    
    local container = Instance.new("Frame")
    container.InputEnded:Connect(function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            props.closed()
        end
    end)
    container.BackgroundTransparency = 1
    container.Size = UDim2.fromScale(1, 1)
    container.ZIndex = 100
    container.Parent = layerContext()

    -- this is to block viewport interactions
    local container2 = Instance.new("TextButton")
    container2.BackgroundTransparency = 1
    container2.TextTransparency = 1
    container2.Size = UDim2.fromScale(1, 1)
    container2.ZIndex = -1
    container2.Parent = container.Parent

    -- text button to block input on the other container
    local mainContainer = Instance.new("TextButton")
    mainContainer.BackgroundTransparency = 1
    mainContainer.TextTransparency = 1
    mainContainer.Active = true
    mainContainer.Parent = container

    -- spy object so we can get the parent's position and move the popup based on it
    local spy = Instance.new("Frame")
    spy.Size = UDim2.fromOffset(0, 0)
    spy.BackgroundTransparency = 1

    local sizeConnection: RBXScriptConnection?
    local positionConnection: RBXScriptConnection?

    local function cleanupConnections()
        if sizeConnection then
            sizeConnection:Disconnect()
            sizeConnection = nil
        end
        if positionConnection then
            positionConnection:Disconnect()
            positionConnection = nil
        end
    end
    
    spy:GetPropertyChangedSignal("Parent"):Connect(function()
        cleanupConnections()

        local parent = spy.Parent :: GuiObject?
        if parent then
            sizeConnection = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                size(parent.AbsoluteSize)
            end)
            
            positionConnection = parent:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
                position(parent.AbsolutePosition)
            end)

            size(parent.AbsoluteSize)
            position(parent.AbsolutePosition)
        end
    end)

    vide.apply(mainContainer) {
        BackgroundTransparency = 1,
        Size = function()
            return props.size(size())
        end,
        Position = function()
            return props.position(position(), size())
        end,
        props.native,
        props.children,
    }

    vide.cleanup(function()
        container:Destroy()
        container2:Destroy()
        spy:Destroy()
    end)

    return spy
end
