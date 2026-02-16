local CoreGui = game:GetService("CoreGui")
local Selection = game:GetService("Selection")
local UserInputService = game:GetService("UserInputService")
local vide = require(script.Parent.Parent.Packages.vide)
local runTool = require(script.Parent.Parent.core.runTool)
local toolOrdering = require(script.Parent.Parent.toolOrdering)
local tools = require(script.Parent.Parent.tools)
local types = require(script.Parent.Parent.types)
local fadeFrame = require(script.Parent.base.fadeFrame)
local toolbar = require(script.Parent.toolbar)
local tween = require(script.Parent.tween)

-- connects events and wires up tools
local function useTool(
    on: () -> boolean,
    lightSource: () -> string,
    tool: () -> string?,
    lightSourceObject: () -> types.LightSourceObject?
)
    local currentAction = vide.source(nil :: {
        tool: string,
        initialState: types.ToolState,
        update: runTool.UpdateToolCallback,
        -- sources
        currentState: (() -> types.ToolState) & ((types.ToolState) -> ()),
        direction: (() -> Vector3) & ((Vector3) -> ()),
    }?)

    local function tryUpdate(commit: boolean)
        local action = currentAction()
        if action then
            local result = action.update(commit)
            if result.kind == "success" then
                action.currentState(result.data.currentState)
                action.direction(result.data.direction)
            end
        end
    end

    vide.cleanup(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if not on() then return end

        local tool = tool()
        if not tool then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 and tool and (not currentAction()) then
            local initialState, update = runTool(tool, lightSource(), lightSourceObject())
            local connection: RBXScriptConnection
            connection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
                if input.UserInputState ~= Enum.UserInputState.Begin and input.UserInputState ~= Enum.UserInputState.Change then
                    connection:Disconnect()
                    local newAction = currentAction()
                    if newAction and newAction.initialState == initialState then
                        tryUpdate(true)
                        currentAction(nil)
                    end
                end
            end)

            currentAction({
                tool = tool,
                initialState = initialState,
                currentState = vide.source(initialState),
                direction = vide.source(Vector3.zero),
                update = update,
            })
            tryUpdate(false)
        end
    end))

    vide.effect(function()
        local action = currentAction()
        if not action then return end

        local tool = tools[action.tool]
        if tool.gizmo then
            local gizmo = vide.untrack(function()
                return tool.gizmo(action.initialState, action.currentState, action.direction) :: GuiObject
            end)
            gizmo.Parent = CoreGui

            vide.cleanup(gizmo)
        end

        vide.cleanup(UserInputService.InputChanged:Connect(function(input)
            if not on() then return end

            if input.UserInputType == Enum.UserInputType.MouseMovement then
                tryUpdate(false)
            end
        end))

        local camera = workspace.CurrentCamera
        if camera then
            vide.cleanup(camera:GetPropertyChangedSignal("CFrame"):Connect(function(input)
                if not on() then return end

                tryUpdate(false)
            end))
        end
    end)

    return function()
        return not not currentAction()
    end
end

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
    lightSources: () -> {string},
    lightSource: () -> string,
    lightSourceSelected: (string) -> (),
    tools: () -> {string},
    tool: () -> string?,
    toolSelected: (string?) -> ()
})
     vide.effect(function()
        if options.on() then
            vide.cleanup(UserInputService.InputBegan:Connect(function(input, gpe)
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
                end
            end))
        end
    end)
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
                if #selection ~= 1 then return end

                local object = selection[1]
                if not object:IsA("Light") and not object:IsA("BasePart") and not object:IsA("Attachment") then
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
                end
            end

            vide.cleanup(Selection.Changed:Connect(updateObject))
            updateObject()
        end
    end)
end

export type Props = {
    on: () -> boolean,
    onChanged: (boolean) -> (),
    plugin: Plugin,
    pluginButton: PluginToolbarButton,
}

return function(props: Props)
    local lightSource = vide.source("sun")
    local lightSources = vide.source({
        "object",
        "sun",
        "moon",
    })
    local lightSourceObject = vide.source(nil :: types.LightSourceObject?)

    local tools = vide.derive(function()
        return
            if lightSource() == "object" then {
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
    local toolBacking = vide.source("direct" :: string?)
    local tool = vide.derive(function(): string?
        if toolBacking() and not table.find(tools(), toolBacking()) then
            return tools()[1]
        else
            return toolBacking()
        end
    end)

    local function handleToolSelected(newTool)
        if tool() == newTool then
            toolBacking(nil)
        else
            toolBacking(newTool)
        end
    end

    local isUsingTool = useTool(props.on, lightSource, tool, lightSourceObject)

    useLightSourceSelection(props.on, lightSource, lightSourceObject)

    useHotkeys({
        on = props.on,
        lightSources = lightSources,
        lightSource = lightSource,
        lightSourceSelected = lightSource,
        tools = tools,
        tool = tool,
        toolSelected = handleToolSelected,
    })

    vide.effect(function()
        props.pluginButton:SetActive(props.on())
    end)

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

    return {
        fadeFrame {
            transparency = tween(function() return isUsingTool() and 0.5 or 0 end, 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            position = vide.spring(function() return isUsingTool() and UDim2.fromOffset(0, -28) or UDim2.fromOffset(0, 0) end, 0.18, 1),
            size = UDim2.new(1, 0, 0, 300),
            child = toolbar {
                tools = tools,
                tool = tool,
                toolSelected = handleToolSelected,

                lightSources = lightSources,
                lightSource = lightSource,
                lightSourceSelected = lightSource,
            },
        },
    }
end
