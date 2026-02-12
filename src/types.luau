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

export type ToolUpdate<T> = T & {
    direction: Vector3,
}

export type Tool<T = {}> = {
	update: (LightSource, initial: ToolState, current: ToolState) -> result.Result<ToolUpdate<T>, string>,
    gizmo: ((initial: ToolState, current: () -> ToolState, direction: () -> Vector3) -> unknown)?,
}

-- Light sources

export type LightSource = {
    new: () -> LightSource,
    updateDirection: (
        LightSource,
		placeState: ToolState,
		direction: Vector3,
		position: Vector3?,
		angle: number? -- Angle for light objects
    ) -> (),
    getFilter: (LightSource) -> {Instance}?,
    destroy: (LightSource) -> (),
}

return {}