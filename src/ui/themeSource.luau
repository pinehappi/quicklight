local vide = require(script.Parent.Parent.Packages.vide)
export type Theme = {
    strokeThickness: number,
    cornerRadius: {
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
        s: number,
        m: number,
        l: number,
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
        background: Color3,
        foreground: Color3,
        stroke: Color3,
    },
}

local function getTheme(): Theme
    local theme = settings().Studio.Theme
    return {
        strokeThickness = 1,
        cornerRadius = {
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
            s = 4,
            m = 6,
            l = 8,
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
            background = theme:GetColor(Enum.StudioStyleGuideColor.Button),
            foreground = theme:GetColor(Enum.StudioStyleGuideColor.ButtonText),
            stroke = theme:GetColor(Enum.StudioStyleGuideColor.Border),
        },
    }
end

local themeSource = vide.source(getTheme())

settings().Studio.ThemeChanged:Connect(function()
    themeSource(getTheme())
end)

return themeSource