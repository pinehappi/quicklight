local vide = require(script.Parent.Parent.Parent.Packages.vide)
local theme = require(script.Parent.Parent.theme)
local tween = require(script.Parent.Parent.tween)
local useButtonState = require(script.Parent.useButtonState)

export type OptionProps = {
    value: string,
    text: string | (() -> string | nil) | nil,
    icon: (({ color: () -> Color3 }) -> any) | nil,
    isSelecting: boolean | (() -> boolean) | nil,
    
    activated: (() -> ()) | nil,

    isStart: boolean?,
    isEnd: boolean?,
}

local function optionButton(props: OptionProps)
    local isSelecting: () -> boolean = 
        if type(props.isSelecting) == "function" then props.isSelecting
        else function() return not not props.isSelecting end
    local isHovering, isPressing, buttonStateProps = useButtonState()
    
    local backgroundColor = tween(function()
        if isSelecting() then
            return theme.button.secondary.background.select()
        elseif isPressing() then
            return theme.button.secondary.background.press()
        elseif isHovering() then
            return theme.button.secondary.background.hover()
        else
            return theme.button.secondary.background.default()
        end
    end, theme.tween.base)

    local foregroundColor = tween(function()
        if isSelecting() then
            return theme.button.secondary.foreground.select()
        elseif isPressing() then
            return theme.button.secondary.foreground.press()
        elseif isHovering() then
            return theme.button.secondary.foreground.hover()
        else
            return theme.button.secondary.foreground.default()
        end
    end, theme.tween.base)
    
    return vide.create "Frame" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = backgroundColor,

        if props.isStart or props.isEnd then
            vide.create "UIGradient" {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.4999, 0),
                    NumberSequenceKeypoint.new(0.5, 1),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Rotation = props.isStart and 180 or 0,
            }
        else nil,
        
        vide.create "TextButton" {
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
            
            vide.create "UIPadding" {
                PaddingLeft = theme.padding.md,
                PaddingRight = theme.padding.md,
                PaddingTop = theme.padding.sm,
                PaddingBottom = theme.padding.sm,
            },

            Activated = props.activated,

            buttonStateProps,
        }
    }
end

export type ContainerProps = {
    value: () -> string?,
    valueChanged: (string) -> (),
    options: {OptionProps},
    native: unknown,
}

return function(props: ContainerProps)
    local buttons = {}
    for index, option in props.options do
        option.isSelecting = function()
            return option.value == props.value()
        end
        option.activated = function()
            props.valueChanged(option.value)
        end
        option.isStart = (index == 1)
        option.isEnd = (index == #props.options)
        table.insert(buttons, optionButton(option))
    end
    
    return vide.create "Frame" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = theme.button.secondary.stroke.default,

        vide.create "UIListLayout" {
            FillDirection = Enum.FillDirection.Horizontal,
            -- simulate stroke with the background of this
            Padding = function()
                return UDim.new(0, theme.strokeThickness())
            end,
        },

        vide.create "UIStroke" {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.button.secondary.stroke.default,
            Thickness = theme.strokeThickness,
        },

        vide.create "UICorner" {
            CornerRadius = theme.radius.base,
        },

        buttons,

        props.native,
    }
end