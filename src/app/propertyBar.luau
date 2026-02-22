local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local vide = require(script.Parent.Parent.Packages.vide)
local Properties = require(script.Parent.Parent.Properties)
local switchClass = require(script.Parent.Parent.switchClass)
local buttonGroup = require(script.Parent.base.buttonGroup)
local theme = require(script.Parent.theme)
local checkbox = require(script.Parent.base.checkbox)
local colorInput = require(script.Parent.base.colorInput)
local numberbox = require(script.Parent.base.numberbox)
local slider = require(script.Parent.base.slider)

local function input(props: {
    name: string,
    spec: Properties.PropertySpec,
    value: () -> any,
    valueChanged: (newValue: any, isNewSession: boolean) -> (),
    native: any,
})
    local spec = props.spec

    -- session state
    local hasSessionStarted = false
    local hasSessionUpdated = false
    
    local function handleSessionBegan()
        hasSessionStarted = true
        hasSessionUpdated = false
    end

    local function handleSessionEnded()
        hasSessionStarted = false
        hasSessionUpdated = false
    end

    local function handleChanged(newValue: any)
        props.valueChanged(newValue, (not hasSessionStarted) or (not hasSessionUpdated))
        if hasSessionStarted then
            hasSessionUpdated = true
        end
    end

    return vide.create "Frame" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,

        props.native,

        vide.create "UIListLayout" {
            Padding = theme.padding.md,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        },

        vide.create "TextLabel" {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            TextSize = theme.textSize.base,
            FontFace = theme.font.default,
            Text = props.name,
            TextColor3 = theme.surface0.foreground,

            vide.create "UIPadding" {
                PaddingLeft = theme.padding.sm,
                PaddingRight = theme.padding.sm,
                PaddingTop = theme.padding.sm,
                PaddingBottom = theme.padding.sm,
            },
        },

        if spec.type == "number" then
            {
                numberbox {
                    value = props.value,
                    valueChanged = handleChanged,
                    focused = handleSessionBegan,
                    focusLost = handleSessionEnded,
                    native = {
                        Size = UDim2.fromOffset(50, 0)
                    }
                },
                slider {
                    value = props.value,
                    valueChanged = handleChanged,
                    min = spec.min,
                    max = spec.max,
                    step = spec.step,
                    dragBegan = handleSessionBegan,
                    dragEnded = handleSessionEnded,
                    native = {
                        Size = UDim2.fromOffset(50, 12)
                    }
                },
            }
        elseif spec.type == "Color3" then
            colorInput {
                color = props.value,
                colorChanged = handleChanged,
                dragBegan = handleSessionBegan,
                dragEnded = handleSessionEnded,
                focused = handleSessionBegan,
                focusLost = handleSessionEnded,
            }
        elseif spec.type == "boolean" then
            checkbox {
                checked = props.value,
                checkedChanged = handleChanged,
            }
        else
            nil
    }
end

local function propertyInput(props: {
    object: () -> any,
    property: string,
    native: any,
})
    local spec = Properties.getSpec(props.property)
    local value = vide.source(nil :: any)

    vide.effect(function()
        local object = props.object()
        value(object[props.property])
        vide.cleanup(object:GetPropertyChangedSignal(props.property):Connect(function()
            value(object[props.property])
        end))
    end)

    return input {
        name = props.property,
        spec = spec,
        native = props.native,

        value = value,
        valueChanged = function(newValue, isNewSession)
            local object = props.object()
            if not object then return end

            local recording = ChangeHistoryService:TryBeginRecording("set " .. props.property)
            if not recording then
                warn("Failed to begin recording for " .. props.property)
                -- Still apply the change
                object[props.property] = newValue
                return
            end
            
            object[props.property] = newValue
            
            local operation = isNewSession and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Append
            ChangeHistoryService:FinishRecording(recording, operation)
        end,
    }
end

export type Props = {
    objectInfo: () -> Properties.ObjectInfo,
    distance: () -> number,
    distanceChanged: (number) -> (),
}

return function(props: Props)
    -- fix horrible dependency order race where propertyInput effect runs with the new object before the properties update
    local object = vide.derive(function()
        local object = props.objectInfo()
        return object and object.object
    end)

    local currentClass = vide.derive(function(): string?
        local object = object()
        if object then
            if object:IsA("PointLight") then
                return "point"
            elseif object:IsA("SpotLight") then
                return "spot"
            elseif object:IsA("SurfaceLight") then
                return "surface"
            end
        end
        return nil
    end)
    
    -- making it a button so it sinks input
    return vide.create "TextButton" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = theme.surface0.background,
        TextTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 52),
        AnchorPoint = Vector2.new(0.5, 0),

        vide.create "UICorner" {
            CornerRadius = theme.radius.base,
        },
        
        vide.create "UIStroke" {
            Color = theme.surface0.stroke,
            Thickness = theme.strokeThickness,
        },

        vide.create "UIPadding" {
            PaddingLeft = theme.padding.lg,
            PaddingRight = theme.padding.lg,
            PaddingTop = theme.padding.sm,
            PaddingBottom = theme.padding.sm,
        },

        vide.create "UIListLayout" {
            Padding = theme.padding.md,
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        },

        vide.show(function()
            local object = object()
            return object and object:IsA("Light")
        end, function()
            return {
                buttonGroup {
                    value = currentClass,
                    valueChanged = function(newValue)
                        local object = object()
                        if newValue ~= currentClass() and object and object:IsA("Light") then
                            local newLight = switchClass(object, newValue)
                            if newLight then
                                Selection:Set({newLight})
                            end
                        end
                    end,
                    options = {
                        {
                            value = "point",
                            text = "Point",
                        },
                        {
                            value = "spot",
                            text = "Spot"
                        },
                        {
                            value = "surface",
                            text = "Surface"
                        }
                    },
                    native = {
                        LayoutOrder = -2,
                    },
                },

                input {
                    name = "Distance",
                    spec = { type = "number", min = 0.1, max = 50, step = 0.1 },
                    value = props.distance,
                    valueChanged = function(newDistance, isNewSession)
                        local recording = ChangeHistoryService:TryBeginRecording("set distance")
                        if not recording then
                            warn("Failed to begin recording for distance")
                            props.distanceChanged(newDistance)
                            return
                        end
                        
                        -- this relies on the property implicitly updating the light via an effect
                        -- which is not great but whatever
                        props.distanceChanged(newDistance)
                        
                        local operation = isNewSession and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Append
                        ChangeHistoryService:FinishRecording(recording, operation)
                    end,
                    LayoutOrder = -1,
                }
            }
        end),

        vide.values(function() return props.objectInfo().properties end, function(property, index)
            return propertyInput {
                object = object,
                property = property,
                native = {
                    LayoutOrder = index,
                },
            }
        end),
    }
end
