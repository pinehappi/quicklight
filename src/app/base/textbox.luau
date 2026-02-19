local vide = require(script.Parent.Parent.Parent.Packages.vide)
local theme = require(script.Parent.Parent.theme)
local tween = require(script.Parent.Parent.tween)

export type Props = {
    text: () -> (string),
    textChanged: (string) -> (),
    padding: {
        left: UDim | () -> UDim,
        right: UDim | () -> UDim,
        top: UDim | () -> UDim,
        bottom: UDim | () -> UDim,
    }?,

    native: unknown,
}

return function(props: Props)
    local isSelecting = vide.source(false)
    local isHovering = vide.source(false)
    local isPressing = vide.source(false)
    
    local backgroundColor = tween(function()
        if isSelecting() then
            return theme.input.background.select()
        elseif isPressing() then
            return theme.input.background.press()
        elseif isHovering() then
            return theme.input.background.hover()
        else
            return theme.input.background.default()
        end
    end, theme.tween.base)

    local foregroundColor = tween(function()
        if isSelecting() then
            return theme.input.foreground.select()
        elseif isPressing() then
            return theme.input.foreground.press()
        elseif isHovering() then
            return theme.input.foreground.hover()
        else
            return theme.input.foreground.default()
        end
    end, theme.tween.base)
    
    local strokeColor = tween(function()
        if isSelecting() then
            return theme.input.stroke.select()
        elseif isPressing() then
            return theme.input.stroke.press()
        elseif isHovering() then
            return theme.input.stroke.hover()
        else
            return theme.input.stroke.default()
        end
    end, theme.tween.base)
    
    return vide.create "TextBox" {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = backgroundColor,
        Text = props.text,
        TextSize = theme.textSize.base,
        TextColor3 = foregroundColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClipsDescendants = true,
        
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

        Focused = function()
            isSelecting(true)
        end,

        FocusLost = function()
            isSelecting(false)
        end,

        vide.changed("Text", function(text)
            props.textChanged(text)
        end),
    }
end
