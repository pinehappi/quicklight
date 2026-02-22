local UserInputService = game:GetService("UserInputService")
local vide = require(script.Parent.Parent.Packages.vide)
local layerContext = require(script.Parent.layerContext)
local theme = require(script.Parent.theme)

export type Props = {
    text: string | () -> string,
}

return function(props: Props)
    local layer = layerContext()

    local mousePosition = vide.source(UserInputService:GetMouseLocation())

    local tooltip = vide.create "TextLabel" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = theme.surface0.background,
        TextColor3 = theme.surface0.foreground,
        Text = props.text,
        TextSize = theme.textSize.base,
        Position = function()
            return UDim2.fromOffset(mousePosition().X + 5, mousePosition().Y + 5)
        end,

        vide.create "UIStroke" {
            Color = theme.surface0.stroke,
        },
        
        vide.create "UICorner" {
            CornerRadius = theme.radius.full,
        },

        vide.create "UIPadding" {
            PaddingLeft = theme.padding.md,
            PaddingRight = theme.padding.md,
            PaddingTop = theme.padding.md,
            PaddingBottom = theme.padding.md,
        },
    }

    tooltip.Parent = layer

    vide.cleanup(UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            mousePosition(UserInputService:GetMouseLocation())
        end
    end))

    vide.cleanup(tooltip)

    return nil
end
