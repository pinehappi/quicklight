local vide = require(script.Parent.Parent.Packages.vide)
local button = require(script.Parent.base.button)
local theme = require(script.Parent.theme)

export type Props = {
    createLightsEnabled: () -> boolean,
    createLightsEnabledChanged: (boolean) -> (),
}

return function(props: Props)
    return vide.create "Frame" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = theme.surface0.background,
        AnchorPoint = Vector2.new(0, 1),
        Position = function()
            return UDim2.new(0, theme.spacing.xl(), 1, -theme.spacing.xl())
        end,

        vide.create "UIPadding" {
            PaddingLeft = theme.padding.md,
            PaddingRight = theme.padding.md,
            PaddingTop = theme.padding.md,
            PaddingBottom = theme.padding.md,
        },

        vide.create "UIStroke" {
            Color = theme.surface0.stroke
        },

        vide.create "UICorner" {
            CornerRadius = theme.radius.base,
        },
        
        vide.create "UIListLayout" {
            Padding = theme.padding.sm,
            FillDirection = Enum.FillDirection.Vertical,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
        },

        vide.create "Frame" {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,

            vide.create "UIListLayout" {
                Padding = theme.padding.xl,
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
            },

            vide.create "TextLabel" {
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.XY,
                TextColor3 = theme.surface0.foreground,
                TextSize = theme.textSize.base,
                FontFace = theme.font.default,
                Text = "Create Light",
                TextXAlignment = Enum.TextXAlignment.Left,
            },

            button {
                text = "Shift",
                isSelecting = props.createLightsEnabled,
                padding = {
                    left = UDim.new(0, 16),
                    right = UDim.new(0, 16),
                    top = theme.padding.sm,
                    bottom = theme.padding.sm,
                },
                activated = function()
                    props.createLightsEnabledChanged(not props.createLightsEnabled())
                end,
            },
        },
    }
end
