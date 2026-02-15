-- canvasgroup that only switches when grouptransparency is on

local vide = require(script.Parent.Parent.Parent.Packages.vide)
export type Props = {
    transparency: () -> number,
    size: UDim2 | (() -> UDim2),
    position: UDim2 | (() -> UDim2),
    child: Instance,
    native: {[string]: unknown}?,
}

return function(props: Props)
    local container = vide.create "Frame" {
        BackgroundTransparency = 1,
        Size = props.size,
        Position = props.position,
        props.native,
    }

    local canvasGroup = vide.create "CanvasGroup" {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        GroupTransparency = props.transparency,
        Visible = function()
            return props.transparency() > 0
        end,
    }

    props.child.Parent = container
    canvasGroup.Parent = container
    
    vide.effect(function()
        if props.transparency() > 0 then
            props.child.Parent = canvasGroup
        else
            props.child.Parent = container
        end
    end)

    return container
end