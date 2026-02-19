local Lighting = game:GetService("Lighting")
local vide = require(script.Parent.Parent.Packages.vide)
local theme = require(script.Parent.theme)
local types = require(script.Parent.Parent.types)
local checkbox = require(script.Parent.base.checkbox)
local colorInput = require(script.Parent.base.colorInput)
local numberbox = require(script.Parent.base.numberbox)
local slider = require(script.Parent.base.slider)

export type Props = {
    lightSource: () -> string,
    lightSourceObject: () -> types.LightSourceObject?,
}

export type Property = {
    name: string,
    type: string,
}

type ObjectInfo = {
    object: any,
    properties: {Property}
}

local function getSourceInfo(lightSource: string, lightSourceObject: types.LightSourceObject?): ObjectInfo?
    if lightSource == "sun" or lightSource == "moon" then
        return {
            object = Lighting,
            properties = {
                { name = "Brightness", type = "number" },
                { name = "Ambient", type = "Color3" },
                { name = "OutdoorAmbient", type = "Color3" },
            }
        }
    elseif lightSource == "object" and lightSourceObject then
        local properties: {Property} = {
            { name = "Color", type = "Color3" },
            { name = "Brightness", type = "number" },
            { name = "Range", type = "number" },
            { name = "Shadows", type = "boolean" },
        }

        if lightSourceObject.light:IsA("SpotLight") or lightSourceObject.light:IsA("SurfaceLight") then
            table.insert(properties, 3, { name = "Angle", type = "number" })
        end

        return {
            object = lightSourceObject.light,
            properties = properties,
        }
    else
        return nil
    end
end

local function propertyInput(props: {
    object: any,
    property: Property,
    order: number | () -> number,
})
    local object = props.object
    if not object then return nil end

    local property = props.property
    local value = vide.source(object[property.name])

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
            Text = property.name,
            TextColor3 = theme.surface0.foreground,

            vide.create "UIPadding" {
                PaddingLeft = theme.padding.sm,
                PaddingRight = theme.padding.sm,
                PaddingTop = theme.padding.sm,
                PaddingBottom = theme.padding.sm,
            },
        },

        if property.type == "number" then
            {
                numberbox {
                    value = value,
                    valueChanged = value,
                    native = {
                        Size = UDim2.fromOffset(50, 0)
                    }
                },
                slider {
                    value = value,
                    valueChanged = value,
                    min = 0,
                    max = 60,
                    step = 0.5,
                    native = {
                        Size = UDim2.fromOffset(50, 12)
                    }
                },
            }
        elseif property.type == "Color3" then
            colorInput {
                color = value,
                colorChanged = value,
            }
        elseif property.type == "boolean" then
            checkbox {
                checked = value,
                checkedChanged = value,
            }
        else
            nil
    }
end

return function(props: Props)
    local objectInfo = vide.derive(function()
        return getSourceInfo(props.lightSource(), props.lightSourceObject())
    end)

    return vide.create "Frame" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = theme.surface0.background,
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

        vide.show(objectInfo, function(info)
            return vide.values(function() return info().properties end, function(property, index)
                return propertyInput {
                    object = info().object,
                    property = property,
                    order = index,
                }
            end)
        end),
    }
end
