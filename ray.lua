
INFINITY = 0xFFFFFFFFFF -- eh, close enough

-- Ray class
Ray = Class:extend()

function Ray:init(pos, dir)
    self.position = pos
    self.direction = dir
end

function Ray:fromPixel(pixel, resolution)
    local posX = ((pixel.x / resolution.x) - 0.5)
    local posY = ((pixel.y / resolution.y) - 0.5)
    return self(vec3(0, 0, 0), vec3(posX, posY, -1):normalize())
end

function Ray.__tostring(self)
    return "Ray(" .. tostring(self.position) .. "," .. tostring(self.direction) .. ")"
end

-- Handy Functions
function pointCanSeePoint(fromPoint, toPoint, objects, ignoreObjects)
    local shouldIgnoreObject = {}
    for _, obj in pairs(ignoreObjects) do
        shouldIgnoreObject[obj] = true
    end

    local ray = Ray(fromPoint, (toPoint - fromPoint):normalize())
    for _, object in pairs(objects) do
        if not shouldIgnoreObject[object] then
            local point, _ = object:intersect_ray(ray)
            if point then return false end
        end
    end
    return true
end


function pointLightSource(point, lights, objects, ignoreObjects)
    local closestLight = nil
    local closestDist = INFINITY
    for _, light in pairs(lights) do
        local lightPos = light.position
        if pointCanSeePoint(point, lightPos, objects, ignoreObjects) then
            local dist = vec3.dist(point, lightPos)
            if dist < closestDist then
                closestLight = light
                closestDist = dist
            end
        end
    end
    return closestLight, closestDist
end