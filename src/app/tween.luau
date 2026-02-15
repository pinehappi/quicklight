local TweenService = game:GetService("TweenService")
local vide = require(script.Parent.Parent.Packages.vide)
return function(source: () -> number, style: Enum.EasingStyle, direction: Enum.EasingDirection, duration: number): () -> number
    local value = vide.source(source())
    
    vide.effect(function()
        local target = source()
        vide.cleanup(task.spawn(function()
            local startTime = os.clock()
            local initial = vide.untrack(value)
            while true do
                local delta = os.clock() - startTime
                local alpha = math.min(1, delta / duration)
                local ratio = TweenService:GetValue(alpha, style, direction)

                value(ratio*target + (1-ratio)*initial)

                if alpha >= 1 then
                    break
                end

                task.wait()
            end
        end))
    end)

    return value
end
