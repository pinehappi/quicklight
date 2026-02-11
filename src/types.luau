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

-- Placers

export type PlaceState = {
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

export type PlaceUpdate<T> = T & {
    direction: Vector3,
}

export type Placer<T = {}> = {
	update: (LightSource, initial: PlaceState, current: PlaceState) -> result.Result<PlaceUpdate<T>, string>,
    gizmo: ((initial: PlaceState, current: () -> PlaceState, direction: () -> Vector3) -> unknown)?,
}

-- Light sources

export type LightSource = {
    new: () -> LightSource,
    updateDirection: (
        LightSource,
		placeState: PlaceState,
		direction: Vector3,
		position: Vector3?,
		angle: number? -- Angle for light objects
    ) -> (),
    getFilter: (LightSource) -> {Instance}?,
    destroy: (LightSource) -> (),
}

return {}