local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local vide = require(script.Parent.Parent.Packages.vide)
local placers = require(script.Parent.Parent.placers)
local types = require(script.Parent.Parent.types)
local updateSkyFromDirection = require(script.Parent.Parent.utils.updateSkyFromDirection)
local toolbar = require(script.Parent.toolbar)

local function getPlaceState(): types.PlaceState
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
    local result = workspace:Raycast(camera.CFrame.Position, ray.Direction * 10000)
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

local function updateLightSource(name: string, direction: Vector3)
    if name == "sun" then
        updateSkyFromDirection(direction, -1)
    else
        updateSkyFromDirection(direction, 1)
    end
end

local function usePlacerControls(on: () -> boolean, activeLightSource: () -> string, activePlacer: () -> string?)
    local currentPlacement = vide.source(nil :: {
        placer: string,
        initial: types.PlaceState,
        current: (() -> types.PlaceState) & ((types.PlaceState) -> types.PlaceState),
        direction: (() -> Vector3) & ((Vector3) -> Vector3),
    }?)

    local function updatePlace(commit: boolean)
        local placement = currentPlacement()
        if not placement then return end
        
        local placer = placers[placement.placer]
        local currentPlaceState = getPlaceState()
        local result = placer.update({} :: any, placement.initial, currentPlaceState)
        placement.current(currentPlaceState)

        if result.kind == "success" then
            local recording = commit and ChangeHistoryService:TryBeginRecording(`{activeLightSource()} {activePlacer()}`)
            if commit and not recording then return end

            placement.direction(result.data.direction)
            
            local success, err = pcall(function()
                updateLightSource(activeLightSource(), result.data.direction)
            end)
                
            if success then
                if recording then
                    ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
                end
            else
                warn("Light placement failed: " .. err)
                if recording then
                    ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel)
                end
            end
        end
    end

    vide.cleanup(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if not on() then return end

        local placer = activePlacer()
        if not placer then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local connection: RBXScriptConnection
            connection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
                if input.UserInputState ~= Enum.UserInputState.Begin and input.UserInputState ~= Enum.UserInputState.Change then
                    connection:Disconnect()
                    updatePlace(true)
                    currentPlacement(nil)
                end
            end)

            local placeState = getPlaceState()
            currentPlacement({
                placer = placer,
                initial = placeState,
                -- TODO: does this get gc'ed?
                current = vide.source(placeState),
                direction = vide.source(Vector3.new(0, 0, 0)),
            })
            updatePlace(false)
        end
    end))

    vide.effect(function()
        local placement = currentPlacement()
        if placement then
            local placer = placers[placement.placer]
            if placer.gizmo then
                local gizmo = vide.untrack(function()
                    return placer.gizmo(placement.initial, placement.current, placement.direction) :: GuiObject
                end)
                gizmo.Parent = CoreGui

                vide.cleanup(gizmo)
            end

            vide.cleanup(UserInputService.InputChanged:Connect(function(input)
                if not on() then return end

                if input.UserInputType == Enum.UserInputType.MouseMovement and currentPlacement() then
                    updatePlace(false)
                end
            end))

            local camera = workspace.CurrentCamera
            if camera then
                vide.cleanup(camera:GetPropertyChangedSignal("CFrame"):Connect(function(input)
                    if not on() then return end

                    updatePlace(false)
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

export type Props = {
    on: () -> boolean,

    activePlacer: () -> string?,
    placerSelected: (string?) -> (),
}

return function(props: Props)
    local activeLightSource = vide.source("sun")
    local lightSources = vide.source({
        "sun",
        "moon",
    })
    local placers = vide.source({
        "direct",
        "line",
        "face",
        "bounce",
        "shadow",
    })

    usePlacerControls(props.on, activeLightSource, props.activePlacer)

    vide.effect(function()
        if props.on() then
            vide.cleanup(UserInputService.InputBegan:Connect(function(input, gpe)
                local number = NUMBER_KEYCODES[input.KeyCode]
                if number and placers()[number] and input:IsModifierKeyDown(Enum.ModifierKey.Ctrl) then
                    props.placerSelected(placers()[number])
                elseif input.KeyCode == Enum.KeyCode.Tab then
                    local lightSourceIndex = table.find(lightSources(), activeLightSource())
                    if lightSourceIndex then
                        activeLightSource(lightSources()[lightSourceIndex % #lightSources() + 1])
                    end
                end
            end))
        end
    end)

    return {
        toolbar {
            placers = placers,
            activePlacer = props.activePlacer,
            placerSelected = props.activePlacer,

            lightSources = lightSources,
            activeLightSource = activeLightSource,
            lightSourceSelected = activeLightSource,
        },
    }
end
