local theme = require(script.Parent.Parent.theme)
local button = require(script.Parent.button)
local icon = require(script.Parent.icon)

export type Props = {
    checked: () -> boolean,
    checkedChanged: (boolean) -> ()
}

return function(props: Props)
    return button {
        icon = function(iconProps)
            return icon {
                image = function()
                    if props.checked() then
                        return "rbxassetid://17650916717"
                    else
                        return ""
                    end
                end,
                color = iconProps.color,
                size = theme.textSize.base,
            }
        end,
        isSelecting = props.checked,
        activated = function()
            props.checkedChanged(not props.checked())
        end,
        padding = {
            left = theme.padding.xs,
            right = theme.padding.xs,
            top = theme.padding.xs,
            bottom = theme.padding.xs,
        },
    }
end
