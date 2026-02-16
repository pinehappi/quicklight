local vide = require(script.Parent.Parent.Packages.vide)
local theme = require(script.Parent.Parent.app.theme)
local result = require(script.Parent.Parent.result)
local types = require(script.Parent.Parent.types)

local VERTEX_DISTANCE = 0.1

local function getAverageNormal(normals: {Vector3}): Vector3
	local sum = Vector3.new(0, 0, 0)
	for _, n in normals do
		sum += n
	end
	
	if sum == Vector3.new(0, 0, 0) then
		return Vector3.new(0, 1, 0)
	else
		return sum.Unit
	end
end

local function vecProject(a: Vector3, b: Vector3): Vector3
	return (a:Dot(b) / (b.Magnitude^2)) * b
end

local function vecAngle(a: Vector3, b: Vector3): number
	return math.acos(a:Dot(b) / a.Magnitude / b.Magnitude) 
end

return {
	run = function(_, object)
        local normals: {Vector3} = {}
        local vertices: {Vector3} = {}
        local lastPosition: Vector3? = nil

        local lightInfo: types.LightInfo = {
            direction = Vector3.new(0, 1, 0),
        }

        return function(current)
            local normal = current.mouseNormal
            local isFarEnough = (lastPosition == nil) or ((lastPosition - current.mousePosition).Magnitude > VERTEX_DISTANCE)
            if (not normal) or (not isFarEnough) then
                return result.ok({
                    lightInfo = lightInfo,
                    gizmoExtra = {
                        vertices = vertices,
                    },
                })
            end

            lastPosition = current.mousePosition

            table.insert(normals, normal)
            table.insert(vertices, current.mousePosition)

            local averageNormal = -getAverageNormal(normals)
            local direction = -averageNormal
            
            if object then
                local angle = nil
                local offsetVertices = table.create(#vertices)
                local offset = 5
                for i, v in vertices do
                    table.insert(offsetVertices, v + normals[i]*offset)
                end
                
                local farthestPoint = offsetVertices[1]
                local maxProjectedLengthSquared = -math.huge
                for _, v in offsetVertices do
                    local projectedLengthSquared = vecProject(v, averageNormal).Magnitude^2
                    if projectedLengthSquared > maxProjectedLengthSquared then
                        maxProjectedLengthSquared = projectedLengthSquared
                        farthestPoint = v
                    end
                end
                
                local projectedVerticesSum = Vector3.new(0, 0, 0)
                for _, v in offsetVertices do
                    if v ~= farthestPoint then
                        projectedVerticesSum += v + vecProject((farthestPoint - v), averageNormal)
                    else
                        projectedVerticesSum += v
                    end
                end
                
                local center = projectedVerticesSum / #offsetVertices
                
                local originalCenter = Vector3.new(0, 0, 0)
                for _, v in vertices do
                    originalCenter += v
                end
                originalCenter /= #vertices
                
                local centersDirection = nil
                if center == originalCenter then
                    centersDirection = Vector3.new(0, 1, 0)
                else
                    centersDirection = (originalCenter - center).Unit
                end
                
                for _, v in vertices do
                    local a = 2*math.deg(vecAngle((v - center).Unit, centersDirection))
                    
                    if a == a then -- May be NaN
                        if angle == nil then
                            angle = a
                        elseif a > angle then
                            angle = a
                        end
                    end
                end
                
                lightInfo.angle = angle
                lightInfo.position = center + (direction*-5)
            end

            lightInfo.direction = direction

            return result.ok({
                lightInfo = lightInfo,
                gizmoExtra = {
                    vertices = vertices,
                },
            })
        end
	end,
    gizmo = function(initial, current, lightInfo, gizmoExtra)
        local lines = vide.source({})

        -- meh
        vide.effect(function()
            local gotLines = vide.untrack(lines)
            local gizmoExtra = gizmoExtra()
            local start = #gotLines + 1
            local finish = gizmoExtra and #gizmoExtra.vertices or 1
            if gizmoExtra and finish >= start then
                for i = math.max(2, start), finish do
                    local a = gizmoExtra.vertices[i - 1]
                    local b = gizmoExtra.vertices[i]
                    local delta = b - a
                    local line = Instance.new("CylinderHandleAdornment")
                    line.Adornee = workspace:FindFirstChildOfClass("Terrain")
                    line.AlwaysOnTop = true
                    line.ZIndex = 0
                    line.Height = delta.Magnitude
                    line.CFrame = CFrame.lookAt(a, b) * CFrame.new(0, 0, -0.5*delta.Magnitude)
                    line.Color3 = vide.untrack(theme.accent.faint)
                    line.Radius = 0.2
                    table.insert(gotLines, line)
                end

                lines(gotLines)
            end
        end)
        
        return vide.create "Folder" {
            lines,
        }
    end,
} :: types.Tool<{
    vertices: {Vector3},
}>