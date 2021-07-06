---@diagnostic disable: unused-function
local LOVE_SIM = false

if _G["love"] ~= nil then
    LOVE_SIM = true
end

--
-- Load Libraries
--


if LOVE_SIM then
    require "class"
    require "cpml"
    require "materials"
    require "ray"
    require "lovescreen"
    require "shapes"
else
    os.loadAPI("lib/class")
    Class = class.Class
    
    os.loadAPI("lib/cpml")
    vec3 = cpml.vec3
    vec2 = cpml.vec2
    mat4 = cpml.mat4
    quat = cpml.quat
    intersect = cpml.intersect

    os.loadAPI("ray")
    Ray = ray.Ray
    
    os.loadAPI("shapes")
    Sphere = shapes.Sphere
    Plane = shapes.Plane

    os.loadAPI("ccscreen")
    Screen = ccscreen.Screen

end


--
-- Main part of the program
--


-- Draw Parameters
local cameraYaw = math.pi / 32
local cameraPitch = math.pi / 32
local cameraPos = vec3(0, -2, 8) -- vec3(0, -2, 0)
local cameraRotSpeed = math.pi / 32
local viewRotMatrix = mat4()
local viewTransMatrix = mat4()


-- Call this every time the camera moves
local function updateViewMatrix()
    local yawRot = quat.from_angle_axis(cameraYaw, vec3(0, -1, 0))
    local pitchRot = quat.from_angle_axis(cameraPitch, vec3(1, 0, 0))
    viewRotMatrix = yawRot * pitchRot
    viewTransMatrix:translate(mat4.identity(viewTransMatrix), cameraPos)
end

updateViewMatrix()

-- Scene Objects
-- X left-right negative-positive
-- Y top-bottom negative-positive
-- Z front-back negative-positive
local lightPosition = vec3(100.0, -100.0, 100.0)

local objects = {
    Plane(vec3(0, 1, 0), vec3(0, -1, 0)):with_colour(colours.lime, colours.green),
    Sphere(vec3(-2, -1.1, -5), 1):with_colour(colours.red, colours.brown),
    Sphere(vec3(1,  0, -8), 1):with_colour(colours.blue, colours.cyan),
    Sphere(vec3(2, -1.5, 2), 1),
}

local function castRay(ray, objects)
    local closestPoint = false
    local closestDist = INFINITY
    local closestObject = nil

    for _, object in ipairs(objects) do
        local point, dist = object:intersect_ray(ray)
        if point and dist < closestDist then
            closestDist = dist
            closestPoint = point
            closestObject = object
        end
    end
        
    return closestPoint, closestDist, closestObject
end


local function renderFrame(screen)
    for y=0,screen.resolution.y do
        for x=0,screen.resolution.x do
            
            -- Shoot the ray in the scene and search for intersection
            local ray = Ray:fromPixel(vec2(x, y), screen.resolution)
            ray.direction = viewRotMatrix * ray.direction
            ray.position = cameraPos

            local point, dist, object = castRay(ray, objects)

            local pxColour = colours.black -- background
            if point then
                pxColour = object:pointColour(point, {{position = lightPosition}}, objects)
            end
            screen:setPx(x, y, pxColour)

        end
    end
end

if LOVE_SIM then
local loveScreen = Screen:new()

function love.draw()
    love.graphics.setColor(1, 1,  1)
    love.graphics.print("Hello, world!", 400, 300)
    renderFrame(loveScreen)
end

else -- NOT LOVE_SIM 

local function main()
    local screen = Screen()
    while(true) do
        renderFrame(screen)
        os.sleep(0)
    end
end

main()

end -- END NOT LOVE_SIM

--
-- Movement
--

if LOVE_SIM then

function love.keypressed(key, scancode, isrepeat)
    if scancode == "left" then  cameraYaw   = cameraYaw   - cameraRotSpeed end
    if scancode == "right" then cameraYaw   = cameraYaw   + cameraRotSpeed end
    if scancode == "up" then    cameraPitch = cameraPitch + cameraRotSpeed end
    if scancode == "down" then  cameraPitch = cameraPitch - cameraRotSpeed end
    if scancode == "r" then cameraPos.y = cameraPos.y + 0.5 end
    if scancode == "f" then cameraPos.y = cameraPos.y - 0.5 end
    if scancode == "d" then cameraPos.x = cameraPos.x + 0.5 end
    if scancode == "a" then cameraPos.x = cameraPos.x - 0.5 end
    if scancode == "s" then cameraPos.z = cameraPos.z + 0.5 end
    if scancode == "w" then cameraPos.z = cameraPos.z - 0.5 end
    updateViewMatrix()
end

else -- NOT LOVE_SIM

end -- END NOT LOVE_SIM