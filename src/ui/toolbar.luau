local vide = require(script.Parent.Parent.Packages.vide)
local button = require(script.Parent.base.button)
local icon = require(script.Parent.base.icon)
local theme = require(script.Parent.theme)

export type Props = {
    tools: () -> {string},
    activeTool: () -> string?,
    toolSelected: (string?) -> (),

    lightSources: () -> {string},
    activeLightSource: () -> string,
    lightSourceSelected: (string) -> (),
}

local toolIcons = {
    direct = "rbxassetid://4827658474",
    line = "rbxassetid://17380139258",
    bounce = "rbxassetid://2714338256",
    face = "rbxassetid://11955884948",
    shadow = "rbxassetid://12188334397",
}

local lightSourceIcons = {
    sun = "rbxassetid://17650932353",
    moon = "rbxassetid://17650930453",
}

return function(props: Props)
    return vide.create "Frame" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = theme.surface0.background,
        Position = UDim2.new(0.5, 0, 0, 12),
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

        vide.create "Frame" {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 0),
            
            vide.create "UIListLayout" {
                Padding = theme.padding.md,
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            },

            vide.values(props.lightSources, function(name, index)
                return button {
                    text = name,
                    icon = function(props)
                        return icon {
                            image = lightSourceIcons[name],
                            color = props.color,
                            size = theme.textSize.base,
                        }
                    end,
                    isSelecting = function()
                        return props.activeLightSource() == name
                    end,
                    activated = function()
                        props.lightSourceSelected(name)
                    end,

                    native = {
                        LayoutOrder = index,
                    }
                }
            end),
        },

        vide.create "Frame" {
            BackgroundColor3 = theme.surface0.stroke,
            Size = function()
                return UDim2.fromOffset(1, theme.textSize.base() + theme.spacing.sm())
            end,
        },

        vide.create "Frame" {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 0),
            
            vide.create "UIListLayout" {
                Padding = theme.padding.md,
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            },

            vide.values(props.tools, function(name, index)
                return button {
                    text = name,
                    icon = function(props)
                        return icon {
                            image = toolIcons[name],
                            color = props.color,
                            size = theme.textSize.base,
                        }
                    end,
                    isSelecting = function()
                        return props.activeTool() == name
                    end,
                    activated = function()
                        props.toolSelected(name)
                    end,
                    native = {
                        LayoutOrder = index,
                    }
                }
            end)
        },
    }
end
