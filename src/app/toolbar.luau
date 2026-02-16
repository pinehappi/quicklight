local vide = require(script.Parent.Parent.Packages.vide)
local button = require(script.Parent.base.button)
local icon = require(script.Parent.base.icon)
local layerContext = require(script.Parent.layerContext)
local theme = require(script.Parent.theme)
local toolOrdering = require(script.Parent.Parent.toolOrdering)
local tween = require(script.Parent.tween)

local toolIcons = {
    direct = "rbxassetid://115640630847427",
    line = "rbxassetid://5210472205",
    bounce = "rbxassetid://2714338256",
    face = "rbxassetid://11955884948",
    shadow = "rbxassetid://12188334397",
}

local lightSourceIcons = {
    object = "rbxassetid://122586788171758",
    sun = "rbxassetid://17650932353",
    moon = "rbxassetid://17650930453",
}

export type Props = {
    tools: () -> {string},
    tool: () -> string?,
    toolSelected: (string?) -> (),

    lightSources: () -> {string},
    lightSource: () -> string,
    lightSourceSelected: (string) -> (),
}

return function(props: Props)
    -- we want buttons be full size on the first render
    local firstRender: {[string]: boolean} = {}
    for _, tool in toolOrdering do
        firstRender[tool] = true
    end

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
                        return props.lightSource() == name
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
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            },

            vide.values(props.tools, function(name, _, present)
                local index = table.find(toolOrdering, name)
                local toolButton = button {
                    text = name,
                    icon = function(props)
                        return icon {
                            image = toolIcons[name],
                            color = props.color,
                            size = theme.textSize.base,
                        }
                    end,
                    isSelecting = function()
                        return props.tool() == name
                    end,
                    activated = function()
                        props.toolSelected(name)
                    end,
                }

                local size = vide.source(Vector2.zero)
                -- parent immediately so we can get the size
                toolButton.Parent = layerContext()
                size(toolButton.AbsoluteSize)

                local currentSizeX = tween(function()
                    if present() or firstRender[name] then
                        if present() then
                            firstRender[name] = false
                        end
                        return size().X
                    else
                        return 0
                    end
                end, theme.tween.slow)
                
                local currentPadding = tween(function()
                    if (present() or firstRender[name]) and index < #toolOrdering then
                        return theme.spacing.md()
                    else
                        return 0
                    end
                end, theme.tween.slow)

                vide.apply(toolButton) {
                    AutomaticSize = Enum.AutomaticSize.None,
                    ClipsDescendants = true,
                    Size = function()
                        return UDim2.fromOffset(currentSizeX(), size().Y)
                    end,
                }
                
                -- hide the stroke so when its collapsed its completely gone
                vide.apply(toolButton:FindFirstChildOfClass("UIStroke")) {
                    Transparency = function()
                        return currentSizeX() == 0 and 1 or 0
                    end,
                }

                return vide.create "Frame" {
                    Size = function()
                        return UDim2.fromOffset(currentSizeX() + currentPadding(), size().Y)
                    end,
                    BackgroundTransparency = 1,
                    LayoutOrder = index,
                    toolButton,
                }, 5
            end)
        },
    }
end
