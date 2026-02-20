local NAME = "quicklight"

local vide = require(script.Parent.Packages.vide)
local app = require(script.Parent.app.app)
local layerContext = require(script.Parent.app.layerContext)

local pluginToolbar = plugin:CreateToolbar(NAME)
local pluginButton = pluginToolbar:CreateButton(NAME, `activate {NAME}`, "rbxassetid://87332514379465")

local gui = Instance.new("ScreenGui")
gui.Name = NAME
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = true
gui.Parent = game:GetService("CoreGui")

local on = vide.source(false)
local unmount = vide.mount(function()
    return layerContext(gui, function()
        return app {
            on = on,
            onChanged = on,
            plugin = plugin,
            pluginButton = pluginButton,
        }
    end)
end, gui)

plugin.Unloading:Connect(function()
    unmount()
    gui:Destroy()
end)