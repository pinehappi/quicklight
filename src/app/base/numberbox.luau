local textbox = require(script.Parent.textbox)

export type Props = {
    value: () -> number,
    valueChanged: (number) -> (),
    
    native: any,
}

return function(props: Props)
    return textbox {
        text = function()
            return tostring(props.value())
        end,
        textChanged = function(text)
            local number = tonumber(text)
            if number then
                props.valueChanged(number)
            end
        end,
        native = props.native,
    }
end
