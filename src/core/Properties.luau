local Lighting = game:GetService("Lighting")
local types = require(script.Parent.Parent.types)

export type PropertySpec =
    | { type: "boolean" }
    | { type: "number", min: number, max: number, step: number }
    | { type: "Color3" }

export type ObjectInfo = {
    object: any,
    properties: {string},
}

local specs: {[string]: PropertySpec} = {
    -- Shared
    Brightness = { type = "number", min = 0, max = 5, step = 0.1 },
    
    -- Lighting
    Ambient = { type = "Color3" },
    OutdoorAmbient = { type = "Color3" },

    -- Object
    Color = { type = "Color3" },
    Range = { type = "number", min = 0, max = 120, step = 0.25 },
    Shadows = { type = "boolean" },
    Angle = { type = "number", min = 0, max = 180, step = 0.5 },
}

return {
    getSpec = function(property: string)
        return specs[property]
    end,
    getObjectInfo = function(lightSource: string, lightSourceObject: types.LightSourceObject?): ObjectInfo?
        if lightSource == "sun" or lightSource == "moon" then
            return {
                object = Lighting,
                properties = { "Brightness", "Ambient", "OutdoorAmbient" },
            }
        elseif lightSource == "object" and lightSourceObject then
            local properties: {string} = {
                "Color",
                "Brightness",
                "Range",
                --"Shadows",
            }

            --[[if lightSourceObject.light:IsA("SpotLight") or lightSourceObject.light:IsA("SurfaceLight") then
                table.insert(properties, 3, "Angle")
            end]]

            return {
                object = lightSourceObject.light,
                properties = properties,
            }
        else
            return nil
        end
    end,
}