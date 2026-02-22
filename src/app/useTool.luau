local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Selection = game:GetService("Selection")
local UserInputService = game:GetService("UserInputService")
local vide = require(script.Parent.Parent.Packages.vide)
local tools = require(script.Parent.Parent.tools)
local types = require(script.Parent.Parent.types)
local updateLightSource = require(script.Parent.Parent.updateLightSource)

local function getToolState(ignore: {any}?): types.ToolState
    local camera = workspace.CurrentCamera
    if not workspace.CurrentCamera then
        -- how?!?!
        return {
            sunDirection = Lighting:GetSunDirection(),
            moonDirection = Lighting:GetMoonDirection(),
            cameraPosition = Vector3.zero,
            cameraDirection = Vector3.zero,
            mousePosition = Vector3.zero,
            mouseDirection = Vector3.zero,
            normal = nil,
        }
    end
    
    local mouseLocation = UserInputService:GetMouseLocation()
    local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y, 1)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    if ignore then
        params.FilterDescendantsInstances = ignore
    end
    local result = workspace:Raycast(camera.CFrame.Position, ray.Direction * 10000, params)
	return {
		sunDirection = Lighting:GetSunDirection(),
		moonDirection = Lighting:GetMoonDirection(),
		cameraPosition = workspace.CurrentCamera.CFrame.Position,
		cameraDirection = workspace.CurrentCamera.CFrame.LookVector,
		mousePosition = result and result.Position or camera.CFrame.Position + ray.Direction * 10000,
		mouseDirection = ray.Direction,
        mouseNormal = result and result.Normal,
	}
end

--- returns the light source object and if it committed a ChangeHistoryService recording
local function createLightSourceObject(): (types.LightSourceObject, boolean)
    local recording = ChangeHistoryService:TryBeginRecording("create light")

    local container = Instance.new("Part")
    container.Size = Vector3.new(1, 1, 1)
    container.Transparency = 0
    container.Material = Enum.Material.Neon
    container.Color = Color3.new(1, 1, 1)
    container.TopSurface = Enum.SurfaceType.Smooth
    container.BottomSurface = Enum.SurfaceType.Smooth
    container.Anchored = true
    container.CanCollide = false
    container.Name = "LightPart"
    container.Parent = workspace

    local light = Instance.new("SpotLight")
    light.Color = Color3.new(1, 1, 1)
    light.Brightness = 1
    light.Parent = container
    
    if recording then
        ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
    end
    
    Selection:Set({light})
    
    return {
        light = light,
        container = container,
    }, not not container
end

--- connects events and wires up tools
--- returns a source for whether a tool is in use and and error if any
return function(props: {
    on: () -> boolean,
    tool: () -> string?,
    lightSource: () -> string,
    lightSourceObject: () -> types.LightSourceObject?,
    distance: () -> number,
    createLightsEnabled: () -> boolean,
})
    local on, tool, lightSource, lightSourceObject, distance, createLightsEnabled =
        props.on, props.tool, props.lightSource, props.lightSourceObject, props.distance, props.createLightsEnabled
    
    local session = vide.source(nil :: {
        active: boolean,
        hasCommitted: boolean,
        tool: string,
        lightSource: string,
        lightSourceObject: types.LightSourceObject?,
        -- if it has committed in ChangeHistoryService
        handle: types.ToolHandle,
        -- sources
        currentState: (() -> types.ToolState) & ((types.ToolState) -> ()),
        placement: (() -> types.LightPlacement) & ((types.LightPlacement) -> ()),
    }?)
    local toolError = vide.source(nil :: string?)

    local function tryUpdate()
        local session = session()
        if session then
            if session.lightSource == "object" and (not session.lightSourceObject) then
                toolError("Need to select a light or hold [Shift] to create one!")
                return
            end
            
            local distance = distance()
            local currentState = getToolState({session.lightSourceObject and session.lightSourceObject.container})
            local updateResult = session.handle.update(currentState, distance, session.lightSource)

            if updateResult.kind == "success" then
                local recording = ChangeHistoryService:TryBeginRecording(`{session.lightSource} {session.tool}`)
                if not recording then return end
                
                local success, err = pcall(function()
                    updateLightSource(session.lightSource, updateResult.data, currentState, session.lightSourceObject, distance)
                end)
                    
                if success then
                    if session.hasCommitted then
                        ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Append)
                    else
                        session.hasCommitted = true
                        ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
                    end
                else
                    warn("Light placement failed: " .. err)
                    ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel)
                end

                -- update sources
                session.currentState(currentState)
                session.placement(updateResult.data)
            else
                toolError(updateResult.error)
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
            local hasCommitted = false
            if lightSource == "object" and createLightsEnabled() then
                lightSourceObject, hasCommitted = createLightSourceObject()
            end

            local initialState = getToolState({lightSourceObject and lightSourceObject.container})
            local handle = tools[tool](initialState, lightSourceObject)
            
            local newSession = {
                active = true,
                hasCommitted = hasCommitted,
                tool = tool,
                lightSource = lightSource,
                lightSourceObject = lightSourceObject,
                handle = handle,
                currentState = vide.source(initialState),
                placement = vide.source({
                    direction = Vector3.zero,
                } :: types.LightPlacement),
            }

            local connection: RBXScriptConnection
            connection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
                if input.UserInputState ~= Enum.UserInputState.Begin and input.UserInputState ~= Enum.UserInputState.Change then
                    connection:Disconnect()
                    local gotSession = session()
                    -- check it's the same session
                    if gotSession and gotSession.handle == newSession.handle then
                        tryUpdate()
                        
                        if gotSession then
                            gotSession.active = false
                            session(gotSession)
                            toolError(nil)
                        end
                    end
                end
            end)

            session(newSession)
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
        local distance = distance()

        local session = vide.untrack(session)
        if session then
            local lightSource = vide.untrack(lightSource)
            local lightSourceObject = vide.untrack(lightSourceObject)
            
            -- make sure it's the same object
            if lightSource == session.lightSource
                and lightSourceObject
                and session.lightSourceObject
                and (lightSourceObject.container == session.lightSourceObject.container)
                and (lightSourceObject.light == session.lightSourceObject.light)
            then
                local result = session.handle.update(vide.untrack(session.currentState), distance, lightSource)
                if result.kind == "success" then
                    updateLightSource(
                        session.lightSource,
                        result.data,
                        vide.untrack(session.currentState),
                        session.lightSourceObject,
                        distance
                    )
                end
            end
        end
    end)

    return function()
        local currentSession = session()
        return not not (currentSession and currentSession.active)
    end, toolError
end
