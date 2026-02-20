local vide = require(script.Parent.Parent.Parent.Packages.vide)
local theme = require(script.Parent.Parent.theme)
local tween = require(script.Parent.Parent.tween)
local icon = require(script.Parent.icon)
local useButtonState = require(script.Parent.useButtonState)

export type Props = {
    checked: () -> boolean,
    checkedChanged: (boolean) -> ()
}

return function(props: Props)
    local isHovering, isPressing, buttonStateProps = useButtonState()

    local backgroundColor = tween(function()
        if props.checked() then
            return theme.accent.main()
        elseif isPressing() then
            return theme.input.background.press()
        elseif isHovering() then
            return theme.input.background.hover()
        else
            return theme.input.background.default()
        end
    end, theme.tween.base)

    local foregroundColor = tween(function()
        if props.checked() then
            return theme.accent.foreground()
        elseif isPressing() then
            return theme.input.foreground.press()
        elseif isHovering() then
            return theme.input.foreground.hover()
        else
            return theme.input.foreground.default()
        end
    end, theme.tween.base)
    
    local strokeColor = tween(function()
        if props.checked() then
            return theme.accent.main()
        elseif isPressing() then
            return theme.input.stroke.press()
        elseif isHovering() then
            return theme.input.stroke.hover()
        else
            return theme.input.stroke.default()
        end
    end, theme.tween.base)

    return vide.create "TextButton" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = backgroundColor,
        TextTransparency = 1,

        vide.create "UIStroke" {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = strokeColor,
            Thickness = theme.strokeThickness,
        },

        vide.create "UIPadding" {
            PaddingLeft = theme.padding.xs,
            PaddingRight = theme.padding.xs,
            PaddingTop = theme.padding.xs,
            PaddingBottom = theme.padding.xs,
        },

        vide.create "UICorner" {
            CornerRadius = theme.radius.base,
        },

        icon {
            image = function()
                if props.checked() then
                    return "rbxassetid://17650916717"
                else
                    return ""
                end
            end,
            color = foregroundColor,
            size = theme.textSize.base,
        },

        Activated = function()
            props.checkedChanged(not props.checked())
        end,

        buttonStateProps,
    }
end
