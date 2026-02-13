local NAME = "lazylight"

local vide = require(script.Parent.Packages.vide)
local app = require(script.Parent.app.app)

local pluginToolbar = plugin:CreateToolbar(NAME)
local pluginButton = pluginToolbar:CreateButton(NAME, `activate {NAME}`, "")

local gui = Instance.new("ScreenGui")
gui.Name = NAME
gui.Parent = game:GetService("CoreGui")

local on = vide.source(false)
local unmount = vide.mount(function()
    vide.effect(function()
        gui.Enabled = on()
    end)
    
    return app {
        on = on,
        onChanged = on,
        plugin = plugin,
        pluginButton = pluginButton,
    }
end, gui)

plugin.Unloading:Connect(function()
    unmount()
    gui:Destroy()
end)