local TweenService = game:GetService("TweenService")
local vide = require(script.Parent.Parent.Packages.vide)

local function lerp<T>(a: T, b: T, alpha: number): T
    if type(a) == "number" then
        return a + (b - a) * alpha
    elseif typeof(a) == "Color3" then
        return a:Lerp(b, alpha)
    else
        error(`invalid tween type: {typeof(a)}`)
    end
end

return function<T>(source: () -> T, tweenInfo: () -> TweenInfo): () -> T
    local value = vide.source(source())
    
    vide.effect(function()
        local target = source()
        vide.cleanup(task.spawn(function()
            local startTime = os.clock()
            local initial = vide.untrack(value)
            local tweenInfo = vide.untrack(tweenInfo)
            while true do
                local delta = os.clock() - startTime
                local alpha = math.min(1, delta / tweenInfo.Time)
                local ratio = TweenService:GetValue(alpha, tweenInfo.EasingStyle, tweenInfo.EasingDirection)

                value(lerp(initial, target, ratio))

                if alpha >= 1 then
                    break
                end

                task.wait()
            end
        end))
    end)

    return value
end
