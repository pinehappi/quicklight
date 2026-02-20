local vide = require(script.Parent.Parent.Packages.vide)
export type Theme = {
    strokeThickness: number,
    radius: {
        base: number,
    },
    font: {
        default: Font,
    },
    textSize: {
        base: number,
    },
    spacing: {
        xs: number,
        sm: number,
        md: number,
        lg: number,
        xl: number,
    },
    accent: {
        main: Color3,
        foreground: Color3,
    },
    surface0: {
        background: Color3,
        foreground: Color3,
        stroke: Color3,
    },
    button: {
        secondary: {
            background: Color3,
            foreground: Color3,
            stroke: Color3,
        },
        ghost: {
            background: Color3,
            foreground: Color3,
        },
    },
    input: {
        background: Color3,
        foreground: Color3,
        stroke: Color3,
        strokeActive: Color3,
    },
    tween: {
        base: TweenInfo,
        slow: TweenInfo,
    },
}

local function getTheme(): Theme
    local theme = settings().Studio.Theme
    return {
        strokeThickness = 1,
        radius = {
            base = 4,
        },
        font = {
            default = Font.fromEnum(Enum.Font.SourceSans)
        },
        textSize = {
            base = 16,
        },
        spacing = {
            xs = 2,
            sm = 4,
            md = 6,
            lg = 8,
            xl = 10,
        },
        accent = {
            main = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButton),
            foreground = theme:GetColor(Enum.StudioStyleGuideColor.DialogMainButtonText),
        },
        surface0 = {
            background = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
            foreground = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
            stroke = theme:GetColor(Enum.StudioStyleGuideColor.Border),
        },
        button = {
            secondary = {
                background = theme:GetColor(Enum.StudioStyleGuideColor.Button),
                foreground = theme:GetColor(Enum.StudioStyleGuideColor.ButtonText),
                stroke = theme:GetColor(Enum.StudioStyleGuideColor.Border),
            },
            ghost = {
                background = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
                foreground = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
            }
        },
        input = {
            background = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
            foreground = theme:GetColor(Enum.StudioStyleGuideColor.ButtonText),
            stroke = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder),
            strokeActive = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder, Enum.StudioStyleGuideModifier.Selected),
        },
        tween = {
            base = TweenInfo.new(0.06, Enum.EasingStyle.Quad),
            slow = TweenInfo.new(0.17, Enum.EasingStyle.Sine),
        }
    }
end

local themeSource = vide.source(getTheme())

settings().Studio.ThemeChanged:Connect(function()
    themeSource(getTheme())
end)

return themeSource