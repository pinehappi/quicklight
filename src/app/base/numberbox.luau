local textbox = require(script.Parent.textbox)

export type Props = {
    value: () -> number,
    valueChanged: (number) -> (),
    focused: (() -> ())?,
    focusLost: (() -> ())?,
    
    native: any,
}

return function(props: Props)
    return textbox {
        text = function()
            return tostring(math.floor(props.value() * 1000) / 1000)
        end,
        textChanged = function(text)
            local number = tonumber(text)
            if number then
                props.valueChanged(number)
            end
        end,
        focused = props.focused,
        focusLost = props.focusLost,
        native = props.native,
    }
end
