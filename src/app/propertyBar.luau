local vide = require(script.Parent.Parent.Packages.vide)
local Properties = require(script.Parent.Parent.core.Properties)
local theme = require(script.Parent.theme)
local checkbox = require(script.Parent.base.checkbox)
local colorInput = require(script.Parent.base.colorInput)
local numberbox = require(script.Parent.base.numberbox)
local slider = require(script.Parent.base.slider)

local function propertyInput(props: {
    object: () -> any,
    property: string,
    changed: (value: any) -> (),
    order: number | () -> number,
})
    local object = props.object
    if not object then return nil end

    local spec = Properties.getSpec(props.property)
    local value = vide.source(nil :: any)

    vide.effect(function()
        value(props.object()[props.property])
        vide.cleanup(props.object():GetPropertyChangedSignal(props.property):Connect(function()
            value(props.object()[props.property])
        end))
    end)

    return vide.create "Frame" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        LayoutOrder = props.order,

        vide.create "UIListLayout" {
            Padding = theme.padding.md,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        },

        vide.create "TextLabel" {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            TextSize = theme.textSize.base,
            FontFace = theme.font.default,
            Text = props.property,
            TextColor3 = theme.surface0.foreground,

            vide.create "UIPadding" {
                PaddingLeft = theme.padding.sm,
                PaddingRight = theme.padding.sm,
                PaddingTop = theme.padding.sm,
                PaddingBottom = theme.padding.sm,
            },
        },

        if spec.type == "number" then
            {
                numberbox {
                    value = value,
                    valueChanged = props.changed,
                    native = {
                        Size = UDim2.fromOffset(50, 0)
                    }
                },
                slider {
                    value = value,
                    valueChanged = props.changed,
                    min = spec.min,
                    max = spec.max,
                    step = spec.step,
                    native = {
                        Size = UDim2.fromOffset(50, 12)
                    }
                },
            }
        elseif spec.type == "Color3" then
            colorInput {
                color = value,
                colorChanged = props.changed,
            }
        elseif spec.type == "boolean" then
            checkbox {
                checked = value,
                checkedChanged = props.changed,
            }
        else
            nil
    }
end

export type Props = {
    objectInfo: () -> Properties.ObjectInfo,
    propertyChanged: (property: string, value: any) -> (),
}

return function(props: Props)
    -- making it a button so it sinks input
    return vide.create "TextButton" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = theme.surface0.background,
        TextTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 52),
        AnchorPoint = Vector2.new(0.5, 0),

        vide.create "UICorner" {
            CornerRadius = theme.radius.base,
        },
        
        vide.create "UIStroke" {
            Color = theme.surface0.stroke,
            Thickness = theme.strokeThickness,
        },

        vide.create "UIPadding" {
            PaddingLeft = theme.padding.lg,
            PaddingRight = theme.padding.lg,
            PaddingTop = theme.padding.sm,
            PaddingBottom = theme.padding.sm,
        },

        vide.create "UIListLayout" {
            Padding = theme.padding.md,
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        },

        vide.values(function() return props.objectInfo().properties end, function(property, index)
            return propertyInput {
                object = function() return props.objectInfo().object end,
                property = property,
                order = index,
                changed = function(value)
                    props.propertyChanged(property, value)
                end,
            }
        end),
    }
end
