local NAME = "lazylight"

local vide = require(script.Parent.Packages.vide)
local app = require(script.Parent.ui.app)

local pluginToolbar = plugin:CreateToolbar(NAME)
local pluginButton = pluginToolbar:CreateButton(NAME, "activate lazy light", "")

local gui = Instance.new("ScreenGui")
gui.Name = NAME
gui.Parent = game:GetService("CoreGui")

local on = vide.source(true)
local unmount = vide.mount(function()
    vide.effect(function()
        pluginButton:SetActive(on())
    end)

    vide.effect(function()
        gui.Enabled = on()
    end)
    
    return app {
        on = on,
    }
end, gui)

pluginButton.Click:Connect(function()
    on(not on())
    if on() then
        plugin:Activate(true)
    end
end)

plugin.Deactivation:Connect(function()
    on(false)
end)

plugin.Unloading:Connect(function()
    unmount()
    gui:Destroy()
end)