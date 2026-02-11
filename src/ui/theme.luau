local vide = require(script.Parent.Parent.Packages.vide)
local Oklab = require(script.Parent.Parent.utils.Oklab)
local themeSource = require(script.Parent.themeSource)

local destroy, theme = vide.root(function()
    return {
        strokeThickness = function()
            return themeSource().strokeThickness
        end,
        cornerRadius = {
            base = function()
                return UDim.new(0, themeSource().cornerRadius.base)
            end,
        },
        spacing = {
            xs = function()
                return themeSource().spacing.xs
            end,
            s = function()
                return themeSource().spacing.s
            end,
            m = function()
                return themeSource().spacing.m
            end,
            l = function()
                return themeSource().spacing.l
            end,
            xl = function()
                return themeSource().spacing.xl
            end,
        },
        padding = {
            xs = function()
                return UDim.new(0, themeSource().spacing.xs)
            end,
            s = function()
                return UDim.new(0, themeSource().spacing.s)
            end,
            m = function()
                return UDim.new(0, themeSource().spacing.m)
            end,
            l = function()
                return UDim.new(0, themeSource().spacing.l)
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
            light = function()
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
            background = {
                default = function()
                    return themeSource().button.background
                end,
                hover = vide.derive(function()
                    return Oklab.mix(themeSource().button.background, themeSource().button.foreground, 0.1)
                end),
                press = vide.derive(function()
                    return Oklab.mix(themeSource().button.background, themeSource().surface0.background, 0.1)
                end),
                select = function()
                    return themeSource().accent.main
                end,
            },
            foreground = {
                default = function()
                    return themeSource().button.foreground
                end,
                hover = function()
                    return themeSource().button.foreground
                end,
                press = function()
                    return themeSource().button.foreground
                end,
                select = function()
                    return themeSource().accent.foreground
                end,
            },
            stroke = {
                default = function()
                    return themeSource().button.stroke
                end,
                hover = function()
                    return themeSource().button.stroke
                end,
                press = vide.derive(function()
                    return Oklab.mix(themeSource().button.stroke, themeSource().surface0.stroke, 0.1)
                end),
                select = function()
                    return themeSource().accent.main
                end,
            }
        },
    }
end)

script:FindFirstAncestorWhichIsA("Plugin").Unloading:Connect(destroy)

return theme