local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local vide = require(script.Parent.Parent.Packages.vide)
local startTool = require(script.Parent.Parent.startTool)
local types = require(script.Parent.Parent.types)
local updateLightSource = require(script.Parent.Parent.updateLightSource)

--- connects events and wires up tools
--- returns a source for whether a tool is in use
return function(
    on: () -> boolean,
    lightSource: () -> string,
    tool: () -> string?,
    lightSourceObject: () -> types.LightSourceObject?,
    distance: () -> number
)
    local session = vide.source(nil :: {
        active: boolean,
        handle: types.ToolHandle,
        update: startTool.UpdateToolCallback,
        lightSource: string,
        lightSourceObject: types.LightSourceObject?,
        -- sources
        currentState: (() -> types.ToolState) & ((types.ToolState) -> ()),
        placement: (() -> types.LightPlacement) & ((types.LightPlacement) -> ()),
    }?)

    local function tryUpdate()
        local currentSession = session()
        if currentSession then
            local result = currentSession.update(distance())
            if result.kind == "success" then
                currentSession.currentState(result.data.currentState)
                currentSession.placement(result.data.placement)
            end
        end
    end

    vide.cleanup(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if not on() then return end

        local tool = tool()
        if not tool then return end

        local prevSession = session()
        if prevSession and prevSession.active then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 and tool then
            local lightSource = lightSource()
            local lightSourceObject = lightSourceObject()
            local initialState, handle, update = startTool(tool, lightSource, lightSourceObject)

            local connection: RBXScriptConnection
            connection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
                if input.UserInputState ~= Enum.UserInputState.Begin and input.UserInputState ~= Enum.UserInputState.Change then
                    connection:Disconnect()
                    local newSession = session()
                    if newSession and newSession.update == update then
                        tryUpdate()
                        
                        if newSession then
                            newSession.active = false
                            session(newSession)
                        end
                    end
                end
            end)

            session({
                active = true,
                handle = handle,
                update = update,

                lightSource = lightSource,
                lightSourceObject = lightSourceObject,

                currentState = vide.source(initialState),
                placement = vide.source({
                    direction = Vector3.zero,
                } :: types.LightPlacement),
            })
            tryUpdate()
        end
    end))

    vide.effect(function()
        local currentSession = session()
        if (not currentSession) or (not currentSession.active) then return end

        local gizmo = currentSession.handle.gizmo
        if gizmo then
            local gizmoInstance = vide.untrack(function()
                return gizmo(currentSession.currentState, currentSession.placement) :: GuiObject
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

    vide.effect(function()
        local distance = distance() -- for tracking

        local currentSession = vide.untrack(session)
        if currentSession then
            local lightSource = vide.untrack(lightSource)
            local lightSourceObject = vide.untrack(lightSourceObject)
            
            -- make sure it's the same object
            if lightSource == currentSession.lightSource
                and lightSourceObject
                and currentSession.lightSourceObject
                and (lightSourceObject.container == currentSession.lightSourceObject.container)
                and (lightSourceObject.light == currentSession.lightSourceObject.light)
            then
                local result = currentSession.handle.update(vide.untrack(currentSession.currentState), distance, lightSource)
                if result.kind == "success" then
                    updateLightSource(
                        currentSession.lightSource,
                        result.data,
                        vide.untrack(currentSession.currentState),
                        currentSession.lightSourceObject,
                        distance
                    )
                end
            end
        end
    end)

    return function()
        local currentSession = session()
        return not not (currentSession and currentSession.active)
    end
end
