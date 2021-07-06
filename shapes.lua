
--
-- Shapes
--

Shape = Class:extend()

function Shape:init()
    self.colour = colours.white
    self.shadowColour = colours.gray
end

function Shape:with_colour(colour, shadowColour)
    if colour ~= nil then
        self.colour = colour
    end
    if shadowColour ~= nil then
        self.shadowColour = shadowColour
    end
    return self
end


function Shape:pointColour(point, lights, objects)
    if pointLightSource(point, lights, objects, {self}) ~= nil then
        return self.colour
    else
        return self.shadowColour
    end
end

--
-- Sphere
--

Sphere = Shape:extend()

function Sphere:init(position, radius)
    self.super.init(self)
    self.position = position
    self.radius = radius
end

function Sphere:intersect_ray(ray)
    return intersect.ray_sphere(ray, self)
end

--
-- Plane
--

Plane = Shape:extend()

function Plane:init(position, normal)
    self.super.init(self)
    self.position = position
    self.normal = normal
end

function Plane:intersect_ray(ray)
    return intersect.ray_plane(ray, self)
end


AABB = Shape:extend()