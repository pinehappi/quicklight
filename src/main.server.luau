local NAME = "lazylight"

local vide = require(script.Parent.Packages.vide)
local app = require(script.Parent.ui.app)

local pluginToolbar = plugin:CreateToolbar(NAME)
local pluginButton = pluginToolbar:CreateButton(NAME, "activate lazylight", "")

local gui = Instance.new("ScreenGui")
gui.Name = NAME
gui.Parent = game:GetService("CoreGui")

local on = vide.source(false)
local activeTool = vide.source(nil :: string?)
local unmount = vide.mount(function()
    vide.effect(function()
        pluginButton:SetActive(on())
    end)

    vide.effect(function()
        if on() and activeTool() then
            plugin:Activate(true)
        elseif on() and not activeTool() then
            plugin:Deactivate()
        end
    end)

    vide.effect(function()
        gui.Enabled = on()
    end)
    
    return app {
        on = on,
        activeTool = activeTool,
        toolSelected = function(tool)
            if activeTool() == tool then
                activeTool(nil)
            else
                activeTool(tool)
            end
        end,
    }
end, gui)

pluginButton.Click:Connect(function()
    on(not on())
    if on() and activeTool() == nil then
        activeTool("direct")
    end
end)

plugin.Deactivation:Connect(function()
    if on() then
        activeTool(nil)
    end
end)

plugin.Unloading:Connect(function()
    unmount()
    gui:Destroy()
end)