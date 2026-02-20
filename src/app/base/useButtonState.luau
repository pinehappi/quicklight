local vide = require(script.Parent.Parent.Parent.Packages.vide)

--- returns the (isHovering, isPressing, buttonStateProps). You should put buttonStateProps
--- into whatever object you want the buttonState for.
return function(): (() -> boolean, () -> boolean, unknown)
    local isHovering = vide.source(false)
    local isPressing = vide.source(false)

    return isHovering, isPressing, {
        InputBegan = function(input: InputObject)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                isHovering(true)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                isPressing(true)

                local connection: RBXScriptConnection
                connection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
                    if input.UserInputState ~= Enum.UserInputState.Begin and input.UserInputState ~= Enum.UserInputState.Change then
                        connection:Disconnect()
                        isPressing(false)
                    end
                end)
            end
        end,

        InputEnded = function(input: InputObject)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                isHovering(false)
            end
        end,
    }
end
