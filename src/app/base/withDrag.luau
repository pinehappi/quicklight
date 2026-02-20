local UserInputService = game:GetService("UserInputService")
local vide = require(script.Parent.Parent.Parent.Packages.vide)
return function(update: (percentX: number, percentY: number) -> (), handleDragBegan: (() -> ())?, handleDragEnded: (() -> ())?)
    local containerSize = Vector2.zero
    local containerPosition = Vector2.zero

    return {
        vide.changed("AbsoluteSize", function(size)
            containerSize = size
        end),

        vide.changed("AbsolutePosition", function(position)
            containerPosition = position
        end),

        InputBegan = function(input: InputObject)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local connection: RBXScriptConnection
                local dragConnection: RBXScriptConnection

                if handleDragBegan then
                    handleDragBegan()
                end

                local function updateDrag(x: number, y: number)
                    local deltaX = x - containerPosition.X
                    local deltaY = y - containerPosition.Y
                    local percentX = math.clamp(deltaX / containerSize.X, 0, 1)
                    local percentY = math.clamp(deltaY / containerPosition.Y, 0, 1)
                    update(percentX, percentY)
                end
                
                connection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
                    if input.UserInputState ~= Enum.UserInputState.Begin and input.UserInputState ~= Enum.UserInputState.Change then
                        connection:Disconnect()
                        dragConnection:Disconnect()
                        if handleDragEnded then
                            handleDragEnded()
                        end
                    end
                end)
                
                dragConnection = UserInputService.InputChanged:Connect(function(input, gpe)
                    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateDrag(input.Position.X, input.Position.Y)
                    end
                end)

                updateDrag(input.Position.X, input.Position.Y)
            end
        end,
    }
end
