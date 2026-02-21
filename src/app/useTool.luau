local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local vide = require(script.Parent.Parent.Packages.vide)
local startTool = require(script.Parent.Parent.startTool)
local types = require(script.Parent.Parent.types)

-- connects events and wires up tools
-- returns a source for whether a tool is in use
return function(
    on: () -> boolean,
    lightSource: () -> string,
    tool: () -> string?,
    lightSourceObject: () -> types.LightSourceObject?
)
    local currentAction = vide.source(nil :: {
        gizmo: types.Gizmo?,
        update: startTool.UpdateToolCallback,
        -- sources
        currentState: (() -> types.ToolState) & ((types.ToolState) -> ()),
        placement: (() -> types.LightPlacement) & ((types.LightPlacement) -> ()),
    }?)

    local function tryUpdate()
        local action = currentAction()
        if action then
            local result = action.update()
            if result.kind == "success" then
                action.currentState(result.data.currentState)
                action.placement(result.data.placement)
            end
        end
    end

    vide.cleanup(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if not on() then return end

        local tool = tool()
        if not tool then return end

        if currentAction() then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 and tool and (not currentAction()) then
            local initialState, gizmo, update = startTool(tool, lightSource(), lightSourceObject())

            local connection: RBXScriptConnection
            connection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
                if input.UserInputState ~= Enum.UserInputState.Begin and input.UserInputState ~= Enum.UserInputState.Change then
                    connection:Disconnect()
                    local newAction = currentAction()
                    if newAction and newAction.update == update then
                        tryUpdate()
                        currentAction(nil)
                    end
                end
            end)

            currentAction({
                gizmo = gizmo,
                update = update,

                currentState = vide.source(initialState),
                placement = vide.source({
                    direction = Vector3.zero,
                } :: types.LightPlacement),
            })
            tryUpdate()
        end
    end))

    vide.effect(function()
        local action = currentAction()
        if not action then return end

        local gizmo = action.gizmo
        if gizmo then
            local gizmoInstance = vide.untrack(function()
                return gizmo(action.currentState, action.placement) :: GuiObject
            end)
            gizmoInstance.Parent = CoreGui

            vide.cleanup(gizmoInstance)
        end

        vide.cleanup(UserInputService.InputChanged:Connect(function(input)
            if not on() then return end

            if input.UserInputType == Enum.UserInputType.MouseMovement then
                tryUpdate()
            end
        end))

        local camera = workspace.CurrentCamera
        if camera then
            vide.cleanup(camera:GetPropertyChangedSignal("CFrame"):Connect(function(input)
                if not on() then return end

                tryUpdate()
            end))
        end
    end)

    return function()
        return not not currentAction()
    end
end
