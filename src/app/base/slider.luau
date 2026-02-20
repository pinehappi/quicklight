local vide = require(script.Parent.Parent.Parent.Packages.vide)
local theme = require(script.Parent.Parent.theme)
local tween = require(script.Parent.Parent.tween)
local useButtonState = require(script.Parent.useButtonState)
local withDrag = require(script.Parent.withDrag)

export type Props = {
    value: () -> number,
    valueChanged: (number) -> (),
    min: number | (() -> number),
    max: number | (() -> number),
    step: number,
    color: Color3 | (() -> Color3?) | nil,
    dragBegan: (() -> ())?,
    dragEnded: (() -> ())?,

    native: any,
}

return function(props: Props)
    local isHovering, isPressing, buttonStateProps = useButtonState()

    local percent = function()
        return math.clamp(
            (props.value() - vide.read(props.min)) / (vide.read(props.max) :: number - vide.read(props.min)),
            0,
            1
        )
    end
    
    local circleSize = tween(function()
        if isPressing() or isHovering() then
            return 10
        else
            return 0
        end
    end, theme.tween.base)

    return vide.create "TextButton" {
        BackgroundTransparency = 1,
        Text = "",
        
        vide.create "Frame" {
            Name = "Bar",
            BackgroundColor3 = theme.input.background.default,
            Size = UDim2.new(1, 0, 0, 6),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),

            vide.create "UIStroke" {
                Color = theme.input.stroke.default,
                Thickness = theme.strokeThickness,
                BorderStrokePosition = Enum.BorderStrokePosition.Inner,
            },

            vide.create "UICorner" {
                CornerRadius = theme.radius.full,
            },

            vide.create "Frame" {
                Name = "Fill",
                Size = function()
                    return UDim2.fromScale(percent(), 1)
                end,
                BackgroundColor3 = props.color or theme.accent.main,

                vide.create "UICorner" {
                    CornerRadius = theme.radius.full,
                },
            },

            vide.create "Frame" {
                Name = "Circle",
                Size = function()
                    return UDim2.fromOffset(circleSize(), circleSize())
                end,
                BackgroundColor3 = props.color or theme.accent.main,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = function()
                    return UDim2.fromScale(percent(), 0.5)
                end,

                vide.create "UICorner" {
                    CornerRadius = theme.radius.full,
                },
            }
        },

        { -- need to nest this to avoid the "nested property" dupe check :(
            withDrag(function(percent: number)
                local unrounded = percent*vide.read(props.max) + (1 - percent)*vide.read(props.min)
                props.valueChanged(math.round(unrounded / props.step) * props.step)
            end, props.dragBegan, props.dragEnded),
        },
        
        buttonStateProps,
        
        props.native,
    }
end
