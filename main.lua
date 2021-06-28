local vec3 = require("cpml.modules.vec3")
local vec2 = require("cpml.modules.vec2")
local mat4 = require("cpml.modules.mat4")
local quat = require("cpml.modules.quat")
local intersect = require("cpml.modules.intersect")

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

local LoveScreen = {
    resolution = vec2(162, 80),
    pixelRatio = vec2(1, 2),
    loveScale = 4,
}

function LoveScreen:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.pxsize = self.pixelRatio * self.loveScale
    self.loveResolution = self.pxsize * self.resolution
    love.window.setMode(self.loveResolution.x, self.loveResolution.y, {})
    return o
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


local function computePrimRay(x, y)
    -- TODO
    return vec3(1, 1, 1)
end

local INFINITY = tonumber("inf")



--
-- Run in Simulator
--

local loveScreen = LoveScreen:new()

local function randostatic()
    for i=0,10000 do
        loveScreen:setPx(math.random(0, loveScreen.resolution.x - 1), math.random(0, loveScreen.resolution.y - 1), math.random(), math.random(), math.random())
    end
end

local Ray = {
    __tostring = function (self)
        return "Ray(" .. tostring(self.position) .. "," .. tostring(self.direction) .. ")"
    end,

    __call = function(self, pos, dir)
        local o = {
            position = pos,
            direction = dir,
        }
        setmetatable(o, self)
        return o
    end,
}
setmetatable(Ray, Ray)

function castRay(pixel, resolution)
    local posX = ((pixel.x / resolution.x) - 0.5)
    local posY = ((pixel.y / resolution.y) - 0.5)
    return Ray(vec3(0, 0, 0), vec3(posX, posY, -1):normalize())
end

local objects = {
    {
        position = vec3(2, 3, -10),
        radius = 0.01
    }
}

local function test()
    local ray = castRay(vec2(40, 50), vec2(100, 100))
    print(ray)

    local point, dist = intersect.ray_sphere(ray, {
        position = vec3(0, 0, -11),
        radius = 1,
    })

    print(point, dist)
end

test()

function love.draw()
    love.graphics.setColor(1, 1,  1)
    love.graphics.print("Hello, world!", 400, 300)

    local screen = loveScreen
    local resolution = vec2(162, 80)
    
    for y=0,resolution.y do
        for x=0,resolution.x do
            
            -- Shoot the ray in the scene and search for intersection
            local ray = castRay(vec2(x, y), resolution)
            
            -- if x == 22 or y == 71 then
            --     print("ray.direction", ray.direction)
            -- end

            local point, dist = intersect.ray_sphere(ray, {
                position = vec3(-1, 0, -5),
                radius = 0.5,
            })

            local clampMin = 4
            local clampMax = 8
            
            if point then
                local colour = 1 - ((dist - clampMin) / (clampMax - clampMin))
                screen:setPx(x, y, colour, colour, colour)
            end

        end
    end
end