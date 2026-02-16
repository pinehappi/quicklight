local vide = require(script.Parent.Parent.Parent.Packages.vide)
local theme = require(script.Parent.Parent.theme)
local tween = require(script.Parent.Parent.tween)

export type Props = {
    text: string | (() -> string | nil) | nil,
    icon: (({ color: () -> Color3 }) -> any) | nil,
    isSelecting: boolean | (() -> boolean) | nil,
    
    activated: (() -> ()) | nil,

    native: unknown,
}

return function(props: Props)
    local isSelecting: () -> boolean = 
        if type(props.isSelecting) == "function" then props.isSelecting
        else function() return not not props.isSelecting end
    local isHovering = vide.source(false)
    local isPressing = vide.source(false)
    
    local backgroundColorTarget = function()
        if isSelecting() then
            return theme.button.background.select()
        elseif isPressing() then
            return theme.button.background.press()
        elseif isHovering() then
            return theme.button.background.hover()
        else
            return theme.button.background.default()
        end
    end
    local backgroundColor = tween(backgroundColorTarget, theme.tween.base)

    local foregroundColorTarget = function()
        if isSelecting() then
            return theme.button.foreground.select()
        elseif isPressing() then
            return theme.button.foreground.press()
        elseif isHovering() then
            return theme.button.foreground.hover()
        else
            return theme.button.foreground.default()
        end
    end
    local foregroundColor = tween(foregroundColorTarget, theme.tween.base)
    
    local strokeColorTarget = function()
        if isSelecting() then
            return theme.button.stroke.select()
        elseif isPressing() then
            return theme.button.stroke.press()
        elseif isHovering() then
            return theme.button.stroke.hover()
        else
            return theme.button.stroke.default()
        end
    end
    local strokeColor = tween(strokeColorTarget, theme.tween.base)
    
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
            PaddingLeft = theme.padding.md,
            PaddingRight = theme.padding.md,
            PaddingTop = theme.padding.sm,
            PaddingBottom = theme.padding.sm,
        },

        props.native,

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

        Activated = props.activated,
    }
end
