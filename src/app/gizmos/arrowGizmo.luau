local vide = require(script.Parent.Parent.Parent.Packages.vide)
export type Props = {
    color: Color3 | () -> Color3,
    from: Vector3 | () -> Vector3,
    to: Vector3 | () -> Vector3,
    startRadius: number,
    endRadius: number,
    thickness: number,
    endConeRatio: number?,
}

return function(props: Props)
    local terrain = workspace.Terrain
    local lookAt = vide.derive(function()
        return CFrame.lookAt(vide.read(props.from), vide.read(props.to))
    end)
    local delta = vide.derive(function()
        return vide.read(props.to) :: Vector3 - vide.read(props.from) :: Vector3
    end)

    return vide.create "Folder" {
        vide.create "SphereHandleAdornment" {
            Adornee = terrain,
            AlwaysOnTop = true,
            ZIndex = 0,
            Color3 = props.color,
            Radius = props.startRadius,
            CFrame = function()
                return lookAt()
            end,
        },

        vide.create "CylinderHandleAdornment" {
            Adornee = terrain,
            AlwaysOnTop = true,
            ZIndex = 0,
            Radius = props.thickness,
            Color3 = props.color,
            CFrame = function()
                return lookAt() * CFrame.new(0, 0, -delta().Magnitude / 2)
            end,
            Height = function()
                return delta().Magnitude
            end,
        },

        vide.create "ConeHandleAdornment" {
            Adornee = terrain,
            AlwaysOnTop = true,
            ZIndex = 0,
            Color3 = props.color,
            Radius = props.endRadius,
            Height = props.endRadius * (props.endConeRatio or 2),
            CFrame = function()
                return CFrame.new(vide.read(props.to)) * lookAt().Rotation
            end,
        },
    }
end
