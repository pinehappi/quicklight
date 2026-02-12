local vide = require(script.Parent.Parent.Parent.Packages.vide)
export type Props = {
    image: string,
    color: Color3 | () -> Color3,
    size: number | () -> number,
}

return function(props: Props)
    return vide.create "ImageLabel" {
        BackgroundTransparency = 1,
        Image = props.image,
        ImageColor3 = props.color,
        Size = function()
            return UDim2.fromOffset(vide.read(props.size), vide.read(props.size))
        end,
    }
end
