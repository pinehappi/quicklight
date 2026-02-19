local vide = require(script.Parent.Parent.Parent.Packages.vide)
local theme = require(script.Parent.Parent.theme)
local popup = require(script.Parent.popup)
local slider = require(script.Parent.slider)
local textbox = require(script.Parent.textbox)
local withDrag = require(script.Parent.withDrag)

local CIRCLE_ASSET = "rbxassetid://5552526748"

local function rgbComponent(props: {
    name: string,
    value: () -> number,
    valueChanged: (number) -> (),
    color: Color3,
})
    return vide.create "Frame" {
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.fromScale(1, 0),
        BackgroundTransparency = 1,

        vide.create "UIListLayout" {
            Padding = theme.padding.xs,
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        },

        vide.create "Frame" {
            Name = "Title",
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.fromScale(1, 0),
            BackgroundTransparency = 1,

            vide.create "UIListLayout" {
                Padding = theme.padding.xs,
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween,
            },

            vide.create "TextLabel" {
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                Text = props.name,
                TextColor3 = theme.surface0.foreground,
                TextSize = theme.textSize.base,
                FontFace = theme.font.default,
                TextXAlignment = Enum.TextXAlignment.Left,
            },

            textbox {
                text = function() return tostring(props.value()) end,
                textChanged = function(text)
                    local number = tonumber(text)
                    if number then
                        props.valueChanged(math.clamp(number, 0, 255))
                    end
                end,
                padding = {
                    left = theme.padding.xs,
                    right = theme.padding.xs,
                    top = theme.padding.xs,
                    bottom = theme.padding.xs,
                },
                native = {
                    Size = UDim2.fromOffset(36, 0),
                },
            },
        },

        slider {
            value = props.value,
            valueChanged = props.valueChanged,
            min = 0,
            max = 255,
            step = 1,
            native = {
                Size = UDim2.new(1, 0, 0, 12),
            },
            color = props.color,
        },
    }
end

local function pickerPopup(props: {
    color: () -> Color3,
    colorChanged: (Color3) -> (),
})
    return vide.create "Frame" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = theme.surface0.background,

        vide.create "UIStroke" {
            Color = theme.surface0.stroke,
            Thickness = theme.strokeThickness,
        },

        vide.create "UICorner" {
            CornerRadius = theme.radius.base,
        },

        vide.create "UIPadding" {
            PaddingLeft = theme.padding.sm,
            PaddingRight = theme.padding.sm,
            PaddingTop = theme.padding.sm,
            PaddingBottom = theme.padding.sm,
        },

        vide.create "UIListLayout" {
            Padding = theme.padding.xl,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        },

        vide.create "Frame" {
            Name = "Picker",
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,

            vide.create "UIListLayout" {
                Padding = theme.padding.sm,
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            },

            vide.create "Frame" {
                BackgroundColor3 = function()
                    local h, _, _ = props.color():ToHSV()
                    return Color3.fromHSV(h, 1, 1)
                end,
                Size = UDim2.fromOffset(100, 100),

                vide.create "UICorner" {
                    CornerRadius = theme.radius.base,
                },

                vide.create "Frame" {
                    Size = UDim2.fromScale(1, 1),

                    vide.create "UICorner" {
                        CornerRadius = theme.radius.base,
                    },

                    vide.create "UIGradient" {
                        Transparency = NumberSequence.new(0, 1),
                        Color = ColorSequence.new(Color3.new(1, 1, 1)),
                        Rotation = 180,
                    },
                },

                vide.create "Frame" {
                    Name = "Value",
                    Size = UDim2.fromScale(1, 1),

                    vide.create "UICorner" {
                        CornerRadius = theme.radius.base,
                    },

                    vide.create "UIGradient" {
                        Transparency = NumberSequence.new(0, 1),
                        Color = ColorSequence.new(Color3.new(0, 0, 0)),
                        Rotation = -90,
                    },
                },

                vide.create "ImageLabel" {
                    BackgroundTransparency = 1,
                    Image = CIRCLE_ASSET,
                    ImageColor3 = function()
                        local color = props.color()
                        if math.sqrt(color.R^2 + color.G^2 + color.B^2) >= 0.75 then
                            return Color3.new(0, 0, 0)
                        else
                            return Color3.new(1, 1, 1)
                        end
                    end,
                    Size = UDim2.fromOffset(12, 12),
                    AnchorPoint = Vector2.new(0.5, 0.5),

                    Position = function()
                        local _, s, v = props.color():ToHSV()
                        return UDim2.fromScale(1 - s, 1 - v)
                    end,

                    vide.create "ImageLabel" {
                        BackgroundTransparency = 1,
                        Image = CIRCLE_ASSET,
                        ImageColor3 = props.color,
                        Size = UDim2.fromOffset(10, 10),
                        Position = UDim2.fromScale(0.5, 0.5),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                    },
                },

                withDrag(function(percentX: number, percentY: number)
                    local hue = props.color():ToHSV()
                    props.colorChanged(Color3.fromHSV(hue, 1 - percentX, 1 - percentY))
                end),
            },

            vide.create "Frame" {
                Size = UDim2.fromOffset(100, 6),
                
                vide.create "UICorner" {
                    CornerRadius = theme.radius.full,
                },

                vide.create "UIGradient" {
                    -- thnaks chatgpt
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0/6, Color3.fromHSV(0/6, 1, 1)), -- Red
                        ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1, 1)), -- Yellow
                        ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1, 1)), -- Green
                        ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1, 1)), -- Cyan
                        ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1, 1)), -- Blue
                        ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1, 1)), -- Magenta
                        ColorSequenceKeypoint.new(6/6, Color3.fromHSV(6/6, 1, 1))  -- Red (wrap)
                    }),
                },

                vide.create "ImageLabel" {
                    BackgroundTransparency = 1,
                    Image = CIRCLE_ASSET,
                    ImageColor3 = Color3.new(0, 0, 0),
                    Size = UDim2.fromOffset(12, 12),
                    AnchorPoint = Vector2.new(0.5, 0.5),

                    Position = function()
                        local h, _, _ = props.color():ToHSV()
                        return UDim2.fromScale(h, 0.5)
                    end,

                    vide.create "ImageLabel" {
                        BackgroundTransparency = 1,
                        Image = CIRCLE_ASSET,
                        ImageColor3 = function()
                            local h, _, _ = props.color():ToHSV()
                            return Color3.fromHSV(h, 1, 1)
                        end,
                        Size = UDim2.fromOffset(10, 10),
                        Position = UDim2.fromScale(0.5, 0.5),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                    },
                },

                withDrag(function(percentX: number, _: number)
                    local _, saturation, value = props.color():ToHSV()
                    props.colorChanged(Color3.fromHSV(percentX, saturation, value))
                end)
            }
        },

        vide.create "Frame" {
            Name = "Options",
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.fromOffset(100, 0),
            BackgroundTransparency = 1,

            vide.create "UIListLayout" {
                Padding = theme.padding.sm,
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
            },

            rgbComponent {
                name = "R",
                color = Color3.new(1, 0, 0),
                value = function()
                    return math.round(props.color().R * 255)
                end,
                valueChanged = function(r)
                    props.colorChanged(Color3.new(r / 255, props.color().G, props.color().B))
                end,
            },

            rgbComponent {
                name = "G",
                color = Color3.new(0, 1, 0),
                value = function()
                    return math.round(props.color().G * 255)
                end,
                valueChanged = function(g)
                    props.colorChanged(Color3.new(props.color().R, g / 255, props.color().B))
                end,
            },

            rgbComponent {
                name = "B",
                color = Color3.new(0, 0, 1),
                value = function()
                    return math.round(props.color().B * 255)
                end,
                valueChanged = function(b)
                    props.colorChanged(Color3.new(props.color().R, props.color().G, b / 255))
                end,
            },
        },
    }
end

export type Props = {
    color: () -> Color3,
    colorChanged: (Color3) -> (),
    native: any,
}

return function(props: Props)
    local isPopupActive = vide.source(false)

    return vide.create "Frame" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,

        vide.create "UIListLayout" {
            Padding = theme.padding.sm,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        },

        vide.create "TextButton" {
            BackgroundColor3 = props.color,

            vide.create "UICorner" {
                CornerRadius = theme.radius.base,
            },

            vide.create "UIStroke" {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Color = theme.input.stroke.default,
                Thickness = theme.strokeThickness,
            },

            Size = UDim2.fromOffset(24, 24),

            Activated = function()
                isPopupActive(not isPopupActive())
            end,

            vide.show(isPopupActive, function()
                return popup {
                    closed = function()
                        isPopupActive(false)
                    end,
                    size = function(size)
                        return UDim2.fromOffset(0, 0)
                    end,
                    position = function(pos, size)
                        return UDim2.fromOffset(pos.x, pos.y + size.y + theme.spacing.lg())
                    end,
                    children = pickerPopup {
                        color = props.color,
                        colorChanged = props.colorChanged
                    },
                    native = {
                        AutomaticSize = Enum.AutomaticSize.XY,
                    }
                }
            end),
        },

        textbox {
            text = function()
                return "#" .. props.color():ToHex()
            end,
            textChanged = function(text)
                
            end,

            native = {
                Size = UDim2.fromOffset(60, 0),
            },
        },

        props.native,
    }
end
