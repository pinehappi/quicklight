local vide = require(script.Parent.Parent.Parent.Packages.vide)
local theme = require(script.Parent.Parent.theme)
local tween = require(script.Parent.Parent.tween)
local useButtonState = require(script.Parent.useButtonState)

export type Props = {
    text: string | (() -> string | nil) | nil,
    icon: (({ color: () -> Color3 }) -> any) | nil,
    isSelecting: boolean | (() -> boolean) | nil,
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
    local isSelecting: () -> boolean = 
        if type(props.isSelecting) == "function" then props.isSelecting
        else function() return not not props.isSelecting end
    local isHovering, isPressing, buttonStateProps = useButtonState()
    
    local backgroundColor = tween(function()
        if isSelecting() then
            return theme.button.background.select()
        elseif isPressing() then
            return theme.button.background.press()
        elseif isHovering() then
            return theme.button.background.hover()
        else
            return theme.button.background.default()
        end
    end, theme.tween.base)

    local foregroundColor = tween(function()
        if isSelecting() then
            return theme.button.foreground.select()
        elseif isPressing() then
            return theme.button.foreground.press()
        elseif isHovering() then
            return theme.button.foreground.hover()
        else
            return theme.button.foreground.default()
        end
    end, theme.tween.base)
    
    local strokeColor = tween(function()
        if isSelecting() then
            return theme.button.stroke.select()
        elseif isPressing() then
            return theme.button.stroke.press()
        elseif isHovering() then
            return theme.button.stroke.hover()
        else
            return theme.button.stroke.default()
        end
    end, theme.tween.base)
    
    return vide.create "TextButton" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = backgroundColor,
        Text = "",

        props.icon and props.icon {
            color = foregroundColor,
        },

        vide.show(function()
            return vide.read(props.text)
        end, function()
            return vide.create "TextLabel" {
                Text = props.text,
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                TextColor3 = foregroundColor,
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
        
        vide.create "UIStroke" {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = strokeColor,
            Thickness = theme.strokeThickness,
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
