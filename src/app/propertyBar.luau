local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReflectionService = game:GetService("ReflectionService")
local Selection = game:GetService("Selection")
local vide = require(script.Parent.Parent.Packages.vide)
local Properties = require(script.Parent.Parent.core.Properties)
local buttonGroup = require(script.Parent.base.buttonGroup)
local theme = require(script.Parent.theme)
local checkbox = require(script.Parent.base.checkbox)
local colorInput = require(script.Parent.base.colorInput)
local numberbox = require(script.Parent.base.numberbox)
local slider = require(script.Parent.base.slider)

local function propertyInput(props: {
    object: () -> any,
    property: string,
    order: number | () -> number,
})
    local object = props.object
    if not object then return nil end

    local spec = Properties.getSpec(props.property)
    local value = vide.source(nil :: any)

    vide.effect(function()
        local object = props.object()
        value(object[props.property])
        vide.cleanup(object:GetPropertyChangedSignal(props.property):Connect(function()
            value(object[props.property])
        end))
    end)

    -- session state
    local isRecordingSession = false
    local hasCommittedInSession = false
    
    local function startSession()
        isRecordingSession = true
        hasCommittedInSession = false
    end

    local function endSession()
        isRecordingSession = false
        hasCommittedInSession = false
    end

    local function updateProperty(newValue: any)
        local obj = props.object()
        if not obj then return end
        
        local recording = ChangeHistoryService:TryBeginRecording("set " .. props.property)
        if not recording then
            warn("Failed to begin recording for " .. props.property)
            -- Still apply the change
            obj[props.property] = newValue
            return
        end
        
        obj[props.property] = newValue
        
        local operation = Enum.FinishRecordingOperation.Commit
        if isRecordingSession and hasCommittedInSession then
            operation = Enum.FinishRecordingOperation.Append
        end
        
        ChangeHistoryService:FinishRecording(recording, operation)
        
        if isRecordingSession then
            hasCommittedInSession = true
        end
    end

    return vide.create "Frame" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        LayoutOrder = props.order,

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
            Text = props.property,
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
                    value = value,
                    valueChanged = updateProperty,
                    focused = startSession,
                    focusLost = endSession,
                    native = {
                        Size = UDim2.fromOffset(50, 0)
                    }
                },
                slider {
                    value = value,
                    valueChanged = updateProperty,
                    min = spec.min,
                    max = spec.max,
                    step = spec.step,
                    dragBegan = startSession,
                    dragEnded = endSession,
                    native = {
                        Size = UDim2.fromOffset(50, 12)
                    }
                },
            }
        elseif spec.type == "Color3" then
            colorInput {
                color = value,
                colorChanged = updateProperty,
                dragBegan = startSession,
                dragEnded = endSession,
                focused = startSession,
                focusLost = endSession,
            }
        elseif spec.type == "boolean" then
            checkbox {
                checked = value,
                checkedChanged = updateProperty,
            }
        else
            nil
    }
end

type LightShortClassName = "point" | "spot" | "surface"
local longClassNames: {[LightShortClassName]: string} = {
    point = "PointLight",
    spot = "SpotLight",
    surface = "SurfaceLight",
}
local function switchClass(light: Light, shortClassName: LightShortClassName): Light?
    local recording = ChangeHistoryService:TryBeginRecording("convert light")
    if not recording then return end
    
    local longClassName = longClassNames[shortClassName]
    local oldProperties = ReflectionService:GetPropertiesOfClass(light.ClassName, {
        ExcludeDisplay = true,
    })
    local newProperties = ReflectionService:GetPropertiesOfClass(longClassName, {
        ExcludeDisplay = true,
    })

    local sharedProperties: {[string]: boolean} = {}
    
    for _, property in oldProperties do
        if sharedProperties[property.Name] == nil then
            sharedProperties[property.Name] = false
        end
    end
    
    for _, property in newProperties do
        if sharedProperties[property.Name] == false then
            sharedProperties[property.Name] = true
        end
    end

    local newLight = Instance.new(longClassName) :: Light

    for name, isShared in sharedProperties do
        if not isShared then continue end
        pcall(function()
            (newLight :: any)[name] = (light :: any)[name]
        end)
    end

    -- convert class name
    if newLight.Name == light.ClassName then
        newLight.Name = longClassName
    end

    light.Parent = nil

    ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)

    return newLight
end

export type Props = {
    objectInfo: () -> Properties.ObjectInfo,
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
            return buttonGroup {
                value = currentClass,
                valueChanged = function(newValue)
                    local object = object()
                    if newValue ~= currentClass() and object and object:IsA("Light") then
                        local newLight = switchClass(object, newValue :: LightShortClassName)
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
            }
        end),

        vide.values(function() return props.objectInfo().properties end, function(property, index)
            return propertyInput {
                object = object,
                property = property,
                order = index,
            }
        end),
    }
end
