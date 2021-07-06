--
-- ComputerCraft Screen
--  using an Advanced Monitor
--

Screen = Class:extend()
Screen.resolution = vec2(162, 80)

function Screen:init()
    local monitor = peripheral.wrap("left")
    monitor.setTextScale(0.5)
end

function Screen:setPx(x, y, c)
    paintutils.drawPixel(x, y, c)
end