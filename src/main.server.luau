local NAME = "lazylight"

local vide = require(script.Parent.Packages.vide)
local app = require(script.Parent.ui.app)

local pluginToolbar = plugin:CreateToolbar(NAME)
local pluginButton = pluginToolbar:CreateButton(NAME, "activate lazylight", "")

local gui = Instance.new("ScreenGui")
gui.Name = NAME
gui.Parent = game:GetService("CoreGui")

local on = vide.source(false)
local activePlacer = vide.source(nil :: string?)
local unmount = vide.mount(function()
    vide.effect(function()
        pluginButton:SetActive(on())
    end)

    vide.effect(function()
        if on() and activePlacer() then
            plugin:Activate(true)
        end
    end)

    vide.effect(function()
        gui.Enabled = on()
    end)
    
    return app {
        on = on,
        activePlacer = activePlacer,
        placerSelected = function(placer)
            if activePlacer() == placer then
                activePlacer(nil)
            else
                activePlacer(placer)
            end
        end,
    }
end, gui)

pluginButton.Click:Connect(function()
    on(not on())
    if on() and activePlacer() == nil then
        activePlacer("direct")
    end
end)

plugin.Deactivation:Connect(function()
    if on() then
        activePlacer(nil)
    end
end)

plugin.Unloading:Connect(function()
    unmount()
    gui:Destroy()
end)