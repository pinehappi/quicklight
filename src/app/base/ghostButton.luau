local vide = require(script.Parent.Parent.Parent.Packages.vide)
local theme = require(script.Parent.Parent.theme)
local tween = require(script.Parent.Parent.tween)
local useButtonState = require(script.Parent.useButtonState)

export type Props = {
    text: string | (() -> string | nil) | nil,
    icon: unknown,
    padding: {
        left: UDim | () -> UDim,
        right: UDim | () -> UDim,
        top: UDim | () -> UDim,
        bottom: UDim | () -> UDim,
    }?,
    
    activated: (() -> ()) | nil,

    native: unknown,
}

return function(props: Props)
    local isHovering, isPressing, buttonStateProps = useButtonState()
    
    local backgroundTransparency = tween(function()
        if isPressing() then
            return theme.button.ghost.backgroundTransparency.press()
        elseif isHovering() then
            return theme.button.ghost.backgroundTransparency.hover()
        else
            return theme.button.ghost.backgroundTransparency.default()
        end
    end, theme.tween.base)

    return vide.create "TextButton" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = theme.button.ghost.background,
        BackgroundTransparency = backgroundTransparency,
        Text = "",

        props.icon,

        vide.show(function()
            return vide.read(props.text)
        end, function()
            return vide.create "TextLabel" {
                Text = props.text,
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                TextColor3 = theme.button.ghost.foreground,
                TextSize = theme.textSize.base,
                FontFace = theme.font.default,
            }
        end),
        
        vide.create "UIListLayout" {
            Padding = theme.padding.md,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        },
        
        vide.create "UICorner" {
            CornerRadius = theme.radius.base,
        },

        vide.create "UIPadding" {
            PaddingLeft = (props.padding and props.padding.left) or theme.padding.md,
            PaddingRight = (props.padding and props.padding.right) or theme.padding.md,
            PaddingTop = (props.padding and props.padding.top) or theme.padding.sm,
            PaddingBottom = (props.padding and props.padding.bottom) or theme.padding.sm,
        },

        Activated = props.activated,

        props.native,

        buttonStateProps,
    }
end
