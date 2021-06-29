local vec3 = require("cpml.modules.vec3")
local vec2 = require("cpml.modules.vec2")
local mat4 = require("cpml.modules.mat4")
local quat = require("cpml.modules.quat")
local intersect = require("cpml.modules.intersect")
require "class"

function love.conf(t) 
    t.console = true
end


--
-- Global Config
--   Resolutions available on the ComputerCraft Advanced Monitor
--
local RESOLUTIONS = {
    default  = vec2(70, 40),
}

--
-- LoveScreen pixel blitter
--  Simulates the ComputerCraft Monitor using Love2D engine
--

Screen = class()
Screen.resolution = vec2(162, 80)

LoveScreen = Screen:extend()
LoveScreen.pixelRatio = vec2(1, 2)
LoveScreen.loveScale = 4

function LoveScreen:init()
    self.pxsize = self.pixelRatio * self.loveScale
    self.loveResolution = self.pxsize * self.resolution
    love.window.setMode(self.loveResolution.x, self.loveResolution.y, {})
end

function LoveScreen:setPx(x, y, r, g, b)
    -- Expects r/g/b are 0-1.0
    local s = self.pxsize
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", x * s.x, y * s.y, s.x, s.y)
end


--
-- Main part of the program
--


local INFINITY = tonumber("inf")



--
-- Run in Simulator
--

local loveScreen = LoveScreen:new()

-- Ray class
Ray = class()

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

-- Shapes

Shape = class()

function Shape:init()
    self.colour = vec3(1, 1, 1)
end

function Shape:with_colour(new_colour)
    if new_colour ~= nil then
        self.colour = new_colour
    end
    return self
end

Sphere = Shape:extend()

function Sphere:init(position, radius)
    self.super.init(self)
    self.position = position
    self.radius = radius
end

function Sphere:intersect_ray(ray)
    return intersect.ray_sphere(ray, self)
end

InfinitePlane = Shape:extend()

function InfinitePlane:init(position, normal)
    self.super.init(self)
    self.position = position
    self.normal = normal
end

function InfinitePlane:intersect_ray(ray)
    return intersect.ray_plane(ray, self)
end



-- Draw Parameters
local screen = loveScreen
local resolution = vec2(162, 80)
        
local clampMin = 1
local clampMax = 32

local cameraYaw = 0
local cameraPitch = 0
local cameraPos = vec3(0, 0, 0) -- vec3(0, -2, 0)
local cameraRotSpeed = math.pi / 32
local viewRotMatrix = mat4()
local viewTransMatrix = mat4()

local function updateViewMatrix()
    local yawRot = quat.from_angle_axis(cameraYaw, vec3(0, -1, 0))
    local pitchRot = quat.from_angle_axis(cameraPitch, vec3(1, 0, 0))
    viewRotMatrix = yawRot * pitchRot
    viewTransMatrix:translate(mat4.identity(viewTransMatrix), cameraPos)
end

updateViewMatrix()

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

-- Scene Objects
-- X left-right negative-positive
-- Y top-bottom negative-positive
-- Z front-back negative-positive
local lightPosition = vec3(100.0, -100.0, 100.0)

local objects = {
    InfinitePlane(vec3(0, 1, 0), vec3(0, -1, 0)):with_colour(vec3(0, 1, 0)),
    Sphere(vec3(-2, 0, -5), 1):with_colour(vec3(1, 0, 0)),
    Sphere(vec3(1,  0, -8), 1):with_colour(vec3(0, 0, 1)),
    Sphere(vec3(-4, 0, -5), 1),
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

function love.draw()
    love.graphics.setColor(1, 1,  1)
    love.graphics.print("Hello, world!", 400, 300)

    local bgTopColour = vec3(0, 0.1, 0.5) * 2
    local bgBottomColour = vec3(0, 0.7, 1.0) * 2
    local bgGradient = bgTopColour + (bgBottomColour - bgTopColour)

    
    for y=0,resolution.y do
        for x=0,resolution.x do
            
            -- Shoot the ray in the scene and search for intersection
            local ray = Ray:fromPixel(vec2(x, y), resolution)
            ray.direction = viewRotMatrix * ray.direction
            ray.position = cameraPos

            local point, dist, object = castRay(ray, objects)

            if point then
                -- Cast ray to light
                local rayToLight = Ray(point + vec3(0, -0.0001, 0), lightPosition - point)

                local inShadow, _, _ = castRay(rayToLight, objects)

                -- local colourScale = math.min(1.0, 1 - ((dist - clampMin) / (clampMax - clampMin)))
                local rgb = object.colour
                if inShadow ~= false then
                    rgb = rgb * 0.3 -- Shadow is darker
                end
                screen:setPx(x, y, rgb.x, rgb.y, rgb.z)
            else
                local rgb = vec3.scale(bgGradient, y/resolution.y)
                screen:setPx(x, y, rgb.x, rgb.y, rgb.z)
            end

        end
    end
end