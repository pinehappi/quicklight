local UserInputService = game:GetService("UserInputService")
local vide = require(script.Parent.Parent.Parent.Packages.vide)
local theme = require(script.Parent.Parent.theme)

export type Props = {
    value: () -> number,
    valueChanged: (number) -> (),
    min: number | (() -> number),
    max: number | (() -> number),

    native: any,
}

return function(props: Props)
    local percent = function()
        return (props.value() - vide.read(props.min)) / (vide.read(props.max) :: number - vide.read(props.min))
    end

    local button = vide.create "TextButton" {
        BackgroundTransparency = 1,
        Text = "",
        
        vide.create "Frame" {
            Name = "Bar",
            BackgroundColor3 = theme.input.background.default,
            Size = UDim2.new(1, 0, 0, 6),

            --[[vide.create "UIStroke" {
                Color = theme.input.background.default,
                Thickness = theme.strokeThickness,
            },]]

            vide.create "UICorner" {
                CornerRadius = theme.radius.full,
            },

            vide.create "Frame" {
                Name = "Fill",
                Size = function()
                    return UDim2.fromScale(percent(), 1)
                end,
                BackgroundColor3 = theme.accent.main,

                vide.create "UICorner" {
                    CornerRadius = theme.radius.full,
                },
            },

            vide.create "Frame" {
                Name = "Circle",
                Size = UDim2.fromOffset(10, 10),
                BackgroundColor3 = theme.accent.main,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = function()
                    return UDim2.fromScale(percent(), 0.5)
                end,

                vide.create "UICorner" {
                    CornerRadius = theme.radius.full,
                },
            }
        },
        
        props.native,
    }

    vide.cleanup(button.InputBegan:Connect(function(input: InputObject)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local connection: RBXScriptConnection
            local dragConnection: RBXScriptConnection

            local function updateDrag(x: number)
                local delta = x - button.AbsolutePosition.X
                local percent = math.clamp(delta / button.AbsoluteSize.X, 0, 1)
                props.valueChanged(percent*vide.read(props.max) + (1 - percent)*vide.read(props.min))
            end
            
            connection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
                if input.UserInputState ~= Enum.UserInputState.Begin and input.UserInputState ~= Enum.UserInputState.Change then
                    connection:Disconnect()
                    dragConnection:Disconnect()
                end
            end)
            
            dragConnection = UserInputService.InputChanged:Connect(function(input, gpe)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateDrag(input.Position.X)
                end
            end)

            updateDrag(input.Position.X)
        end
    end))

    return button
end
