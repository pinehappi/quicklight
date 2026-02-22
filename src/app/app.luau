local Selection = game:GetService("Selection")
local UserInputService = game:GetService("UserInputService")
local vide = require(script.Parent.Parent.Packages.vide)
local Properties = require(script.Parent.Parent.Properties)
local toolOrdering = require(script.Parent.Parent.toolOrdering)
local types = require(script.Parent.Parent.types)
local fadeFrame = require(script.Parent.base.fadeFrame)
local propertyBar = require(script.Parent.propertyBar)
local theme = require(script.Parent.theme)
local toolbar = require(script.Parent.toolbar)
local tween = require(script.Parent.tween)
local useLightVisualizer = require(script.Parent.useLightVisualizer)

local useTool = require(script.Parent.useTool)
local slider = require(script.Parent.base.slider)
local sidePanel = require(script.Parent.sidePanel)

local NUMBER_KEYCODES = {
    [Enum.KeyCode.One] = 1,
    [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four] = 4,
    [Enum.KeyCode.Five] = 5,
}

-- light source + tool selecting hotkeys
local function useHotkeys(options: {
    on: () -> boolean,
    isUsingTool: () -> boolean,
    lightSources: () -> {string},
    lightSource: () -> string,
    lightSourceSelected: (string) -> (),
    tools: () -> {string},
    tool: () -> string?,
    toolSelected: (string?) -> (),
    createLightsEnabledChanged: (boolean) -> (),
    propertiesEnabledToggled: () -> (),
})
    vide.cleanup(UserInputService.InputBegan:Connect(function(input, gpe)
        if not options.on() then return end
        if options.isUsingTool() then return end

        local number = NUMBER_KEYCODES[input.KeyCode]
        local tools = options.tools()
        if number and number <= #tools and input:IsModifierKeyDown(Enum.ModifierKey.Ctrl) then
            local found = 0
            for _, tool in toolOrdering do
                if table.find(tools, tool) then
                    found += 1
                end

                if found == number then
                    options.toolSelected(tool)
                    break
                end
            end
        elseif input.KeyCode == Enum.KeyCode.Tab then
            local lightSources = options.lightSources()
            local lightSourceIndex = table.find(lightSources, options.lightSource())
            if not lightSourceIndex then return end

            if input:IsModifierKeyDown(Enum.ModifierKey.Shift) then
                options.lightSourceSelected(lightSources[(lightSourceIndex - 2) % #lightSources + 1])
            else
                options.lightSourceSelected(lightSources[lightSourceIndex % #lightSources + 1])
            end
        elseif input.KeyCode == Enum.KeyCode.P and input:IsModifierKeyDown(Enum.ModifierKey.Shift) then
            options.propertiesEnabledToggled()
        elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            options.createLightsEnabledChanged(true)
        end
    end))

    vide.cleanup(UserInputService.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            options.createLightsEnabledChanged(false)
        end
    end))
end

-- handling tracking object for "object" mode
local function useLightSourceSelection(
    on: () -> boolean,
    lightSource: () -> string,
    lightSourceObject: (() -> types.LightSourceObject?) & ((types.LightSourceObject?) -> types.LightSourceObject?)
)
    -- TODO: handle the light source object container changing
    vide.effect(function()
        if on() and lightSource() == "object" then
            local function updateObject()
                local selection = Selection:Get()
                if #selection ~= 1 then
                    lightSourceObject(nil)
                    return
                end

                local object = selection[1]
                if not object:IsA("Light") and not object:IsA("BasePart") and not object:IsA("Attachment") then
                    lightSourceObject(nil)
                    return
                end

                local container: Attachment | BasePart | nil
                local light: Light?
                if object:IsA("Light") then
                    if object.Parent and object.Parent:IsA("BasePart") or object.Parent:IsA("Attachment") then
                        container = object.Parent
                    end
                    light = object
                else
                    container = object
                    light = object:FindFirstChildWhichIsA("Light")
                end

                if container and light then
                    local currentObject = lightSourceObject()
                    if currentObject and currentObject.light == light and (currentObject.container :: any) == container then
                        return
                    end

                    lightSourceObject({
                        container = container,
                        light = light,
                    })
                else
                    lightSourceObject(nil)
                end
            end

            vide.cleanup(Selection.SelectionChanged:Connect(updateObject))
            vide.untrack(updateObject)
        elseif on() then
            local object = vide.untrack(lightSourceObject)
            if object then
                --lightSourceObject(nil)

                local current = Selection:Get()
                if #current == 1 and (object.light == current[1] or object.container == current[1]) then
                    Selection:Set({})
                end
            end
        end
    end)
end

local function getFirstAvailableTool(tools: {string}): string?
    for _, tool in toolOrdering do
        if table.find(tools, tool) then
            return tool
        end
    end
    return nil
end

export type Props = {
    on: () -> boolean,
    onChanged: (boolean) -> (),
    plugin: Plugin,
    pluginButton: PluginToolbarButton,
}

return function(props: Props)
    local lightSource = vide.source("object")
    local lightSources = vide.source({
        "object",
        "sun",
        "moon",
    })
    local lightSourceObject = vide.source(nil :: types.LightSourceObject?)
    local distance = vide.source(5)
    local createLightsEnabled = vide.source(false)

    local tools = vide.derive(function()
        return
            if lightSource() == "object" then {
                "pen",
                "face",
                "line",
                "bounce",
            } else {
                "direct",
                "line",
                "face",
                "bounce",
                "shadow",
            }
    end)

    -- one source for the "backing" value, one for the exposed value that handles the tool no longer being available
    local toolBacking = vide.source("pen" :: string?)
    local tool = vide.derive(function(): string?
        local tools = tools()
        if toolBacking() and not table.find(tools, toolBacking()) then
            return getFirstAvailableTool(tools)
        else
            return toolBacking()
        end
    end)

    local isPropertiesEnabled = vide.source(true)
    local objectInfo = vide.derive(function()
        return Properties.getObjectInfo(lightSource(), lightSourceObject())
    end)

    local function handleToolSelected(newTool)
        if tool() == newTool then
            toolBacking(nil)
        else
            toolBacking(newTool)
        end
    end

    local function handleLightSourceSelected(newLightSource)
        lightSource(newLightSource)
        if toolBacking() == nil then
            toolBacking(getFirstAvailableTool(tools()))
        end
    end

    local isUsingTool = useTool(props.on, lightSource, tool, lightSourceObject, distance, createLightsEnabled)

    local toolbarPosition = vide.spring(function()
        local y = 0
        if not props.on() then
            y -= 60
            -- properties are visible, push up even more
            if isPropertiesEnabled() and objectInfo() then
                y -= 30
            end
        end
        if isUsingTool() then
            y -= 28
            if isPropertiesEnabled() and objectInfo() then
                y -= 40
            end
        end
        return UDim2.fromOffset(0, y)
    end, 0.18, 1)

    useLightSourceSelection(props.on, lightSource, lightSourceObject)

    useLightVisualizer({
        plugin = props.plugin,
        active = function()
            return props.on() and lightSource() == "object"
        end,
        lightSourceObject = lightSourceObject,
    })

    useHotkeys({
        on = props.on,
        isUsingTool = isUsingTool,
        lightSources = lightSources,
        lightSource = lightSource,
        lightSourceSelected = handleLightSourceSelected,
        tools = tools,
        tool = tool,
        toolSelected = handleToolSelected,
        createLightsEnabledChanged = createLightsEnabled,
        propertiesEnabledToggled = function()
            isPropertiesEnabled(not isPropertiesEnabled())
        end,
    })

    vide.effect(function()
        if props.on() and tool() then
            props.plugin:Activate(true)
        elseif props.on() and not tool() then
            props.plugin:Deactivate()
        end
    end)

    vide.cleanup(props.pluginButton.Click:Connect(function()
        props.onChanged(not props.on())
        if props.on() and tool() == nil then
            toolBacking(tools()[1])
        end
    end))

    vide.cleanup(props.plugin.Deactivation:Connect(function()
        if props.on() then
            toolBacking(nil)
        end
    end))

    local transparency = tween(function() return isUsingTool() and 0.5 or 0 end, theme.tween.slow)
    return {
        vide.show(props.on, function()
            local top = vide.create "Frame" {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                
                toolbar {
                    isPropertiesAvailable = function() return not not objectInfo() end,
                    isPropertiesEnabled = isPropertiesEnabled,
                    propertiesEnabledChanged = isPropertiesEnabled,
                    
                    tools = tools,
                    tool = tool,
                    toolSelected = handleToolSelected,

                    lightSources = lightSources,
                    lightSource = lightSource,
                    lightSourceSelected = handleLightSourceSelected,
                },

                vide.show(function() return isPropertiesEnabled() and objectInfo() end, function(objectInfo: any)
                    return propertyBar {
                        objectInfo = objectInfo,
                        distance = distance,
                        distanceChanged = distance,
                    }
                end),

                vide.create "Frame" {
                    Size = UDim2.fromOffset(200, 30),
                    Position = UDim2.fromScale(0.5, 0.8),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    
                    slider {
                        value = distance,
                        valueChanged = distance,
                        min = 1,
                        max = 50,
                        step = 1,
                    }
                },
            }
            
            return {
                fadeFrame {
                    transparency = transparency,
                    position = toolbarPosition,
                    size = UDim2.new(1, 0, 0, 150),
                    child = top,
                },

                vide.show(function() return lightSource() == "object" end, function()
                    return fadeFrame { 
                        transparency = transparency,
                        position = vide.spring(function()
                            if isUsingTool() then
                                return UDim2.new(0, 0, 1, 30)
                            else
                                return UDim2.fromScale(0, 1)
                            end
                        end, 0.18, 1),
                        size = UDim2.new(1, 0, 0, 100),
                        native = {
                            AnchorPoint = Vector2.new(0, 1),
                        },
                        child = sidePanel {
                            createLightsEnabled = createLightsEnabled,
                            createLightsEnabledChanged = createLightsEnabled,
                        },
                    }
                end),
            }, 0.5
        end)
    }
end
