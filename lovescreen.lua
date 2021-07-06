
--
-- LoveScreen pixel blitter
--  Simulates the ComputerCraft Monitor using Love2D engine
--

local colour_palette = {
    --        {r, g, b}
    [1] =     {0xF0, 0xF0, 0xF0}, -- white
    [2] =     {0xF2, 0xB2, 0x33}, -- orange
    [4] =     {0xE5, 0x7F, 0xD8}, -- magenta
    [8] =     {0x99, 0xB2, 0xF2}, -- light blue
    [16] =    {0xDE, 0xDE, 0x6C}, -- yellow
    [32] =    {0x7F, 0xCC, 0x19}, -- lime
    [64] =    {0xF2, 0xB2, 0xCC}, -- pink
    [128] =   {0x4C, 0x4C, 0x4C}, -- gray
    [256] =   {0x99, 0x99, 0x99}, -- light grey
    [512] =   {0x4C, 0x99, 0xB2}, -- cyan
    [1024] =  {0xB2, 0x66, 0xE5}, -- purple
    [2048] =  {0x33, 0x66, 0xCC}, -- blue
    [4096] =  {0x7F, 0x66, 0x4C}, -- brown
    [8192] =  {0x57, 0xA6, 0x4E}, -- green
    [16384] =  {0xCC, 0x4C, 0x4C}, -- red
    [32768] = {0x19, 0x19, 0x19}, -- black
}

Screen = Class:extend()

Screen.resolution = vec2(162, 80)
Screen.pixelRatio = vec2(1, 2)
Screen.loveScale = 4

function Screen:init()
    self.pxsize = self.pixelRatio * self.loveScale
    self.loveResolution = self.pxsize * self.resolution
    love.window.setMode(self.loveResolution.x, self.loveResolution.y, {})
end

function Screen:setPx(x, y, c)
    local s = self.pxsize
    local v = colour_palette[math.floor(c)]
    --if v == nil then print("c="..tostring(c).." v="..tostring(v)) end
    love.graphics.setColor(v[1] / 255, v[2] / 255, v[3] / 255)
    love.graphics.rectangle("fill", x * s.x, y * s.y, s.x, s.y)
end

function love.conf(t) 
    t.console = true
end