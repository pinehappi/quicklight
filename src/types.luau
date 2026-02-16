local result = require(script.Parent.result)
export type Cursor =
    | "crosshairs"
    | "default"
    | "openHand"
    | "grab"
    | "point"
    | "invisible"
    | "NS"
    | "EW"
    | "NESW"
    | "NWSE"
    | nil

-- Tools

export type ToolState = {
	sunDirection: Vector3, 
	moonDirection: Vector3, 
	cameraPosition: Vector3,
	cameraDirection: Vector3,
    -- position in 3d space the mouse is on
	mousePosition: Vector3,
    -- direction of mouse ray from the camera
	mouseDirection: Vector3,
    -- normal of the face the mouse is on. `nil` if no face.
    mouseNormal: Vector3?,
}

export type LightInfo = {
    direction: Vector3,
    -- for object/pen
    position: Vector3?,
    angle: number?,
}

export type Tool<GizmoExtra = nil> = {
    run: (initial: ToolState, object: LightSourceObject?)
        -> (current: ToolState)
        -> result.Result<{lightInfo: LightInfo, gizmoExtra: GizmoExtra}, string>,
    gizmo: ((initial: ToolState, current: () -> ToolState, lightInfo: () -> LightInfo, gizmoExtra: () -> GizmoExtra?) -> unknown)?,
}

export type LightSourceObject = {
    container: Attachment | BasePart,
    light: Light,
}

return {}