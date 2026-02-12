local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local vide = require(script.Parent.Parent.Packages.vide)
local runTool = require(script.Parent.Parent.core.runTool)
local tools = require(script.Parent.Parent.tools)
local types = require(script.Parent.Parent.types)
local toolbar = require(script.Parent.toolbar)

-- connects events and wires up tools
local function useTool(on: () -> boolean, activeLightSource: () -> string, activeTool: () -> string?)
    local currentUsing = vide.source(nil :: {
        activity: types.ToolActivity,
        update: (commit: boolean) -> (),
    }?)

    vide.cleanup(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if not on() then return end

        local tool = activeTool()
        if not tool then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 and tool and (not currentUsing()) then
            local activity, update = runTool(tool, activeLightSource())
            local connection: RBXScriptConnection
            connection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
                if input.UserInputState ~= Enum.UserInputState.Begin and input.UserInputState ~= Enum.UserInputState.Change then
                    connection:Disconnect()
                    local newCurrent = currentUsing()
                    if newCurrent and newCurrent.activity == activity then
                        update(true)
                        currentUsing(nil)
                    end
                end
            end)

            currentUsing({
                activity = activity,
                update = update,
            })
            update(false)
        end
    end))

    vide.effect(function()
        local using = currentUsing()
        if using then
            local tool = tools[using.activity.tool]
            if tool.gizmo then
                local gizmo = vide.untrack(function()
                    return tool.gizmo(using.activity.initial, using.activity.current, using.activity.direction) :: GuiObject
                end)
                gizmo.Parent = CoreGui

                vide.cleanup(gizmo)
            end

            vide.cleanup(UserInputService.InputChanged:Connect(function(input)
                if not on() then return end

                local using = currentUsing()
                if input.UserInputType == Enum.UserInputType.MouseMovement and using then
                    using.update(false)
                end
            end))

            local camera = workspace.CurrentCamera
            if camera then
                vide.cleanup(camera:GetPropertyChangedSignal("CFrame"):Connect(function(input)
                    if not on() then return end

                    local using = currentUsing()
                    if using then
                        using.update(false)
                    end
                end))
            end
        end
    end)
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
    activeLightSource: () -> string,
    lightSourceSelected: (string) -> (),
    tools: () -> {string},
    activeTool: () -> string?,
    toolSelected: (string?) -> ()
})
     vide.effect(function()
        if options.on() then
            vide.cleanup(UserInputService.InputBegan:Connect(function(input, gpe)
                local number = NUMBER_KEYCODES[input.KeyCode]
                if number and options.tools()[number] and input:IsModifierKeyDown(Enum.ModifierKey.Ctrl) then
                    options.toolSelected(options.tools()[number])
                elseif input.KeyCode == Enum.KeyCode.Tab then
                    local lightSourceIndex = table.find(options.lightSources(), options.activeLightSource())
                    if lightSourceIndex then
                        options.lightSourceSelected(options.lightSources()[lightSourceIndex % #options.lightSources() + 1])
                    end
                end
            end))
        end
    end)
end

export type Props = {
    on: () -> boolean,

    activeTool: () -> string?,
    toolSelected: (string?) -> (),
}

return function(props: Props)
    local activeLightSource = vide.source("sun")
    local lightSources = vide.source({
        "sun",
        "moon",
    })
    local tools = vide.source({
        "direct",
        "line",
        "face",
        "bounce",
        "shadow",
    })

    useTool(props.on, activeLightSource, props.activeTool)

    useHotkeys({
        on = props.on,
        lightSources = lightSources,
        activeLightSource = activeLightSource,
        lightSourceSelected = activeLightSource,
        tools = tools,
        activeTool = props.activeTool,
        toolSelected = props.toolSelected,
    })
   
    return {
        toolbar {
            tools = tools,
            activeTool = props.activeTool,
            toolSelected = props.toolSelected,

            lightSources = lightSources,
            activeLightSource = activeLightSource,
            lightSourceSelected = activeLightSource,
        },
    }
end
