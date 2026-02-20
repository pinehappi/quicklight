local vide = require(script.Parent.Parent.Packages.vide)
local Oklab = require(script.Parent.Parent.utils.Oklab)
local themeSource = require(script.Parent.themeSource)

local destroy, theme = vide.root(function()
    return {
        strokeThickness = function()
            return themeSource().strokeThickness
        end,
        radius = {
            base = function()
                return UDim.new(0, themeSource().radius.base)
            end,
            full = function()
                return UDim.new(1, 0)
            end,
        },
        spacing = {
            xs = function()
                return themeSource().spacing.xs
            end,
            sm = function()
                return themeSource().spacing.sm
            end,
            md = function()
                return themeSource().spacing.md
            end,
            lg = function()
                return themeSource().spacing.lg
            end,
            xl = function()
                return themeSource().spacing.xl
            end,
        },
        padding = {
            xs = function()
                return UDim.new(0, themeSource().spacing.xs)
            end,
            sm = function()
                return UDim.new(0, themeSource().spacing.sm)
            end,
            md = function()
                return UDim.new(0, themeSource().spacing.md)
            end,
            lg = function()
                return UDim.new(0, themeSource().spacing.lg)
            end,
            xl = function()
                return UDim.new(0, themeSource().spacing.xl)
            end,
        },
        font = {
            default = function()
                return themeSource().font.default
            end
        },
        textSize = {
            base = function()
                return themeSource().textSize.base
            end
        },
        surface0 = {
            background = function()
                return themeSource().surface0.background
            end,
            foreground = function()
                return themeSource().surface0.foreground
            end,
            stroke = function()
                return themeSource().surface0.stroke
            end
        },
        accent = {
            faint = function()
                return Oklab.mix(themeSource().accent.main, Color3.new(1, 1, 1), 0.5)
            end,
            main = function()
                return themeSource().accent.main
            end,
            foreground = function()
                return themeSource().accent.foreground
            end,
        },
        button = {
            secondary = {
                background = {
                    default = function()
                        return themeSource().button.secondary.background
                    end,
                    hover = vide.derive(function()
                        return Oklab.mix(themeSource().button.secondary.background, themeSource().button.secondary.foreground, 0.1)
                    end),
                    press = vide.derive(function()
                        return Oklab.mix(themeSource().button.secondary.background, themeSource().surface0.background, 0.1)
                    end),
                    select = function()
                        return themeSource().accent.main
                    end,
                },
                foreground = {
                    default = function()
                        return themeSource().button.secondary.foreground
                    end,
                    hover = function()
                        return themeSource().button.secondary.foreground
                    end,
                    press = function()
                        return themeSource().button.secondary.foreground
                    end,
                    select = function()
                        return themeSource().accent.foreground
                    end,
                },
                stroke = {
                    default = function()
                        return themeSource().button.secondary.stroke
                    end,
                    hover = function()
                        return themeSource().button.secondary.stroke
                    end,
                    press = vide.derive(function()
                        return Oklab.mix(themeSource().button.secondary.stroke, themeSource().surface0.background, 0.1)
                    end),
                    select = function()
                        return themeSource().accent.main
                    end,
                },
            },
            ghost = {
                background = function()
                    return themeSource().button.ghost.background
                end,
                foreground = function()
                    return themeSource().button.ghost.foreground
                end,
                backgroundTransparency = {
                    default = function()
                        return 1
                    end,
                    hover = function()
                        return 0.9
                    end,
                    press = function()
                        return 0.85
                    end,
                },
            }
        },
        input = {
            background = {
                default = function()
                    return themeSource().input.background
                end,
                hover = function()
                    return themeSource().input.background
                end,
                press = function()
                    return themeSource().input.background
                end,
                select = function()
                    return themeSource().input.background
                end,
            },
            foreground = {
                default = function()
                    return themeSource().input.foreground
                end,
                hover = function()
                    return themeSource().input.foreground
                end,
                press = function()
                    return themeSource().input.foreground
                end,
                select = function()
                    return themeSource().input.foreground
                end,
            },
            stroke = {
                default = function()
                    return themeSource().input.stroke
                end,
                hover = function()
                    return Oklab.mix(themeSource().input.stroke, themeSource().surface0.foreground, 0.1)
                end,
                press = function()
                    return Oklab.mix(themeSource().input.stroke, themeSource().surface0.background, 0.1)
                end,
                select = function()
                    return themeSource().input.strokeActive
                end,
            }

        },
        tween = {
            base = function()
                return themeSource().tween.base
            end,
            slow = function()
                return themeSource().tween.slow
            end,
        }
    }
end)

script:FindFirstAncestorWhichIsA("Plugin").Unloading:Connect(destroy)

return theme