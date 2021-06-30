
local private = {}
local floor   = math.floor
local ceil    = math.ceil

function private.round(value, precision)
	if precision then return utils.round(value / precision) * precision end
	return value >= 0 and floor(value+0.5) or ceil(value-0.5)
end

-- Maths

local sqrt    = math.sqrt
local cos     = math.cos
local sin     = math.sin
local tan       = math.tan
local rad       = math.rad
local acos    = math.acos
local atan2   = math.atan2
local min           = math.min
local max           = math.max
local abs     = math.abs
local ceil    = math.ceil
local floor   = math.floor
local log     = math.log
local log2 = log(2)

local frexp = math.frexp or function(x)
	if x == 0 then return 0, 0 end
	local e = floor(log(abs(x)) / log2 + 1)
	return x / 2 ^ e, e
end


local constants = {}

-- same as C's FLT_EPSILON
constants.FLT_EPSILON = 1.19209290e-07

-- same as C's DBL_EPSILON
constants.DBL_EPSILON = 2.2204460492503131e-16

-- used for quaternion.slerp
constants.DOT_THRESHOLD = 0.9995

local DOT_THRESHOLD = constants.DOT_THRESHOLD
local DBL_EPSILON   = constants.DBL_EPSILON

vec3    = {}
vec3_mt = {}
vec2    = {}
vec2_mt = {}
utils = {}
quat          = {}
quat_mt       = {}
mat4      = {}
mat4_mt   = {}
intersect   = {}

-- setmetatable(vec3, vec3_mt)
-- setmetatable(vec2, vec2_mt)
-- setmetatable(quat, quat_mt)
-- setmetatable(mat4, mat4_mt)

-- Order:
-- vec3
-- vec2
-- utils
-- quat
-- mat4
-- intersect

--
-- BLOCK vec3
--

do

-- Private constructor.
local function new(x, y, z)
	return setmetatable({
		x = x or 0,
		y = y or 0,
		z = z or 0
	}, vec3_mt)
end

-- Do the check to see if JIT is enabled. If so use the optimized FFI structs.
local status, ffi
if type(jit) == "table" and jit.status() then
	status, ffi = pcall(require, "ffi")
	if status then
		ffi.cdef "typedef struct { double x, y, z;} cpml_vec3;"
		new = ffi.typeof("cpml_vec3")
	end
end

--- Constants
-- @table vec3
-- @field unit_x X axis of rotation
-- @field unit_y Y axis of rotation
-- @field unit_z Z axis of rotation
-- @field zero Empty vector
vec3.unit_x = new(1, 0, 0)
vec3.unit_y = new(0, 1, 0)
vec3.unit_z = new(0, 0, 1)
vec3.zero   = new(0, 0, 0)

--- The public constructor.
-- @param x Can be of three types: </br>
-- number X component
-- table {x, y, z} or {x=x, y=y, z=z}
-- scalar To fill the vector eg. {x, x, x}
-- @tparam number y Y component
-- @tparam number z Z component
-- @treturn vec3 out
function vec3.new(x, y, z)
	-- number, number, number
	if x and y and z then
		assert(type(x) == "number", "new: Wrong argument type for x (<number> expected)")
		assert(type(y) == "number", "new: Wrong argument type for y (<number> expected)")
		assert(type(z) == "number", "new: Wrong argument type for z (<number> expected)")

		return new(x, y, z)

	-- {x, y, z} or {x=x, y=y, z=z}
	elseif type(x) == "table" or type(x) == "cdata" then -- table in vanilla lua, cdata in luajit
		local xx, yy, zz = x.x or x[1], x.y or x[2], x.z or x[3]
		assert(type(xx) == "number", "new: Wrong argument type for x (<number> expected)")
		assert(type(yy) == "number", "new: Wrong argument type for y (<number> expected)")
		assert(type(zz) == "number", "new: Wrong argument type for z (<number> expected)")

		return new(xx, yy, zz)

	-- number
	elseif type(x) == "number" then
		return new(x, x, x)
	else
		return new()
	end
end

--- Clone a vector.
-- @tparam vec3 a Vector to be cloned
-- @treturn vec3 out
function vec3.clone(a)
	return new(a.x, a.y, a.z)
end

--- Add two vectors.
-- @tparam vec3 a Left hand operand
-- @tparam vec3 b Right hand operand
-- @treturn vec3 out
function vec3.add(a, b)
	return new(
		a.x + b.x,
		a.y + b.y,
		a.z + b.z
	)
end

--- Subtract one vector from another.
-- @tparam vec3 a Left hand operand
-- @tparam vec3 b Right hand operand
-- @treturn vec3 out
function vec3.sub(a, b)
	return new(
		a.x - b.x,
		a.y - b.y,
		a.z - b.z
	)
end

--- Multiply a vector by another vectorr.
-- @tparam vec3 a Left hand operand
-- @tparam vec3 b Right hand operand
-- @treturn vec3 out
function vec3.mul(a, b)
	return new(
		a.x * b.x,
		a.y * b.y,
		a.z * b.z
	)
end

--- Divide a vector by a scalar.
-- @tparam vec3 a Left hand operand
-- @tparam vec3 b Right hand operand
-- @treturn vec3 out
function vec3.div(a, b)
	return new(
		a.x / b.x,
		a.y / b.y,
		a.z / b.z
	)
end

--- Get the normal of a vector.
-- @tparam vec3 a Vector to normalize
-- @treturn vec3 out
function vec3.normalize(a)
	if a:is_zero() then
		return new()
	end
	return a:scale(1 / a:len())
end

--- Trim a vector to a given length
-- @tparam vec3 a Vector to be trimmed
-- @tparam number len Length to trim the vector to
-- @treturn vec3 out
function vec3.trim(a, len)
	return a:normalize():scale(math.min(a:len(), len))
end

--- Get the cross product of two vectors.
-- @tparam vec3 a Left hand operand
-- @tparam vec3 b Right hand operand
-- @treturn vec3 out
function vec3.cross(a, b)
	return new(
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x
	)
end

--- Get the dot product of two vectors.
-- @tparam vec3 a Left hand operand
-- @tparam vec3 b Right hand operand
-- @treturn number dot
function vec3.dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z
end

--- Get the length of a vector.
-- @tparam vec3 a Vector to get the length of
-- @treturn number len
function vec3.len(a)
	return sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
end

--- Get the squared length of a vector.
-- @tparam vec3 a Vector to get the squared length of
-- @treturn number len
function vec3.len2(a)
	return a.x * a.x + a.y * a.y + a.z * a.z
end

--- Get the distance between two vectors.
-- @tparam vec3 a Left hand operand
-- @tparam vec3 b Right hand operand
-- @treturn number dist
function vec3.dist(a, b)
	local dx = a.x - b.x
	local dy = a.y - b.y
	local dz = a.z - b.z
	return sqrt(dx * dx + dy * dy + dz * dz)
end

--- Get the squared distance between two vectors.
-- @tparam vec3 a Left hand operand
-- @tparam vec3 b Right hand operand
-- @treturn number dist
function vec3.dist2(a, b)
	local dx = a.x - b.x
	local dy = a.y - b.y
	local dz = a.z - b.z
	return dx * dx + dy * dy + dz * dz
end

--- Scale a vector by a scalar.
-- @tparam vec3 a Left hand operand
-- @tparam number b Right hand operand
-- @treturn vec3 out
function vec3.scale(a, b)
	return new(
		a.x * b,
		a.y * b,
		a.z * b
	)
end

--- Rotate vector about an axis.
-- @tparam vec3 a Vector to rotate
-- @tparam number phi Angle to rotate vector by (in radians)
-- @tparam vec3 axis Axis to rotate by
-- @treturn vec3 out
function vec3.rotate(a, phi, axis)
	if not vec3.is_vec3(axis) then
		return a
	end

	local u = axis:normalize()
	local c = cos(phi)
	local s = sin(phi)

	-- Calculate generalized rotation matrix
	local m1 = new((c + u.x * u.x * (1 - c)),       (u.x * u.y * (1 - c) - u.z * s), (u.x * u.z * (1 - c) + u.y * s))
	local m2 = new((u.y * u.x * (1 - c) + u.z * s), (c + u.y * u.y * (1 - c)),       (u.y * u.z * (1 - c) - u.x * s))
	local m3 = new((u.z * u.x * (1 - c) - u.y * s), (u.z * u.y * (1 - c) + u.x * s), (c + u.z * u.z * (1 - c))      )

	return new(
		a:dot(m1),
		a:dot(m2),
		a:dot(m3)
	)
end

--- Get the perpendicular vector of a vector.
-- @tparam vec3 a Vector to get perpendicular axes from
-- @treturn vec3 out
function vec3.perpendicular(a)
	return new(-a.y, a.x, 0)
end

--- Lerp between two vectors.
-- @tparam vec3 a Left hand operand
-- @tparam vec3 b Right hand operand
-- @tparam number s Step value
-- @treturn vec3 out
function vec3.lerp(a, b, s)
	return a + (b - a) * s
end

-- Round all components to nearest int (or other precision).
-- @tparam vec3 a Vector to round.
-- @tparam precision Digits after the decimal (round numebr if unspecified)
-- @treturn vec3 Rounded vector
function vec3.round(a, precision)
	return vec3.new(private.round(a.x, precision), private.round(a.y, precision), private.round(a.z, precision))
end

--- Unpack a vector into individual components.
-- @tparam vec3 a Vector to unpack
-- @treturn number x
-- @treturn number y
-- @treturn number z
function vec3.unpack(a)
	return a.x, a.y, a.z
end

--- Return the component-wise minimum of two vectors.
-- @tparam vec3 a Left hand operand
-- @tparam vec3 b Right hand operand
-- @treturn vec3 A vector where each component is the lesser value for that component between the two given vectors.
function vec3.component_min(a, b)
	return new(math.min(a.x, b.x), math.min(a.y, b.y), math.min(a.z, b.z))
end

--- Return the component-wise maximum of two vectors.
-- @tparam vec3 a Left hand operand
-- @tparam vec3 b Right hand operand
-- @treturn vec3 A vector where each component is the lesser value for that component between the two given vectors.
function vec3.component_max(a, b)
	return new(math.max(a.x, b.x), math.max(a.y, b.y), math.max(a.z, b.z))
end

-- Negate x axis only of vector.
-- @tparam vec2 a Vector to x-flip.
-- @treturn vec2 x-flipped vector
function vec3.flip_x(a)
	return vec3.new(-a.x, a.y, a.z)
end

-- Negate y axis only of vector.
-- @tparam vec2 a Vector to y-flip.
-- @treturn vec2 y-flipped vector
function vec3.flip_y(a)
	return vec3.new(a.x, -a.y, a.z)
end

-- Negate z axis only of vector.
-- @tparam vec2 a Vector to z-flip.
-- @treturn vec2 z-flipped vector
function vec3.flip_z(a)
	return vec3.new(a.x, a.y, -a.z)
end

--- Return a boolean showing if a table is or is not a vec3.
-- @tparam vec3 a Vector to be tested
-- @treturn boolean is_vec3
function vec3.is_vec3(a)
	if type(a) == "cdata" then
		return ffi.istype("cpml_vec3", a)
	end

	return
		type(a)   == "table"  and
		type(a.x) == "number" and
		type(a.y) == "number" and
		type(a.z) == "number"
end

--- Return a boolean showing if a table is or is not a zero vec3.
-- @tparam vec3 a Vector to be tested
-- @treturn boolean is_zero
function vec3.is_zero(a)
	return a.x == 0 and a.y == 0 and a.z == 0
end

--- Return a formatted string.
-- @tparam vec3 a Vector to be turned into a string
-- @treturn string formatted
function vec3.to_string(a)
	return string.format("(%+0.3f,%+0.3f,%+0.3f)", a.x, a.y, a.z)
end

vec3_mt.__index    = vec3
vec3_mt.__tostring = vec3.to_string

function vec3_mt.__call(_, x, y, z)
	return vec3.new(x, y, z)
end

function vec3_mt.__unm(a)
	return new(-a.x, -a.y, -a.z)
end

function vec3_mt.__eq(a, b)
	if not vec3.is_vec3(a) or not vec3.is_vec3(b) then
		return false
	end
	return a.x == b.x and a.y == b.y and a.z == b.z
end

function vec3_mt.__add(a, b)
	assert(vec3.is_vec3(a), "__add: Wrong argument type for left hand operand. (<cpml.vec3> expected)")
	assert(vec3.is_vec3(b), "__add: Wrong argument type for right hand operand. (<cpml.vec3> expected)")
	return a:add(b)
end

function vec3_mt.__sub(a, b)
	assert(vec3.is_vec3(a), "__sub: Wrong argument type for left hand operand. (<cpml.vec3> expected)")
	assert(vec3.is_vec3(b), "__sub: Wrong argument type for right hand operand. (<cpml.vec3> expected)")
	return a:sub(b)
end

function vec3_mt.__mul(a, b)
	assert(vec3.is_vec3(a), "__mul: Wrong argument type for left hand operand. (<cpml.vec3> expected)")
	assert(vec3.is_vec3(b) or type(b) == "number", "__mul: Wrong argument type for right hand operand. (<cpml.vec3> or <number> expected)")

	if vec3.is_vec3(b) then
		return a:mul(b)
	end

	return a:scale(b)
end

function vec3_mt.__div(a, b)
	assert(vec3.is_vec3(a), "__div: Wrong argument type for left hand operand. (<cpml.vec3> expected)")
	assert(vec3.is_vec3(b) or type(b) == "number", "__div: Wrong argument type for right hand operand. (<cpml.vec3> or <number> expected)")

	if vec3.is_vec3(b) then
		return a:div(b)
	end

	return a:scale(1 / b)
end

if status then
	xpcall(function() -- Allow this to silently fail; assume failure means someone messed with package.loaded
		ffi.metatype(new, vec3_mt)
	end, function() end)
end

vec3 = setmetatable({}, vec3_mt)

end


--
-- BLOCK vec2
-- 

do
-- Private constructor.
local function new(x, y)
	return setmetatable({
		x = x or 0,
		y = y or 0
	}, vec2_mt)
end

-- Do the check to see if JIT is enabled. If so use the optimized FFI structs.
local status, ffi
if type(jit) == "table" and jit.status() then
	status, ffi = pcall(require, "ffi")
	if status then
		ffi.cdef "typedef struct { double x, y;} cpml_vec2;"
		new = ffi.typeof("cpml_vec2")
	end
end

--- Constants
-- @table vec2
-- @field unit_x X axis of rotation
-- @field unit_y Y axis of rotation
-- @field zero Empty vector
vec2.unit_x = new(1, 0)
vec2.unit_y = new(0, 1)
vec2.zero   = new(0, 0)

--- The public constructor.
-- @param x Can be of three types: </br>
-- number X component
-- table {x, y} or {x = x, y = y}
-- scalar to fill the vector eg. {x, x}
-- @tparam number y Y component
-- @treturn vec2 out
function vec2.new(x, y)
	-- number, number
	if x and y then
		assert(type(x) == "number", "new: Wrong argument type for x (<number> expected)")
		assert(type(y) == "number", "new: Wrong argument type for y (<number> expected)")

		return new(x, y)

	-- {x, y} or {x=x, y=y}
	elseif type(x) == "table" or type(x) == "cdata" then -- table in vanilla lua, cdata in luajit
		local xx, yy = x.x or x[1], x.y or x[2]
		assert(type(xx) == "number", "new: Wrong argument type for x (<number> expected)")
		assert(type(yy) == "number", "new: Wrong argument type for y (<number> expected)")

		return new(xx, yy)

	-- number
	elseif type(x) == "number" then
		return new(x, x)
	else
		return new()
	end
end

--- Convert point from polar to cartesian.
-- @tparam number radius Radius of the point
-- @tparam number theta Angle of the point (in radians)
-- @treturn vec2 out
function vec2.from_cartesian(radius, theta)
	return new(radius * cos(theta), radius * sin(theta))
end

--- Clone a vector.
-- @tparam vec2 a Vector to be cloned
-- @treturn vec2 out
function vec2.clone(a)
	return new(a.x, a.y)
end

--- Add two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn vec2 out
function vec2.add(a, b)
	return new(
		a.x + b.x,
		a.y + b.y
	)
end

--- Subtract one vector from another.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn vec2 out
function vec2.sub(a, b)
	return new(
		a.x - b.x,
		a.y - b.y
	)
end

--- Multiply a vector by another vector.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn vec2 out
function vec2.mul(a, b)
	return new(
		a.x * b.x,
		a.y * b.y
	)
end

--- Divide a vector by another vector.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn vec2 out
function vec2.div(a, b)
	return new(
		a.x / b.x,
		a.y / b.y
	)
end

--- Get the normal of a vector.
-- @tparam vec2 a Vector to normalize
-- @treturn vec2 out
function vec2.normalize(a)
	if a:is_zero() then
		return new()
	end
	return a:scale(1 / a:len())
end

--- Trim a vector to a given length.
-- @tparam vec2 a Vector to be trimmed
-- @tparam number len Length to trim the vector to
-- @treturn vec2 out
function vec2.trim(a, len)
	return a:normalize():scale(math.min(a:len(), len))
end

--- Get the cross product of two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn number magnitude
function vec2.cross(a, b)
	return a.x * b.y - a.y * b.x
end

--- Get the dot product of two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn number dot
function vec2.dot(a, b)
	return a.x * b.x + a.y * b.y
end

--- Get the length of a vector.
-- @tparam vec2 a Vector to get the length of
-- @treturn number len
function vec2.len(a)
	return sqrt(a.x * a.x + a.y * a.y)
end

--- Get the squared length of a vector.
-- @tparam vec2 a Vector to get the squared length of
-- @treturn number len
function vec2.len2(a)
	return a.x * a.x + a.y * a.y
end

--- Get the distance between two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn number dist
function vec2.dist(a, b)
	local dx = a.x - b.x
	local dy = a.y - b.y
	return sqrt(dx * dx + dy * dy)
end

--- Get the squared distance between two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn number dist
function vec2.dist2(a, b)
	local dx = a.x - b.x
	local dy = a.y - b.y
	return dx * dx + dy * dy
end

--- Scale a vector by a scalar.
-- @tparam vec2 a Left hand operand
-- @tparam number b Right hand operand
-- @treturn vec2 out
function vec2.scale(a, b)
	return new(
		a.x * b,
		a.y * b
	)
end

--- Rotate a vector.
-- @tparam vec2 a Vector to rotate
-- @tparam number phi Angle to rotate vector by (in radians)
-- @treturn vec2 out
function vec2.rotate(a, phi)
	local c = cos(phi)
	local s = sin(phi)
	return new(
		c * a.x - s * a.y,
		s * a.x + c * a.y
	)
end

--- Get the perpendicular vector of a vector.
-- @tparam vec2 a Vector to get perpendicular axes from
-- @treturn vec2 out
function vec2.perpendicular(a)
	return new(-a.y, a.x)
end

--- Signed angle from one vector to another.
-- Rotations from +x to +y are positive.
-- @tparam vec2 a Vector
-- @tparam vec2 b Vector
-- @treturn number angle in (-pi, pi]
function vec2.angle_to(a, b)
	if b then
		local angle = atan2(b.y, b.x) - atan2(a.y, a.x)
		-- convert to (-pi, pi]
		if angle > math.pi       then
			angle = angle - 2 * math.pi
		elseif angle <= -math.pi then
			angle = angle + 2 * math.pi
		end
		return angle
	end

	return atan2(a.y, a.x)
end

--- Unsigned angle between two vectors.
-- Directionless and thus commutative.
-- @tparam vec2 a Vector
-- @tparam vec2 b Vector
-- @treturn number angle in [0, pi]
function vec2.angle_between(a, b)
	if b then
		if vec2.is_vec2(a) then
			return acos(a:dot(b) / (a:len() * b:len()))
		end

		return acos(vec3.dot(a, b) / (vec3.len(a) * vec3.len(b)))
	end

	return 0
end

--- Lerp between two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @tparam number s Step value
-- @treturn vec2 out
function vec2.lerp(a, b, s)
	return a + (b - a) * s
end

--- Unpack a vector into individual components.
-- @tparam vec2 a Vector to unpack
-- @treturn number x
-- @treturn number y
function vec2.unpack(a)
	return a.x, a.y
end

--- Return the component-wise minimum of two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn vec2 A vector where each component is the lesser value for that component between the two given vectors.
function vec2.component_min(a, b)
	return new(math.min(a.x, b.x), math.min(a.y, b.y))
end

--- Return the component-wise maximum of two vectors.
-- @tparam vec2 a Left hand operand
-- @tparam vec2 b Right hand operand
-- @treturn vec2 A vector where each component is the lesser value for that component between the two given vectors.
function vec2.component_max(a, b)
	return new(math.max(a.x, b.x), math.max(a.y, b.y))
end


--- Return a boolean showing if a table is or is not a vec2.
-- @tparam vec2 a Vector to be tested
-- @treturn boolean is_vec2
function vec2.is_vec2(a)
	if type(a) == "cdata" then
		return ffi.istype("cpml_vec2", a)
	end

	return
		type(a)   == "table"  and
		type(a.x) == "number" and
		type(a.y) == "number"
end

--- Return a boolean showing if a table is or is not a zero vec2.
-- @tparam vec2 a Vector to be tested
-- @treturn boolean is_zero
function vec2.is_zero(a)
	return a.x == 0 and a.y == 0
end

--- Convert point from cartesian to polar.
-- @tparam vec2 a Vector to convert
-- @treturn number radius
-- @treturn number theta
function vec2.to_polar(a)
	local radius = sqrt(a.x^2 + a.y^2)
	local theta  = atan2(a.y, a.x)
	theta = theta > 0 and theta or theta + 2 * math.pi
	return radius, theta
end

-- Round all components to nearest int (or other precision).
-- @tparam vec2 a Vector to round.
-- @tparam precision Digits after the decimal (round numebr if unspecified)
-- @treturn vec2 Rounded vector
function vec2.round(a, precision)
	return vec2.new(private.round(a.x, precision), private.round(a.y, precision))
end

-- Negate x axis only of vector.
-- @tparam vec2 a Vector to x-flip.
-- @treturn vec2 x-flipped vector
function vec2.flip_x(a)
	return vec2.new(-a.x, a.y)
end

-- Negate y axis only of vector.
-- @tparam vec2 a Vector to y-flip.
-- @treturn vec2 y-flipped vector
function vec2.flip_y(a)
	return vec2.new(a.x, -a.y)
end

-- Convert vec2 to vec3.
-- @tparam vec2 a Vector to convert.
-- @tparam number the new z component, or nil for 0
-- @treturn vec3 Converted vector
function vec2.to_vec3(a, z)
	return vec3(a.x, a.y, z or 0)
end

--- Return a formatted string.
-- @tparam vec2 a Vector to be turned into a string
-- @treturn string formatted
function vec2.to_string(a)
	return string.format("(%+0.3f,%+0.3f)", a.x, a.y)
end

vec2_mt.__index    = vec2
vec2_mt.__tostring = vec2.to_string

function vec2_mt.__call(_, x, y)
	return vec2.new(x, y)
end

function vec2_mt.__unm(a)
	return new(-a.x, -a.y)
end

function vec2_mt.__eq(a, b)
	if not vec2.is_vec2(a) or not vec2.is_vec2(b) then
		return false
	end
	return a.x == b.x and a.y == b.y
end

function vec2_mt.__add(a, b)
	assert(vec2.is_vec2(a), "__add: Wrong argument type for left hand operand. (<cpml.vec2> expected)")
	assert(vec2.is_vec2(b), "__add: Wrong argument type for right hand operand. (<cpml.vec2> expected)")
	return a:add(b)
end

function vec2_mt.__sub(a, b)
	assert(vec2.is_vec2(a), "__add: Wrong argument type for left hand operand. (<cpml.vec2> expected)")
	assert(vec2.is_vec2(b), "__add: Wrong argument type for right hand operand. (<cpml.vec2> expected)")
	return a:sub(b)
end

function vec2_mt.__mul(a, b)
	assert(vec2.is_vec2(a), "__mul: Wrong argument type for left hand operand. (<cpml.vec2> expected)")
	assert(vec2.is_vec2(b) or type(b) == "number", "__mul: Wrong argument type for right hand operand. (<cpml.vec2> or <number> expected)")

	if vec2.is_vec2(b) then
		return a:mul(b)
	end

	return a:scale(b)
end

function vec2_mt.__div(a, b)
	assert(vec2.is_vec2(a), "__div: Wrong argument type for left hand operand. (<cpml.vec2> expected)")
	assert(vec2.is_vec2(b) or type(b) == "number", "__div: Wrong argument type for right hand operand. (<cpml.vec2> or <number> expected)")

	if vec2.is_vec2(b) then
		return a:div(b)
	end

	return a:scale(1 / b)
end

if status then
	xpcall(function() -- Allow this to silently fail; assume failure means someone messed with package.loaded
		ffi.metatype(new, vec2_mt)
	end, function() end)
end

vec2 = setmetatable({}, vec2_mt)

end 

--
-- BLOCK utils
--

do

--- Clamps a value within the specified range.
-- @param value Input value
-- @param min Minimum output value
-- @param max Maximum output value
-- @return number
function utils.clamp(value, min, max)
	return math.max(math.min(value, max), min)
end

--- Returns `value` if it is equal or greater than |`size`|, or 0.
-- @param value
-- @param size
-- @return number
function utils.deadzone(value, size)
	return abs(value) >= size and value or 0
end

--- Check if value is equal or greater than threshold.
-- @param value
-- @param threshold
-- @return boolean
function utils.threshold(value, threshold)
	-- I know, it barely saves any typing at all.
	return abs(value) >= threshold
end

--- Check if value is equal or less than threshold.
-- @param value
-- @param threshold
-- @return boolean
function utils.tolerance(value, threshold)
	-- I know, it barely saves any typing at all.
	return abs(value) <= threshold
end

--- Scales a value from one range to another.
-- @param value Input value
-- @param min_in Minimum input value
-- @param max_in Maximum input value
-- @param min_out Minimum output value
-- @param max_out Maximum output value
-- @return number
function utils.map(value, min_in, max_in, min_out, max_out)
	return ((value) - (min_in)) * ((max_out) - (min_out)) / ((max_in) - (min_in)) + (min_out)
end

--- Linear interpolation.
-- Performs linear interpolation between 0 and 1 when `low` < `progress` < `high`.
-- @param low value to return when `progress` is 0
-- @param high value to return when `progress` is 1
-- @param progress (0-1)
-- @return number
function utils.lerp(low, high, progress)
	return low * (1 - progress) + high * progress
end

--- Exponential decay
-- @param low initial value
-- @param high target value
-- @param rate portion of the original value remaining per second
-- @param dt time delta
-- @return number
function utils.decay(low, high, rate, dt)
	return utils.lerp(low, high, 1.0 - math.exp(-rate * dt))
end

--- Hermite interpolation.
-- Performs smooth Hermite interpolation between 0 and 1 when `low` < `progress` < `high`.
-- @param progress (0-1)
-- @param low value to return when `progress` is 0
-- @param high value to return when `progress` is 1
-- @return number
function utils.smoothstep(progress, low, high)
	local t = utils.clamp((progress - low) / (high - low), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
end

--- Round number at a given precision.
-- Truncates `value` at `precision` points after the decimal (whole number if
-- left unspecified).
-- @param value
-- @param precision
-- @return number
utils.round = private.round

--- Wrap `value` around if it exceeds `limit`.
-- @param value
-- @param limit
-- @return number
function utils.wrap(value, limit)
	if value < 0 then
		value = value + utils.round(((-value/limit)+1))*limit
	end
	return value % limit
end

--- Check if a value is a power-of-two.
-- Returns true if a number is a valid power-of-two, otherwise false.
-- @author undef
-- @param value
-- @return boolean
function utils.is_pot(value)
	-- found here: https://love2d.org/forums/viewtopic.php?p=182219#p182219
	-- check if a number is a power-of-two
	return (frexp(value)) == 0.5
end

-- Originally from vec3
function utils.project_on(a, b)
	local s =
		(a.x * b.x + a.y * b.y + a.z or 0 * b.z or 0) /
		(b.x * b.x + b.y * b.y + b.z or 0 * b.z or 0)

	if a.z and b.z then
		return vec3(
			b.x * s,
			b.y * s,
			b.z * s
		)
	end

	return vec2(
		b.x * s,
		b.y * s
	)
end

-- Originally from vec3
function utils.project_from(a, b)
	local s =
		(b.x * b.x + b.y * b.y + b.z or 0 * b.z or 0) /
		(a.x * b.x + a.y * b.y + a.z or 0 * b.z or 0)

	if a.z and b.z then
		return vec3(
			b.x * s,
			b.y * s,
			b.z * s
		)
	end

	return vec2(
		b.x * s,
		b.y * s
	)
end

-- Originally from vec3
function utils.mirror_on(a, b)
	local s =
		(a.x * b.x + a.y * b.y + a.z or 0 * b.z or 0) /
		(b.x * b.x + b.y * b.y + b.z or 0 * b.z or 0) * 2

	if a.z and b.z then
		return vec3(
			b.x * s - a.x,
			b.y * s - a.y,
			b.z * s - a.z
		)
	end

	return vec2(
		b.x * s - a.x,
		b.y * s - a.y
	)
end

-- Originally from vec3
function utils.reflect(i, n)
	return i - (n * (2 * n:dot(i)))
end

-- Originally from vec3
function utils.refract(i, n, ior)
	local d = n:dot(i)
	local k = 1 - ior * ior * (1 - d * d)

	if k >= 0 then
		return (i * ior) - (n * (ior * d + k ^ 0.5))
	end

	return vec3()
end

--return utils


end

--
-- BLOCK quat
--

do
-- Private constructor.
local function new(x, y, z, w)
	return setmetatable({
		x = x or 0,
		y = y or 0,
		z = z or 0,
		w = w or 1
	}, quat_mt)
end

-- Do the check to see if JIT is enabled. If so use the optimized FFI structs.
local status, ffi
if type(jit) == "table" and jit.status() then
	status, ffi = pcall(require, "ffi")
	if status then
		ffi.cdef "typedef struct { double x, y, z, w;} cpml_quat;"
		new = ffi.typeof("cpml_quat")
	end
end

-- Statically allocate a temporary variable used in some of our functions.
local tmp = new()
local qv, uv, uuv = vec3(), vec3(), vec3()

--- Constants
-- @table quat
-- @field unit Unit quaternion
-- @field zero Empty quaternion
quat.unit = new(0, 0, 0, 1)
quat.zero = new(0, 0, 0, 0)

--- The public constructor.
-- @param x Can be of two types: </br>
-- number x X component
-- table {x, y, z, w} or {x=x, y=y, z=z, w=w}
-- @tparam number y Y component
-- @tparam number z Z component
-- @tparam number w W component
-- @treturn quat out
function quat.new(x, y, z, w)
	-- number, number, number, number
	if x and y and z and w then
		assert(type(x) == "number", "new: Wrong argument type for x (<number> expected)")
		assert(type(y) == "number", "new: Wrong argument type for y (<number> expected)")
		assert(type(z) == "number", "new: Wrong argument type for z (<number> expected)")
		assert(type(w) == "number", "new: Wrong argument type for w (<number> expected)")

		return new(x, y, z, w)

	-- {x, y, z, w} or {x=x, y=y, z=z, w=w}
	elseif type(x) == "table" then
		local xx, yy, zz, ww = x.x or x[1], x.y or x[2], x.z or x[3], x.w or x[4]
		assert(type(xx) == "number", "new: Wrong argument type for x (<number> expected)")
		assert(type(yy) == "number", "new: Wrong argument type for y (<number> expected)")
		assert(type(zz) == "number", "new: Wrong argument type for z (<number> expected)")
		assert(type(ww) == "number", "new: Wrong argument type for w (<number> expected)")

		return new(xx, yy, zz, ww)
	end

	return new(0, 0, 0, 1)
end

--- Create a quaternion from an angle/axis pair.
-- @tparam number angle Angle (in radians)
-- @param axis/x -- Can be of two types, a vec3 axis, or the x component of that axis
-- @param y axis -- y component of axis (optional, only if x component param used)
-- @param z axis -- z component of axis (optional, only if x component param used)
-- @treturn quat out
function quat.from_angle_axis(angle, axis, a3, a4)
	if axis and a3 and a4 then
		local x, y, z = axis, a3, a4
		local s = sin(angle * 0.5)
		local c = cos(angle * 0.5)
		return new(x * s, y * s, z * s, c)
	else
		return quat.from_angle_axis(angle, axis.x, axis.y, axis.z)
	end
end

--- Create a quaternion from a normal/up vector pair.
-- @tparam vec3 normal
-- @tparam vec3 up (optional)
-- @treturn quat out
function quat.from_direction(normal, up)
	local u = up or vec3.unit_z
	local n = normal:normalize()
	local a = u:cross(n)
	local d = u:dot(n)
	return new(a.x, a.y, a.z, d + 1)
end

--- Clone a quaternion.
-- @tparam quat a Quaternion to clone
-- @treturn quat out
function quat.clone(a)
	return new(a.x, a.y, a.z, a.w)
end

--- Add two quaternions.
-- @tparam quat a Left hand operand
-- @tparam quat b Right hand operand
-- @treturn quat out
function quat.add(a, b)
	return new(
		a.x + b.x,
		a.y + b.y,
		a.z + b.z,
		a.w + b.w
	)
end

--- Subtract a quaternion from another.
-- @tparam quat a Left hand operand
-- @tparam quat b Right hand operand
-- @treturn quat out
function quat.sub(a, b)
	return new(
		a.x - b.x,
		a.y - b.y,
		a.z - b.z,
		a.w - b.w
	)
end

--- Multiply two quaternions.
-- @tparam quat a Left hand operand
-- @tparam quat b Right hand operand
-- @treturn quat quaternion equivalent to "apply b, then a"
function quat.mul(a, b)
	return new(
		a.x * b.w + a.w * b.x + a.y * b.z - a.z * b.y,
		a.y * b.w + a.w * b.y + a.z * b.x - a.x * b.z,
		a.z * b.w + a.w * b.z + a.x * b.y - a.y * b.x,
		a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
	)
end

--- Multiply a quaternion and a vec3.
-- @tparam quat a Left hand operand
-- @tparam vec3 b Right hand operand
-- @treturn quat out
function quat.mul_vec3(a, b)
	qv.x = a.x
	qv.y = a.y
	qv.z = a.z
	uv   = qv:cross(b)
	uuv  = qv:cross(uv)
	return b + ((uv * a.w) + uuv) * 2
end

--- Raise a normalized quaternion to a scalar power.
-- @tparam quat a Left hand operand (should be a unit quaternion)
-- @tparam number s Right hand operand
-- @treturn quat out
function quat.pow(a, s)
	-- Do it as a slerp between identity and a (code borrowed from slerp)
	if a.w < 0 then
		a   = -a
	end
	local dot = a.w

	dot = min(max(dot, -1), 1)

	local theta = acos(dot) * s
	local c = new(a.x, a.y, a.z, 0):normalize() * sin(theta)
	c.w = cos(theta)
	return c
end

--- Normalize a quaternion.
-- @tparam quat a Quaternion to normalize
-- @treturn quat out
function quat.normalize(a)
	if a:is_zero() then
		return new(0, 0, 0, 0)
	end
	return a:scale(1 / a:len())
end

--- Get the dot product of two quaternions.
-- @tparam quat a Left hand operand
-- @tparam quat b Right hand operand
-- @treturn number dot
function quat.dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
end

--- Return the length of a quaternion.
-- @tparam quat a Quaternion to get length of
-- @treturn number len
function quat.len(a)
	return sqrt(a.x * a.x + a.y * a.y + a.z * a.z + a.w * a.w)
end

--- Return the squared length of a quaternion.
-- @tparam quat a Quaternion to get length of
-- @treturn number len
function quat.len2(a)
	return a.x * a.x + a.y * a.y + a.z * a.z + a.w * a.w
end

--- Multiply a quaternion by a scalar.
-- @tparam quat a Left hand operand
-- @tparam number s Right hand operand
-- @treturn quat out
function quat.scale(a, s)
	return new(
		a.x * s,
		a.y * s,
		a.z * s,
		a.w * s
	)
end

--- Alias of from_angle_axis.
-- @tparam number angle Angle (in radians)
-- @param axis/x -- Can be of two types, a vec3 axis, or the x component of that axis
-- @param y axis -- y component of axis (optional, only if x component param used)
-- @param z axis -- z component of axis (optional, only if x component param used)
-- @treturn quat out
function quat.rotate(angle, axis, a3, a4)
	return quat.from_angle_axis(angle, axis, a3, a4)
end

--- Return the conjugate of a quaternion.
-- @tparam quat a Quaternion to conjugate
-- @treturn quat out
function quat.conjugate(a)
	return new(-a.x, -a.y, -a.z, a.w)
end

--- Return the inverse of a quaternion.
-- @tparam quat a Quaternion to invert
-- @treturn quat out
function quat.inverse(a)
	tmp.x = -a.x
	tmp.y = -a.y
	tmp.z = -a.z
	tmp.w =  a.w
	return tmp:normalize()
end

--- Return the reciprocal of a quaternion.
-- @tparam quat a Quaternion to reciprocate
-- @treturn quat out
function quat.reciprocal(a)
	if a:is_zero() then
		error("Cannot reciprocate a zero quaternion")
		return false
	end

	tmp.x = -a.x
	tmp.y = -a.y
	tmp.z = -a.z
	tmp.w =  a.w

	return tmp:scale(1 / a:len2())
end

--- Lerp between two quaternions.
-- @tparam quat a Left hand operand
-- @tparam quat b Right hand operand
-- @tparam number s Step value
-- @treturn quat out
function quat.lerp(a, b, s)
	return (a + (b - a) * s):normalize()
end

--- Slerp between two quaternions.
-- @tparam quat a Left hand operand
-- @tparam quat b Right hand operand
-- @tparam number s Step value
-- @treturn quat out
function quat.slerp(a, b, s)
	local dot = a:dot(b)

	if dot < 0 then
		a   = -a
		dot = -dot
	end

	if dot > DOT_THRESHOLD then
		return a:lerp(b, s)
	end

	dot = min(max(dot, -1), 1)

	local theta = acos(dot) * s
	local c = (b - a * dot):normalize()
	return a * cos(theta) + c * sin(theta)
end

--- Unpack a quaternion into individual components.
-- @tparam quat a Quaternion to unpack
-- @treturn number x
-- @treturn number y
-- @treturn number z
-- @treturn number w
function quat.unpack(a)
	return a.x, a.y, a.z, a.w
end

--- Return a boolean showing if a table is or is not a quat.
-- @tparam quat a Quaternion to be tested
-- @treturn boolean is_quat
function quat.is_quat(a)
	if type(a) == "cdata" then
		return ffi.istype("cpml_quat", a)
	end

	return
		type(a)   == "table"  and
		type(a.x) == "number" and
		type(a.y) == "number" and
		type(a.z) == "number" and
		type(a.w) == "number"
end

--- Return a boolean showing if a table is or is not a zero quat.
-- @tparam quat a Quaternion to be tested
-- @treturn boolean is_zero
function quat.is_zero(a)
	return
		a.x == 0 and
		a.y == 0 and
		a.z == 0 and
		a.w == 0
end

--- Return a boolean showing if a table is or is not a real quat.
-- @tparam quat a Quaternion to be tested
-- @treturn boolean is_real
function quat.is_real(a)
	return
		a.x == 0 and
		a.y == 0 and
		a.z == 0
end

--- Return a boolean showing if a table is or is not an imaginary quat.
-- @tparam quat a Quaternion to be tested
-- @treturn boolean is_imaginary
function quat.is_imaginary(a)
	return a.w == 0
end

--- Convert a quaternion into an angle plus axis components.
-- @tparam quat a Quaternion to convert
-- @tparam identityAxis vec3 of axis to use on identity/degenerate quaternions (optional, default returns 0,0,0,1)
-- @treturn number angle
-- @treturn x axis-x
-- @treturn y axis-y
-- @treturn z axis-z
function quat.to_angle_axis_unpack(a, identityAxis)
	if a.w > 1 or a.w < -1 then
		a = a:normalize()
	end

	-- If length of xyz components is less than DBL_EPSILON, this is zero or close enough (an identity quaternion)
	-- Normally an identity quat would return a nonsense answer, so we return an arbitrary zero rotation early.
	-- FIXME: Is it safe to assume there are *no* valid quaternions with nonzero degenerate lengths?
	if a.x*a.x + a.y*a.y + a.z*a.z < constants.DBL_EPSILON*constants.DBL_EPSILON then
		if identityAxis then
			return 0,identityAxis:unpack()
		else
			return 0,0,0,1
		end
	end

	local x, y, z
	local angle = 2 * acos(a.w)
	local s     = sqrt(1 - a.w * a.w)

	if s < DBL_EPSILON then
		x = a.x
		y = a.y
		z = a.z
	else
		x = a.x / s
		y = a.y / s
		z = a.z / s
	end

	return angle, x, y, z
end

--- Convert a quaternion into an angle/axis pair.
-- @tparam quat a Quaternion to convert
-- @tparam identityAxis vec3 of axis to use on identity/degenerate quaternions (optional, default returns 0,vec3(0,0,1))
-- @treturn number angle
-- @treturn vec3 axis
function quat.to_angle_axis(a, identityAxis)
	local angle, x, y, z = a:to_angle_axis_unpack(identityAxis)
	return angle, vec3(x, y, z)
end

--- Convert a quaternion into a vec3.
-- @tparam quat a Quaternion to convert
-- @treturn vec3 out
function quat.to_vec3(a)
	return vec3(a.x, a.y, a.z)
end

--- Return a formatted string.
-- @tparam quat a Quaternion to be turned into a string
-- @treturn string formatted
function quat.to_string(a)
	return string.format("(%+0.3f,%+0.3f,%+0.3f,%+0.3f)", a.x, a.y, a.z, a.w)
end

quat_mt.__index    = quat
quat_mt.__tostring = quat.to_string

function quat_mt.__call(_, x, y, z, w)
	return quat.new(x, y, z, w)
end

function quat_mt.__unm(a)
	return a:scale(-1)
end

function quat_mt.__eq(a,b)
	if not quat.is_quat(a) or not quat.is_quat(b) then
		return false
	end
	return a.x == b.x and a.y == b.y and a.z == b.z and a.w == b.w
end

function quat_mt.__add(a, b)
	assert(quat.is_quat(a), "__add: Wrong argument type for left hand operand. (<cpml.quat> expected)")
	assert(quat.is_quat(b), "__add: Wrong argument type for right hand operand. (<cpml.quat> expected)")
	return a:add(b)
end

function quat_mt.__sub(a, b)
	assert(quat.is_quat(a), "__sub: Wrong argument type for left hand operand. (<cpml.quat> expected)")
	assert(quat.is_quat(b), "__sub: Wrong argument type for right hand operand. (<cpml.quat> expected)")
	return a:sub(b)
end

function quat_mt.__mul(a, b)
	assert(quat.is_quat(a), "__mul: Wrong argument type for left hand operand. (<cpml.quat> expected)")
	assert(quat.is_quat(b) or vec3.is_vec3(b) or type(b) == "number", "__mul: Wrong argument type for right hand operand. (<cpml.quat> or <cpml.vec3> or <number> expected)")

	if quat.is_quat(b) then
		return a:mul(b)
	end

	if type(b) == "number" then
		return a:scale(b)
	end

	return a:mul_vec3(b)
end

function quat_mt.__pow(a, n)
	assert(quat.is_quat(a), "__pow: Wrong argument type for left hand operand. (<cpml.quat> expected)")
	assert(type(n) == "number", "__pow: Wrong argument type for right hand operand. (<number> expected)")
	return a:pow(n)
end

if status then
	xpcall(function() -- Allow this to silently fail; assume failure means someone messed with package.loaded
		ffi.metatype(new, quat_mt)
	end, function() end)
end

quat = setmetatable({}, quat_mt)


end

--
-- BLOCK mat4
--

do
-- Private constructor.
local function new(m)
	m = m or {
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0
	}
	m._m = m
	return setmetatable(m, mat4_mt)
end
 -- Convert matrix into identity
local function identity(m)
	m[1],  m[2],  m[3],  m[4]  = 1, 0, 0, 0
	m[5],  m[6],  m[7],  m[8]  = 0, 1, 0, 0
	m[9],  m[10], m[11], m[12] = 0, 0, 1, 0
	m[13], m[14], m[15], m[16] = 0, 0, 0, 1
	return m
end

-- Do the check to see if JIT is enabled. If so use the optimized FFI structs.
local status, ffi, the_type
if type(jit) == "table" and jit.status() then
   --  status, ffi = pcall(require, "ffi")
    if status then
        ffi.cdef "typedef struct { double _m[16]; } cpml_mat4;"
        new = ffi.typeof("cpml_mat4")
    end
end

-- Statically allocate a temporary variable used in some of our functions.
local tmp = new()
local tm4 = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
local tv4 = { 0, 0, 0, 0 }
local forward, side, new_up = vec3(), vec3(), vec3()

--- The public constructor.
-- @param a Can be of four types: </br>
-- table Length 16 (4x4 matrix)
-- table Length 9 (3x3 matrix)
-- table Length 4 (4 vec4s)
-- nil
-- @treturn mat4 out
function mat4.new(a)
	local out = new()

	-- 4x4 matrix
	if type(a) == "table" and #a == 16 then
		for i = 1, 16 do
			out[i] = tonumber(a[i])
		end

	-- 3x3 matrix
	elseif type(a) == "table" and #a == 9 then
		out[1], out[2],  out[3]  = a[1], a[2], a[3]
		out[5], out[6],  out[7]  = a[4], a[5], a[6]
		out[9], out[10], out[11] = a[7], a[8], a[9]
		out[16] = 1

	-- 4 vec4s
	elseif type(a) == "table" and type(a[1]) == "table" then
		local idx = 1
		for i = 1, 4 do
			for j = 1, 4 do
				out[idx] = a[i][j]
				idx = idx + 1
			end
		end

	-- nil
	else
		out[1]  = 1
		out[6]  = 1
		out[11] = 1
		out[16] = 1
	end

	return out
end

--- Create an identity matrix.
-- @tparam mat4 a Matrix to overwrite
-- @treturn mat4 out
function mat4.identity(a)
	return identity(a or new())
end

--- Create a matrix from an angle/axis pair.
-- @tparam number angle Angle of rotation
-- @tparam vec3 axis Axis of rotation
-- @treturn mat4 out
function mat4.from_angle_axis(angle, axis)
	local l = axis:len()
	if l == 0 then
		return new()
	end

	local x, y, z = axis.x / l, axis.y / l, axis.z / l
	local c = cos(angle)
	local s = sin(angle)

	return new {
		x*x*(1-c)+c,   y*x*(1-c)+z*s, x*z*(1-c)-y*s, 0,
		x*y*(1-c)-z*s, y*y*(1-c)+c,   y*z*(1-c)+x*s, 0,
		x*z*(1-c)+y*s, y*z*(1-c)-x*s, z*z*(1-c)+c,   0,
		0, 0, 0, 1
	}
end

--- Create a matrix from a quaternion.
-- @tparam quat q Rotation quaternion
-- @treturn mat4 out
function mat4.from_quaternion(q)
	return mat4.from_angle_axis(q:to_angle_axis())
end

--- Create a matrix from a direction/up pair.
-- @tparam vec3 direction Vector direction
-- @tparam vec3 up Up direction
-- @treturn mat4 out
function mat4.from_direction(direction, up)
	local forward = vec3.normalize(direction)
	local side = vec3.cross(forward, up):normalize()
	local new_up = vec3.cross(side, forward):normalize()

	local out = new()
	out[1]    = side.x
	out[5]    = side.y
	out[9]    = side.z
	out[2]    = new_up.x
	out[6]    = new_up.y
	out[10]   = new_up.z
	out[3]    = forward.x
	out[7]    = forward.y
	out[11]   = forward.z
	out[16]   = 1

	return out
end

--- Create a matrix from a transform.
-- @tparam vec3 trans Translation vector
-- @tparam quat rot Rotation quaternion
-- @tparam vec3 scale Scale vector
-- @treturn mat4 out
function mat4.from_transform(trans, rot, scale)
	local angle, axis = rot:to_angle_axis()
	local l = axis:len()

	if l == 0 then
		return new()
	end

	local x, y, z = axis.x / l, axis.y / l, axis.z / l
	local c = cos(angle)
	local s = sin(angle)

	return new {
		x*x*(1-c)+c,   y*x*(1-c)+z*s, x*z*(1-c)-y*s, 0,
		x*y*(1-c)-z*s, y*y*(1-c)+c,   y*z*(1-c)+x*s, 0,
		x*z*(1-c)+y*s, y*z*(1-c)-x*s, z*z*(1-c)+c,   0,
		trans.x, trans.y, trans.z, 1
	}
end

--- Create matrix from orthogonal.
-- @tparam number left
-- @tparam number right
-- @tparam number top
-- @tparam number bottom
-- @tparam number near
-- @tparam number far
-- @treturn mat4 out
function mat4.from_ortho(left, right, top, bottom, near, far)
	local out = new()
	out[1]    =  2 / (right - left)
	out[6]    =  2 / (top - bottom)
	out[11]   = -2 / (far - near)
	out[13]   = -((right + left) / (right - left))
	out[14]   = -((top + bottom) / (top - bottom))
	out[15]   = -((far + near) / (far - near))
	out[16]   =  1

	return out
end

--- Create matrix from perspective.
-- @tparam number fovy Field of view
-- @tparam number aspect Aspect ratio
-- @tparam number near Near plane
-- @tparam number far Far plane
-- @treturn mat4 out
function mat4.from_perspective(fovy, aspect, near, far)
	assert(aspect ~= 0)
	assert(near   ~= far)

	local t   = tan(rad(fovy) / 2)
	local out = new()
	out[1]    =  1 / (t * aspect)
	out[6]    =  1 / t
	out[11]   = -(far + near) / (far - near)
	out[12]   = -1
	out[15]   = -(2 * far * near) / (far - near)
	out[16]   =  0

	return out
end

-- Adapted from the Oculus SDK.
--- Create matrix from HMD perspective.
-- @tparam number tanHalfFov Tangent of half of the field of view
-- @tparam number zNear Near plane
-- @tparam number zFar Far plane
-- @tparam boolean flipZ Z axis is flipped or not
-- @tparam boolean farAtInfinity Far plane is infinite or not
-- @treturn mat4 out
function mat4.from_hmd_perspective(tanHalfFov, zNear, zFar, flipZ, farAtInfinity)
	-- CPML is right-handed and intended for GL, so these don't need to be arguments.
	local rightHanded = true
	local isOpenGL    = true

	local function CreateNDCScaleAndOffsetFromFov(tanHalfFov)
		x_scale  = 2 / (tanHalfFov.LeftTan + tanHalfFov.RightTan)
		x_offset =     (tanHalfFov.LeftTan - tanHalfFov.RightTan) * x_scale * 0.5
		y_scale  = 2 / (tanHalfFov.UpTan   + tanHalfFov.DownTan )
		y_offset =     (tanHalfFov.UpTan   - tanHalfFov.DownTan ) * y_scale * 0.5

		local result = {
			Scale  = vec2(x_scale, y_scale),
			Offset = vec2(x_offset, y_offset)
		}

		-- Hey - why is that Y.Offset negated?
		-- It's because a projection matrix transforms from world coords with Y=up,
		-- whereas this is from NDC which is Y=down.
		 return result
	end

	if not flipZ and farAtInfinity then
		print("Error: Cannot push Far Clip to Infinity when Z-order is not flipped")
		farAtInfinity = false
	end

	 -- A projection matrix is very like a scaling from NDC, so we can start with that.
	local scaleAndOffset  = CreateNDCScaleAndOffsetFromFov(tanHalfFov)
	local handednessScale = rightHanded and -1.0 or 1.0
	local projection      = new()

	-- Produces X result, mapping clip edges to [-w,+w]
	projection[1] = scaleAndOffset.Scale.x
	projection[2] = 0
	projection[3] = handednessScale * scaleAndOffset.Offset.x
	projection[4] = 0

	-- Produces Y result, mapping clip edges to [-w,+w]
	-- Hey - why is that YOffset negated?
	-- It's because a projection matrix transforms from world coords with Y=up,
	-- whereas this is derived from an NDC scaling, which is Y=down.
	projection[5] = 0
	projection[6] = scaleAndOffset.Scale.y
	projection[7] = handednessScale * -scaleAndOffset.Offset.y
	projection[8] = 0

	-- Produces Z-buffer result - app needs to fill this in with whatever Z range it wants.
	-- We'll just use some defaults for now.
	projection[9]  = 0
	projection[10] = 0

	if farAtInfinity then
		if isOpenGL then
			-- It's not clear this makes sense for OpenGL - you don't get the same precision benefits you do in D3D.
			projection[11] = -handednessScale
			projection[12] = 2.0 * zNear
		else
			projection[11] = 0
			projection[12] = zNear
		end
	else
		if isOpenGL then
			-- Clip range is [-w,+w], so 0 is at the middle of the range.
			projection[11] = -handednessScale * (flipZ and -1.0 or 1.0) * (zNear + zFar) / (zNear - zFar)
			projection[12] = 2.0 * ((flipZ and -zFar or zFar) * zNear) / (zNear - zFar)
		else
			-- Clip range is [0,+w], so 0 is at the start of the range.
			projection[11] = -handednessScale * (flipZ and -zNear or zFar) / (zNear - zFar)
			projection[12] = ((flipZ and -zFar or zFar) * zNear) / (zNear - zFar)
		end
	end

	-- Produces W result (= Z in)
	projection[13] = 0
	projection[14] = 0
	projection[15] = handednessScale
	projection[16] = 0

	return projection:transpose(projection)
end

--- Clone a matrix.
-- @tparam mat4 a Matrix to clone
-- @treturn mat4 out
function mat4.clone(a)
	return new(a)
end

--- Multiply two matrices.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Left hand operand
-- @tparam mat4 b Right hand operand
-- @treturn mat4 out Matrix equivalent to "apply b, then a"
function mat4.mul(out, a, b)
	tm4[1]  = b[1]  * a[1] + b[2]  * a[5] + b[3]  * a[9]  + b[4]  * a[13]
	tm4[2]  = b[1]  * a[2] + b[2]  * a[6] + b[3]  * a[10] + b[4]  * a[14]
	tm4[3]  = b[1]  * a[3] + b[2]  * a[7] + b[3]  * a[11] + b[4]  * a[15]
	tm4[4]  = b[1]  * a[4] + b[2]  * a[8] + b[3]  * a[12] + b[4]  * a[16]
	tm4[5]  = b[5]  * a[1] + b[6]  * a[5] + b[7]  * a[9]  + b[8]  * a[13]
	tm4[6]  = b[5]  * a[2] + b[6]  * a[6] + b[7]  * a[10] + b[8]  * a[14]
	tm4[7]  = b[5]  * a[3] + b[6]  * a[7] + b[7]  * a[11] + b[8]  * a[15]
	tm4[8]  = b[5]  * a[4] + b[6]  * a[8] + b[7]  * a[12] + b[8]  * a[16]
	tm4[9]  = b[9]  * a[1] + b[10] * a[5] + b[11] * a[9]  + b[12] * a[13]
	tm4[10] = b[9]  * a[2] + b[10] * a[6] + b[11] * a[10] + b[12] * a[14]
	tm4[11] = b[9]  * a[3] + b[10] * a[7] + b[11] * a[11] + b[12] * a[15]
	tm4[12] = b[9]  * a[4] + b[10] * a[8] + b[11] * a[12] + b[12] * a[16]
	tm4[13] = b[13] * a[1] + b[14] * a[5] + b[15] * a[9]  + b[16] * a[13]
	tm4[14] = b[13] * a[2] + b[14] * a[6] + b[15] * a[10] + b[16] * a[14]
	tm4[15] = b[13] * a[3] + b[14] * a[7] + b[15] * a[11] + b[16] * a[15]
	tm4[16] = b[13] * a[4] + b[14] * a[8] + b[15] * a[12] + b[16] * a[16]

	for i=1, 16 do
		out[i] = tm4[i]
	end

	return out
end

--- Multiply a matrix and a vec4.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Left hand operand
-- @tparam table b Right hand operand
-- @treturn mat4 out
function mat4.mul_vec4(out, a, b)
	tv4[1] = b[1] * a[1] + b[2] * a[5] + b [3] * a[9]  + b[4] * a[13]
	tv4[2] = b[1] * a[2] + b[2] * a[6] + b [3] * a[10] + b[4] * a[14]
	tv4[3] = b[1] * a[3] + b[2] * a[7] + b [3] * a[11] + b[4] * a[15]
	tv4[4] = b[1] * a[4] + b[2] * a[8] + b [3] * a[12] + b[4] * a[16]

	for i=1, 4 do
		out[i] = tv4[i]
	end

	return out
end

--- Invert a matrix.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Matrix to invert
-- @treturn mat4 out
function mat4.invert(out, a)
	tm4[1]  =  a[6] * a[11] * a[16] - a[6] * a[12] * a[15] - a[10] * a[7] * a[16] + a[10] * a[8] * a[15] + a[14] * a[7] * a[12] - a[14] * a[8] * a[11]
	tm4[2]  = -a[2] * a[11] * a[16] + a[2] * a[12] * a[15] + a[10] * a[3] * a[16] - a[10] * a[4] * a[15] - a[14] * a[3] * a[12] + a[14] * a[4] * a[11]
	tm4[3]  =  a[2] * a[7]  * a[16] - a[2] * a[8]  * a[15] - a[6]  * a[3] * a[16] + a[6]  * a[4] * a[15] + a[14] * a[3] * a[8]  - a[14] * a[4] * a[7]
	tm4[4]  = -a[2] * a[7]  * a[12] + a[2] * a[8]  * a[11] + a[6]  * a[3] * a[12] - a[6]  * a[4] * a[11] - a[10] * a[3] * a[8]  + a[10] * a[4] * a[7]
	tm4[5]  = -a[5] * a[11] * a[16] + a[5] * a[12] * a[15] + a[9]  * a[7] * a[16] - a[9]  * a[8] * a[15] - a[13] * a[7] * a[12] + a[13] * a[8] * a[11]
	tm4[6]  =  a[1] * a[11] * a[16] - a[1] * a[12] * a[15] - a[9]  * a[3] * a[16] + a[9]  * a[4] * a[15] + a[13] * a[3] * a[12] - a[13] * a[4] * a[11]
	tm4[7]  = -a[1] * a[7]  * a[16] + a[1] * a[8]  * a[15] + a[5]  * a[3] * a[16] - a[5]  * a[4] * a[15] - a[13] * a[3] * a[8]  + a[13] * a[4] * a[7]
	tm4[8]  =  a[1] * a[7]  * a[12] - a[1] * a[8]  * a[11] - a[5]  * a[3] * a[12] + a[5]  * a[4] * a[11] + a[9]  * a[3] * a[8]  - a[9]  * a[4] * a[7]
	tm4[9]  =  a[5] * a[10] * a[16] - a[5] * a[12] * a[14] - a[9]  * a[6] * a[16] + a[9]  * a[8] * a[14] + a[13] * a[6] * a[12] - a[13] * a[8] * a[10]
	tm4[10] = -a[1] * a[10] * a[16] + a[1] * a[12] * a[14] + a[9]  * a[2] * a[16] - a[9]  * a[4] * a[14] - a[13] * a[2] * a[12] + a[13] * a[4] * a[10]
	tm4[11] =  a[1] * a[6]  * a[16] - a[1] * a[8]  * a[14] - a[5]  * a[2] * a[16] + a[5]  * a[4] * a[14] + a[13] * a[2] * a[8]  - a[13] * a[4] * a[6]
	tm4[12] = -a[1] * a[6]  * a[12] + a[1] * a[8]  * a[10] + a[5]  * a[2] * a[12] - a[5]  * a[4] * a[10] - a[9]  * a[2] * a[8]  + a[9]  * a[4] * a[6]
	tm4[13] = -a[5] * a[10] * a[15] + a[5] * a[11] * a[14] + a[9]  * a[6] * a[15] - a[9]  * a[7] * a[14] - a[13] * a[6] * a[11] + a[13] * a[7] * a[10]
	tm4[14] =  a[1] * a[10] * a[15] - a[1] * a[11] * a[14] - a[9]  * a[2] * a[15] + a[9]  * a[3] * a[14] + a[13] * a[2] * a[11] - a[13] * a[3] * a[10]
	tm4[15] = -a[1] * a[6]  * a[15] + a[1] * a[7]  * a[14] + a[5]  * a[2] * a[15] - a[5]  * a[3] * a[14] - a[13] * a[2] * a[7]  + a[13] * a[3] * a[6]
	tm4[16] =  a[1] * a[6]  * a[11] - a[1] * a[7]  * a[10] - a[5]  * a[2] * a[11] + a[5]  * a[3] * a[10] + a[9]  * a[2] * a[7]  - a[9]  * a[3] * a[6]

	for i=1, 16 do
		out[i] = tm4[i]
	end

	local det = a[1] * out[1] + a[2] * out[5] + a[3] * out[9] + a[4] * out[13]

	if det == 0 then return a end

	det = 1 / det

	for i = 1, 16 do
		out[i] = out[i] * det
	end

	return out
end

--- Scale a matrix.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Matrix to scale
-- @tparam vec3 s Scalar
-- @treturn mat4 out
function mat4.scale(out, a, s)
	identity(tmp)
	tmp[1]  = s.x
	tmp[6]  = s.y
	tmp[11] = s.z

	return out:mul(tmp, a)
end

--- Rotate a matrix.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Matrix to rotate
-- @tparam number angle Angle to rotate by (in radians)
-- @tparam vec3 axis Axis to rotate on
-- @treturn mat4 out
function mat4.rotate(out, a, angle, axis)
	if type(angle) == "table" or type(angle) == "cdata" then
		angle, axis = angle:to_angle_axis()
	end

	local l = axis:len()

	if l == 0 then
		return a
	end

	local x, y, z = axis.x / l, axis.y / l, axis.z / l
	local c = cos(angle)
	local s = sin(angle)

	identity(tmp)
	tmp[1]  = x * x * (1 - c) + c
	tmp[2]  = y * x * (1 - c) + z * s
	tmp[3]  = x * z * (1 - c) - y * s
	tmp[5]  = x * y * (1 - c) - z * s
	tmp[6]  = y * y * (1 - c) + c
 	tmp[7]  = y * z * (1 - c) + x * s
	tmp[9]  = x * z * (1 - c) + y * s
	tmp[10] = y * z * (1 - c) - x * s
	tmp[11] = z * z * (1 - c) + c

	return out:mul(tmp, a)
end

--- Translate a matrix.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Matrix to translate
-- @tparam vec3 t Translation vector
-- @treturn mat4 out
function mat4.translate(out, a, t)
	identity(tmp)
	tmp[13] = t.x
	tmp[14] = t.y
	tmp[15] = t.z

	return out:mul(tmp, a)
end

--- Shear a matrix.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Matrix to translate
-- @tparam number yx
-- @tparam number zx
-- @tparam number xy
-- @tparam number zy
-- @tparam number xz
-- @tparam number yz
-- @treturn mat4 out
function mat4.shear(out, a, yx, zx, xy, zy, xz, yz)
	identity(tmp)
	tmp[2]  = yx or 0
	tmp[3]  = zx or 0
	tmp[5]  = xy or 0
	tmp[7]  = zy or 0
	tmp[9]  = xz or 0
	tmp[10] = yz or 0

	return out:mul(tmp, a)
end

--- Reflect a matrix across a plane.
-- @tparam mat4 Matrix to store the result
-- @tparam a Matrix to reflect
-- @tparam vec3 position A point on the plane
-- @tparam vec3 normal The (normalized!) normal vector of the plane
function mat4.reflect(out, a, position, normal)
	local nx, ny, nz = normal:unpack()
	local d = -position:dot(normal)
	tmp[1] = 1 - 2 * nx ^ 2
	tmp[2] = 2 * nx * ny
	tmp[3] = -2 * nx * nz
	tmp[4] = 0
	tmp[5] = -2 * nx * ny
	tmp[6] = 1 - 2 * ny ^ 2
	tmp[7] = -2 * ny * nz
	tmp[8] = 0
	tmp[9] = -2 * nx * nz
	tmp[10] = -2 * ny * nz
	tmp[11] = 1 - 2 * nz ^ 2
	tmp[12] = 0
	tmp[13] = -2 * nx * d
	tmp[14] = -2 * ny * d
	tmp[15] = -2 * nz * d
	tmp[16] = 1

	return out:mul(tmp, a)
end

--- Transform matrix to look at a point.
-- @tparam mat4 out Matrix to store result
-- @tparam mat4 a Matrix to transform
-- @tparam vec3 eye Location of viewer's view plane
-- @tparam vec3 center Location of object to view
-- @tparam vec3 up Up direction
-- @treturn mat4 out
function mat4.look_at(out, a, eye, look_at, up)
	local z_axis = (eye - look_at):normalize()
	local x_axis = up:cross(z_axis):normalize()
	local y_axis = z_axis:cross(x_axis)
	out[1] = x_axis.x
	out[2] = y_axis.x
	out[3] = z_axis.x
	out[4] = 0
	out[5] = x_axis.y
	out[6] = y_axis.y
	out[7] = z_axis.y
	out[8] = 0
	out[9] = x_axis.z
	out[10] = y_axis.z
	out[11] = z_axis.z
	out[12] = 0
	out[13] = -out[  1]*eye.x - out[4+1]*eye.y - out[8+1]*eye.z
	out[14] = -out[  2]*eye.x - out[4+2]*eye.y - out[8+2]*eye.z
	out[15] = -out[  3]*eye.x - out[4+3]*eye.y - out[8+3]*eye.z
	out[16] = -out[  4]*eye.x - out[4+4]*eye.y - out[8+4]*eye.z + 1

  return out
end

--- Transpose a matrix.
-- @tparam mat4 out Matrix to store the result
-- @tparam mat4 a Matrix to transpose
-- @treturn mat4 out
function mat4.transpose(out, a)
	tm4[1]  = a[1]
	tm4[2]  = a[5]
	tm4[3]  = a[9]
	tm4[4]  = a[13]
	tm4[5]  = a[2]
	tm4[6]  = a[6]
	tm4[7]  = a[10]
	tm4[8]  = a[14]
	tm4[9]  = a[3]
	tm4[10] = a[7]
	tm4[11] = a[11]
	tm4[12] = a[15]
	tm4[13] = a[4]
	tm4[14] = a[8]
	tm4[15] = a[12]
	tm4[16] = a[16]

	for i=1, 16 do
		out[i] = tm4[i]
	end

	return out
end

-- https://github.com/g-truc/glm/blob/master/glm/gtc/matrix_transform.inl#L518
--- Project a matrix from world space to screen space.
-- @tparam vec3 obj Object position in world space
-- @tparam mat4 view View matrix
-- @tparam mat4 projection Projection matrix
-- @tparam table viewport XYWH of viewport
-- @treturn vec3 win
function mat4.project(obj, view, projection, viewport)
	local position = { obj.x, obj.y, obj.z, 1 }

	mat4.mul_vec4(position, view,       position)
	mat4.mul_vec4(position, projection, position)

	position[1] = position[1] / position[4] * 0.5 + 0.5
	position[2] = position[2] / position[4] * 0.5 + 0.5
	position[3] = position[3] / position[4] * 0.5 + 0.5

	position[1] = position[1] * viewport[3] + viewport[1]
	position[2] = position[2] * viewport[4] + viewport[2]

	return vec3(position[1], position[2], position[3])
end

-- https://github.com/g-truc/glm/blob/master/glm/gtc/matrix_transform.inl#L544
--- Unproject a matrix from screen space to world space.
-- @tparam vec3 win Object position in screen space
-- @tparam mat4 view View matrix
-- @tparam mat4 projection Projection matrix
-- @tparam table viewport XYWH of viewport
-- @treturn vec3 obj
function mat4.unproject(win, view, projection, viewport)
	local position = { win.x, win.y, win.z, 1 }

	position[1] = (position[1] - viewport[1]) / viewport[3]
	position[2] = (position[2] - viewport[2]) / viewport[4]

	position[1] = position[1] * 2 - 1
	position[2] = position[2] * 2 - 1
	position[3] = position[3] * 2 - 1

	tmp:mul(projection, view):invert(tmp)
	mat4.mul_vec4(position, tmp, position)

	position[1] = position[1] / position[4]
	position[2] = position[2] / position[4]
	position[3] = position[3] / position[4]

	return vec3(position[1], position[2], position[3])
end

--- Return a boolean showing if a table is or is not a mat4.
-- @tparam mat4 a Matrix to be tested
-- @treturn boolean is_mat4
function mat4.is_mat4(a)
	if type(a) == "cdata" then
		return ffi.istype("cpml_mat4", a)
	end

	if type(a) ~= "table" then
		return false
	end

	for i = 1, 16 do
		if type(a[i]) ~= "number" then
			return false
		end
	end

	return true
end

--- Return a formatted string.
-- @tparam mat4 a Matrix to be turned into a string
-- @treturn string formatted
function mat4.to_string(a)
	local str = "[ "
	for i = 1, 16 do
		str = str .. string.format("%+0.3f", a[i])
		if i < 16 then
			str = str .. ", "
		end
	end
	str = str .. " ]"
	return str
end

--- Convert a matrix to row vec4s.
-- @tparam mat4 a Matrix to be converted
-- @treturn table vec4s
function mat4.to_vec4s(a)
	return {
		{ a[1],  a[2],  a[3],  a[4]  },
		{ a[5],  a[6],  a[7],  a[8]  },
		{ a[9],  a[10], a[11], a[12] },
		{ a[13], a[14], a[15], a[16] }
	}
end

--- Convert a matrix to col vec4s.
-- @tparam mat4 a Matrix to be converted
-- @treturn table vec4s
function mat4.to_vec4s_cols(a)
	return {
		{ a[1], a[5], a[9],  a[13] },
		{ a[2], a[6], a[10], a[14] },
		{ a[3], a[7], a[11], a[15] },
		{ a[4], a[8], a[12], a[16] }
	}
end

-- http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/
--- Convert a matrix to a quaternion.
-- @tparam mat4 a Matrix to be converted
-- @treturn quat out
function mat4.to_quat(a)
	identity(tmp):transpose(a)

	local w     = sqrt(1 + tmp[1] + tmp[6] + tmp[11]) / 2
	local scale = w * 4
	local q     = quat.new(
		tmp[10] - tmp[7] / scale,
		tmp[3]  - tmp[9] / scale,
		tmp[5]  - tmp[2] / scale,
		w
	)

	return q:normalize(q)
end

-- http://www.crownandcutlass.com/features/technicaldetails/frustum.html
--- Convert a matrix to a frustum.
-- @tparam mat4 a Matrix to be converted (projection * view)
-- @tparam boolean infinite Infinite removes the far plane
-- @treturn frustum out
function mat4.to_frustum(a, infinite)
	local t
	local frustum = {}

	-- Extract the LEFT plane
	frustum.left   = {}
	frustum.left.a = a[4]  + a[1]
	frustum.left.b = a[8]  + a[5]
	frustum.left.c = a[12] + a[9]
	frustum.left.d = a[16] + a[13]

	-- Normalize the result
	t = sqrt(frustum.left.a * frustum.left.a + frustum.left.b * frustum.left.b + frustum.left.c * frustum.left.c)
	frustum.left.a = frustum.left.a / t
	frustum.left.b = frustum.left.b / t
	frustum.left.c = frustum.left.c / t
	frustum.left.d = frustum.left.d / t

	-- Extract the RIGHT plane
	frustum.right   = {}
	frustum.right.a = a[4]  - a[1]
	frustum.right.b = a[8]  - a[5]
	frustum.right.c = a[12] - a[9]
	frustum.right.d = a[16] - a[13]

	-- Normalize the result
	t = sqrt(frustum.right.a * frustum.right.a + frustum.right.b * frustum.right.b + frustum.right.c * frustum.right.c)
	frustum.right.a = frustum.right.a / t
	frustum.right.b = frustum.right.b / t
	frustum.right.c = frustum.right.c / t
	frustum.right.d = frustum.right.d / t

	-- Extract the BOTTOM plane
	frustum.bottom   = {}
	frustum.bottom.a = a[4]  + a[2]
	frustum.bottom.b = a[8]  + a[6]
	frustum.bottom.c = a[12] + a[10]
	frustum.bottom.d = a[16] + a[14]

	-- Normalize the result
	t = sqrt(frustum.bottom.a * frustum.bottom.a + frustum.bottom.b * frustum.bottom.b + frustum.bottom.c * frustum.bottom.c)
	frustum.bottom.a = frustum.bottom.a / t
	frustum.bottom.b = frustum.bottom.b / t
	frustum.bottom.c = frustum.bottom.c / t
	frustum.bottom.d = frustum.bottom.d / t

	-- Extract the TOP plane
	frustum.top   = {}
	frustum.top.a = a[4]  - a[2]
	frustum.top.b = a[8]  - a[6]
	frustum.top.c = a[12] - a[10]
	frustum.top.d = a[16] - a[14]

	-- Normalize the result
	t = sqrt(frustum.top.a * frustum.top.a + frustum.top.b * frustum.top.b + frustum.top.c * frustum.top.c)
	frustum.top.a = frustum.top.a / t
	frustum.top.b = frustum.top.b / t
	frustum.top.c = frustum.top.c / t
	frustum.top.d = frustum.top.d / t

	-- Extract the NEAR plane
	frustum.near   = {}
	frustum.near.a = a[4]  + a[3]
	frustum.near.b = a[8]  + a[7]
	frustum.near.c = a[12] + a[11]
	frustum.near.d = a[16] + a[15]

	-- Normalize the result
	t = sqrt(frustum.near.a * frustum.near.a + frustum.near.b * frustum.near.b + frustum.near.c * frustum.near.c)
	frustum.near.a = frustum.near.a / t
	frustum.near.b = frustum.near.b / t
	frustum.near.c = frustum.near.c / t
	frustum.near.d = frustum.near.d / t

	if not infinite then
		-- Extract the FAR plane
		frustum.far   = {}
		frustum.far.a = a[4]  - a[3]
		frustum.far.b = a[8]  - a[7]
		frustum.far.c = a[12] - a[11]
		frustum.far.d = a[16] - a[15]

		-- Normalize the result
		t = sqrt(frustum.far.a * frustum.far.a + frustum.far.b * frustum.far.b + frustum.far.c * frustum.far.c)
		frustum.far.a = frustum.far.a / t
		frustum.far.b = frustum.far.b / t
		frustum.far.c = frustum.far.c / t
		frustum.far.d = frustum.far.d / t
	end

	return frustum
end

mat4_mt.__index = mat4
-- function mat4_mt.__index(t, k)
-- 	if type(t) == "cdata" then
-- 		if type(k) == "number" then
-- 			return t._m[k-1]
-- 		end
-- 	end

-- 	return rawget(mat4, k)
-- end

function mat4_mt.__newindex(t, k, v)
	if type(t) == "cdata" then
		if type(k) == "number" then
			t._m[k-1] = v
		end
	end
end

mat4_mt.__tostring = mat4.to_string

function mat4_mt.__call(_, a)
	return mat4.new(a)
end

function mat4_mt.__unm(a)
	return new():invert(a)
end

function mat4_mt.__eq(a, b)
	if not mat4.is_mat4(a) or not mat4.is_mat4(b) then
		return false
	end

	for i = 1, 16 do
		if not utils.tolerance(b[i]-a[i], constants.FLT_EPSILON) then
			return false
		end
	end

	return true
end

function mat4_mt.__mul(a, b)
	assert(mat4.is_mat4(a), "__mul: Wrong argument type for left hand operand. (<cpml.mat4> expected)")

	if vec3.is_vec3(b) then
		return vec3(mat4.mul_vec4({}, a, { b.x, b.y, b.z, 1 }))
	end

	assert(mat4.is_mat4(b) or #b == 4, "__mul: Wrong argument type for right hand operand. (<cpml.mat4> or table #4 expected)")

	if mat4.is_mat4(b) then
		return new():mul(a, b)
	end

	return mat4.mul_vec4({}, a, b)
end

if status then
	xpcall(function() -- Allow this to silently fail; assume failure means someone messed with package.loaded
		ffi.metatype(new, mat4_mt)
	end, function() end)
end

mat4 = setmetatable({}, mat4_mt)


end

--
-- BLOCK intersect
--

do
-- https://blogs.msdn.microsoft.com/rezanour/2011/08/07/barycentric-coordinates-and-point-in-triangle-tests/
-- point       is a vec3
-- triangle[1] is a vec3
-- triangle[2] is a vec3
-- triangle[3] is a vec3
function intersect.point_triangle(point, triangle)
	local u = triangle[2] - triangle[1]
	local v = triangle[3] - triangle[1]
	local w = point       - triangle[1]

	local vw = v:cross(w)
	local vu = v:cross(u)

	if vw:dot(vu) < 0 then
		return false
	end

	local uw = u:cross(w)
	local uv = u:cross(v)

	if uw:dot(uv) < 0 then
		return false
	end

	local d = uv:len()
	local r = vw:len() / d
	local t = uw:len() / d

	return r + t <= 1
end

-- point    is a vec3
-- aabb.min is a vec3
-- aabb.max is a vec3
function intersect.point_aabb(point, aabb)
	return
		aabb.min.x <= point.x and
		aabb.max.x >= point.x and
		aabb.min.y <= point.y and
		aabb.max.y >= point.y and
		aabb.min.z <= point.z and
		aabb.max.z >= point.z
end

-- point          is a vec3
-- frustum.left   is a plane { a, b, c, d }
-- frustum.right  is a plane { a, b, c, d }
-- frustum.bottom is a plane { a, b, c, d }
-- frustum.top    is a plane { a, b, c, d }
-- frustum.near   is a plane { a, b, c, d }
-- frustum.far    is a plane { a, b, c, d }
function intersect.point_frustum(point, frustum)
	local x, y, z = point:unpack()
	local planes  = {
		frustum.left,
		frustum.right,
		frustum.bottom,
		frustum.top,
		frustum.near,
		frustum.far or false
	}

	-- Skip the last test for infinite projections, it'll never fail.
	if not planes[6] then
		table.remove(planes)
	end

	local dot
	for i = 1, #planes do
		dot = planes[i].a * x + planes[i].b * y + planes[i].c * z + planes[i].d
		if dot <= 0 then
			return false
		end
	end

	return true
end

-- http://www.lighthouse3d.com/tutorials/maths/ray-triangle-intersection/
-- ray.position  is a vec3
-- ray.direction is a vec3
-- triangle[1]   is a vec3
-- triangle[2]   is a vec3
-- triangle[3]   is a vec3
-- backface_cull is a boolean (optional)
function intersect.ray_triangle(ray, triangle, backface_cull)
	local e1 = triangle[2] - triangle[1]
	local e2 = triangle[3] - triangle[1]
	local h  = ray.direction:cross(e2)
	local a  = h:dot(e1)

	-- if a is negative, ray hits the backface
	if backface_cull and a < 0 then
		return false
	end

	-- if a is too close to 0, ray does not intersect triangle
	if abs(a) <= DBL_EPSILON then
		return false
	end

	local f = 1 / a
	local s = ray.position - triangle[1]
	local u = s:dot(h) * f

	-- ray does not intersect triangle
	if u < 0 or u > 1 then
		return false
	end

	local q = s:cross(e1)
	local v = ray.direction:dot(q) * f

	-- ray does not intersect triangle
	if v < 0 or u + v > 1 then
		return false
	end

	-- at this stage we can compute t to find out where
	-- the intersection point is on the line
	local t = q:dot(e2) * f

	-- return position of intersection and distance from ray origin
	if t >= DBL_EPSILON then
		return ray.position + ray.direction * t, t
	end

	-- ray does not intersect triangle
	return false
end

-- https://gamedev.stackexchange.com/questions/96459/fast-ray-sphere-collision-code
-- ray.position    is a vec3
-- ray.direction   is a vec3
-- sphere.position is a vec3
-- sphere.radius   is a number
function intersect.ray_sphere(ray, sphere)
	local offset = ray.position - sphere.position
	local b = offset:dot(ray.direction)
	local c = offset:dot(offset) - sphere.radius * sphere.radius

	-- ray's position outside sphere (c > 0)
	-- ray's direction pointing away from sphere (b > 0)
	if c > 0 and b > 0 then
		return false
	end

	local discr = b * b - c

	-- negative discriminant
	if discr < 0 then
		return false
	end

	-- Clamp t to 0
	local t = -b - sqrt(discr)
	t = t < 0 and 0 or t

	-- Return collision point and distance from ray origin
	return ray.position + ray.direction * t, t
end

-- http://gamedev.stackexchange.com/a/18459
-- ray.position  is a vec3
-- ray.direction is a vec3
-- aabb.min      is a vec3
-- aabb.max      is a vec3
function intersect.ray_aabb(ray, aabb)
	local dir     = ray.direction:normalize()
	local dirfrac = vec3(
		1 / dir.x,
		1 / dir.y,
		1 / dir.z
	)

	local t1 = (aabb.min.x - ray.position.x) * dirfrac.x
	local t2 = (aabb.max.x - ray.position.x) * dirfrac.x
	local t3 = (aabb.min.y - ray.position.y) * dirfrac.y
	local t4 = (aabb.max.y - ray.position.y) * dirfrac.y
	local t5 = (aabb.min.z - ray.position.z) * dirfrac.z
	local t6 = (aabb.max.z - ray.position.z) * dirfrac.z

	local tmin = max(max(min(t1, t2), min(t3, t4)), min(t5, t6))
	local tmax = min(min(max(t1, t2), max(t3, t4)), max(t5, t6))

	-- ray is intersecting AABB, but whole AABB is behind us
	if tmax < 0 then
		return false
	end

	-- ray does not intersect AABB
	if tmin > tmax then
		return false
	end

	-- Return collision point and distance from ray origin
	return ray.position + ray.direction * tmin, tmin
end

-- http://stackoverflow.com/a/23976134/1190664
-- ray.position   is a vec3
-- ray.direction  is a vec3
-- plane.position is a vec3
-- plane.normal   is a vec3
function intersect.ray_plane(ray, plane)
	local denom = plane.normal:dot(ray.direction)

	-- ray does not intersect plane
	if abs(denom) < DBL_EPSILON then
		return false
	end

	-- distance of direction
	local d = plane.position - ray.position
	local t = d:dot(plane.normal) / denom

	if t < DBL_EPSILON then
		return false
	end

	-- Return collision point and distance from ray origin
	return ray.position + ray.direction * t, t
end

function intersect.ray_capsule(ray, capsule)
	local dist2, p1, p2 = intersect.closest_point_segment_segment(
		ray.position,
		ray.position + ray.direction * 1e10,
		capsule.a,
		capsule.b
	)
	if dist2 <= capsule.radius^2 then
		return p1
	end

	return false
end

-- https://web.archive.org/web/20120414063459/http://local.wasp.uwa.edu.au/~pbourke//geometry/lineline3d/
-- a[1] is a vec3
-- a[2] is a vec3
-- b[1] is a vec3
-- b[2] is a vec3
-- e    is a number
function intersect.line_line(a, b, e)
	-- new points
	local p13 = a[1] - b[1]
	local p43 = b[2] - b[1]
	local p21 = a[2] - a[1]

	-- if lengths are negative or too close to 0, lines do not intersect
	if p43:len2() < DBL_EPSILON or p21:len2() < DBL_EPSILON then
		return false
	end

	-- dot products
	local d1343 = p13:dot(p43)
	local d4321 = p43:dot(p21)
	local d1321 = p13:dot(p21)
	local d4343 = p43:dot(p43)
	local d2121 = p21:dot(p21)
	local denom = d2121 * d4343 - d4321 * d4321

	-- if denom is too close to 0, lines do not intersect
	if abs(denom) < DBL_EPSILON then
		return false
	end

	local numer = d1343 * d4321 - d1321 * d4343
	local mua   = numer / denom
	local mub   = (d1343 + d4321 * mua) / d4343

	-- return positions of intersection on each line
	local out1 = a[1] + p21 * mua
	local out2 = b[1] + p43 * mub
	local dist = out1:dist(out2)

	-- if distance of the shortest segment between lines is less than threshold
	if e and dist > e then
		return false
	end

	return { out1, out2 }, dist
end

-- a[1] is a vec3
-- a[2] is a vec3
-- b[1] is a vec3
-- b[2] is a vec3
-- e    is a number
function intersect.segment_segment(a, b, e)
	local c, d = intersect.line_line(a, b, e)

	if c and ((
		a[1].x <= c[1].x and
		a[1].y <= c[1].y and
		a[1].z <= c[1].z and
		c[1].x <= a[2].x and
		c[1].y <= a[2].y and
		c[1].z <= a[2].z
	) or (
		a[1].x >= c[1].x and
		a[1].y >= c[1].y and
		a[1].z >= c[1].z and
		c[1].x >= a[2].x and
		c[1].y >= a[2].y and
		c[1].z >= a[2].z
	)) and ((
		b[1].x <= c[2].x and
		b[1].y <= c[2].y and
		b[1].z <= c[2].z and
		c[2].x <= b[2].x and
		c[2].y <= b[2].y and
		c[2].z <= b[2].z
	) or (
		b[1].x >= c[2].x and
		b[1].y >= c[2].y and
		b[1].z >= c[2].z and
		c[2].x >= b[2].x and
		c[2].y >= b[2].y and
		c[2].z >= b[2].z
	)) then
		return c, d
	end

	-- segments do not intersect
	return false
end

-- a.min is a vec3
-- a.max is a vec3
-- b.min is a vec3
-- b.max is a vec3
function intersect.aabb_aabb(a, b)
	return
		a.min.x <= b.max.x and
		a.max.x >= b.min.x and
		a.min.y <= b.max.y and
		a.max.y >= b.min.y and
		a.min.z <= b.max.z and
		a.max.z >= b.min.z
end

-- aabb.position is a vec3
-- aabb.extent   is a vec3 (half-size)
-- obb.position  is a vec3
-- obb.extent    is a vec3 (half-size)
-- obb.rotation  is a mat4
function intersect.aabb_obb(aabb, obb)
	local a   = aabb.extent
	local b   = obb.extent
	local T   = obb.position - aabb.position
	local rot = mat4():transpose(obb.rotation)
	local B   = {}
	local t

	for i = 1, 3 do
		B[i] = {}
		for j = 1, 3 do
			assert((i - 1) * 4 + j < 16 and (i - 1) * 4 + j > 0)
			B[i][j] = abs(rot[(i - 1) * 4 + j]) + 1e-6
		end
	end

	t = abs(T.x)
	if not (t <= (b.x + a.x * B[1][1] + b.y * B[1][2] + b.z * B[1][3])) then return false end
	t = abs(T.x * B[1][1] + T.y * B[2][1] + T.z * B[3][1])
	if not (t <= (b.x + a.x * B[1][1] + a.y * B[2][1] + a.z * B[3][1])) then return false end
	t = abs(T.y)
	if not (t <= (a.y + b.x * B[2][1] + b.y * B[2][2] + b.z * B[2][3])) then return false end
	t = abs(T.z)
	if not (t <= (a.z + b.x * B[3][1] + b.y * B[3][2] + b.z * B[3][3])) then return false end
	t = abs(T.x * B[1][2] + T.y * B[2][2] + T.z * B[3][2])
	if not (t <= (b.y + a.x * B[1][2] + a.y * B[2][2] + a.z * B[3][2])) then return false end
	t = abs(T.x * B[1][3] + T.y * B[2][3] + T.z * B[3][3])
	if not (t <= (b.z + a.x * B[1][3] + a.y * B[2][3] + a.z * B[3][3])) then return false end
	t = abs(T.z * B[2][1] - T.y * B[3][1])
	if not (t <= (a.y * B[3][1] + a.z * B[2][1] + b.y * B[1][3] + b.z * B[1][2])) then return false end
	t = abs(T.z * B[2][2] - T.y * B[3][2])
	if not (t <= (a.y * B[3][2] + a.z * B[2][2] + b.x * B[1][3] + b.z * B[1][1])) then return false end
	t = abs(T.z * B[2][3] - T.y * B[3][3])
	if not (t <= (a.y * B[3][3] + a.z * B[2][3] + b.x * B[1][2] + b.y * B[1][1])) then return false end
	t = abs(T.x * B[3][1] - T.z * B[1][1])
	if not (t <= (a.x * B[3][1] + a.z * B[1][1] + b.y * B[2][3] + b.z * B[2][2])) then return false end
	t = abs(T.x * B[3][2] - T.z * B[1][2])
	if not (t <= (a.x * B[3][2] + a.z * B[1][2] + b.x * B[2][3] + b.z * B[2][1])) then return false end
	t = abs(T.x * B[3][3] - T.z * B[1][3])
	if not (t <= (a.x * B[3][3] + a.z * B[1][3] + b.x * B[2][2] + b.y * B[2][1])) then return false end
	t = abs(T.y * B[1][1] - T.x * B[2][1])
	if not (t <= (a.x * B[2][1] + a.y * B[1][1] + b.y * B[3][3] + b.z * B[3][2])) then return false end
	t = abs(T.y * B[1][2] - T.x * B[2][2])
	if not (t <= (a.x * B[2][2] + a.y * B[1][2] + b.x * B[3][3] + b.z * B[3][1])) then return false end
	t = abs(T.y * B[1][3] - T.x * B[2][3])
	if not (t <= (a.x * B[2][3] + a.y * B[1][3] + b.x * B[3][2] + b.y * B[3][1])) then return false end

	-- https://gamedev.stackexchange.com/questions/24078/which-side-was-hit
	-- Minkowski Sum
	local wy = (aabb.extent * 2 + obb.extent * 2) * (aabb.position.y - obb.position.y)
	local hx = (aabb.extent * 2 + obb.extent * 2) * (aabb.position.x - obb.position.x)

	if wy.x > hx.x and wy.y > hx.y and wy.z > hx.z then
		if wy.x > -hx.x and wy.y > -hx.y and wy.z > -hx.z then
			return vec3(obb.rotation * {  0, -1, 0, 1 })
		else
			return vec3(obb.rotation * { -1,  0, 0, 1 })
		end
	else
		if wy.x > -hx.x and wy.y > -hx.y and wy.z > -hx.z then
			return vec3(obb.rotation * { 1, 0, 0, 1 })
		else
			return vec3(obb.rotation * { 0, 1, 0, 1 })
		end
	end
end

-- http://stackoverflow.com/a/4579069/1190664
-- aabb.min        is a vec3
-- aabb.max        is a vec3
-- sphere.position is a vec3
-- sphere.radius   is a number
local axes = { "x", "y", "z" }
function intersect.aabb_sphere(aabb, sphere)
	local dist2 = sphere.radius ^ 2

	for _, axis in ipairs(axes) do
		local pos  = sphere.position[axis]
		local amin = aabb.min[axis]
		local amax = aabb.max[axis]

		if pos < amin then
			dist2 = dist2 - (pos - amin) ^ 2
		elseif pos > amax then
			dist2 = dist2 - (pos - amax) ^ 2
		end
	end

	return dist2 > 0
end

-- aabb.min       is a vec3
-- aabb.max       is a vec3
-- frustum.left   is a plane { a, b, c, d }
-- frustum.right  is a plane { a, b, c, d }
-- frustum.bottom is a plane { a, b, c, d }
-- frustum.top    is a plane { a, b, c, d }
-- frustum.near   is a plane { a, b, c, d }
-- frustum.far    is a plane { a, b, c, d }
function intersect.aabb_frustum(aabb, frustum)
	-- Indexed for the 'index trick' later
	local box = {
		aabb.min,
		aabb.max
	}

	-- We have 6 planes defining the frustum, 5 if infinite.
	local planes = {
		frustum.left,
		frustum.right,
		frustum.bottom,
		frustum.top,
		frustum.near,
		frustum.far or false
	}

	-- Skip the last test for infinite projections, it'll never fail.
	if not planes[6] then
		table.remove(planes)
	end

	for i = 1, #planes do
		-- This is the current plane
		local p = planes[i]

		-- p-vertex selection (with the index trick)
		-- According to the plane normal we can know the
		-- indices of the positive vertex
		local px = p.a > 0.0 and 2 or 1
		local py = p.b > 0.0 and 2 or 1
		local pz = p.c > 0.0 and 2 or 1

		-- project p-vertex on plane normal
		-- (How far is p-vertex from the origin)
		local dot = (p.a * box[px].x) + (p.b * box[py].y) + (p.c * box[pz].z)

		-- Doesn't intersect if it is behind the plane
		if dot < -p.d then
			return false
		end
	end

	return true
end

-- outer.min is a vec3
-- outer.max is a vec3
-- inner.min is a vec3
-- inner.max is a vec3
function intersect.encapsulate_aabb(outer, inner)
	return
		outer.min.x <= inner.min.x and
		outer.max.x >= inner.max.x and
		outer.min.y <= inner.min.y and
		outer.max.y >= inner.max.y and
		outer.min.z <= inner.min.z and
		outer.max.z >= inner.max.z
end

-- a.position is a vec3
-- a.radius   is a number
-- b.position is a vec3
-- b.radius   is a number
function intersect.circle_circle(a, b)
	return a.position:dist(b.position) <= a.radius + b.radius
end

-- a.position is a vec3
-- a.radius   is a number
-- b.position is a vec3
-- b.radius   is a number
function intersect.sphere_sphere(a, b)
	return intersect.circle_circle(a, b)
end

-- http://realtimecollisiondetection.net/blog/?p=103
-- sphere.position is a vec3
-- sphere.radius   is a number
-- triangle[1]     is a vec3
-- triangle[2]     is a vec3
-- triangle[3]     is a vec3
function intersect.sphere_triangle(sphere, triangle)
	-- Sphere is centered at origin
	local A  = triangle[1] - sphere.position
	local B  = triangle[2] - sphere.position
	local C  = triangle[3] - sphere.position

	-- Compute normal of triangle plane
	local V  = (B - A):cross(C - A)

	-- Test if sphere lies outside triangle plane
	local rr = sphere.radius * sphere.radius
	local d  = A:dot(V)
	local e  = V:dot(V)
	local s1 = d * d > rr * e

	-- Test if sphere lies outside triangle vertices
	local aa = A:dot(A)
	local ab = A:dot(B)
	local ac = A:dot(C)
	local bb = B:dot(B)
	local bc = B:dot(C)
	local cc = C:dot(C)

	local s2 = (aa > rr) and (ab > aa) and (ac > aa)
	local s3 = (bb > rr) and (ab > bb) and (bc > bb)
	local s4 = (cc > rr) and (ac > cc) and (bc > cc)

	-- Test is sphere lies outside triangle edges
	local AB = B - A
	local BC = C - B
	local CA = A - C

	local d1 = ab - aa
	local d2 = bc - bb
	local d3 = ac - cc

	local e1 = AB:dot(AB)
	local e2 = BC:dot(BC)
	local e3 = CA:dot(CA)

	local Q1 = A * e1 - AB * d1
	local Q2 = B * e2 - BC * d2
	local Q3 = C * e3 - CA * d3

	local QC = C * e1 - Q1
	local QA = A * e2 - Q2
	local QB = B * e3 - Q3

	local s5 = (Q1:dot(Q1) > rr * e1 * e1) and (Q1:dot(QC) > 0)
	local s6 = (Q2:dot(Q2) > rr * e2 * e2) and (Q2:dot(QA) > 0)
	local s7 = (Q3:dot(Q3) > rr * e3 * e3) and (Q3:dot(QB) > 0)

	-- Return whether or not any of the tests passed
	return s1 or s2 or s3 or s4 or s5 or s6 or s7
end

-- sphere.position is a vec3
-- sphere.radius   is a number
-- frustum.left    is a plane { a, b, c, d }
-- frustum.right   is a plane { a, b, c, d }
-- frustum.bottom  is a plane { a, b, c, d }
-- frustum.top     is a plane { a, b, c, d }
-- frustum.near    is a plane { a, b, c, d }
-- frustum.far     is a plane { a, b, c, d }
function intersect.sphere_frustum(sphere, frustum)
	local x, y, z = sphere.position:unpack()
	local planes  = {
		frustum.left,
		frustum.right,
		frustum.bottom,
		frustum.top,
		frustum.near
	}

	if frustum.far then
		table.insert(planes, frustum.far, 5)
	end

	local dot
	for i = 1, #planes do
		dot = planes[i].a * x + planes[i].b * y + planes[i].c * z + planes[i].d

		if dot <= -sphere.radius then
			return false
		end
	end

	-- dot + radius is the distance of the object from the near plane.
	-- make sure that the near plane is the last test!
	return dot + sphere.radius
end

function intersect.capsule_capsule(c1, c2)
	local dist2, p1, p2 = intersect.closest_point_segment_segment(c1.a, c1.b, c2.a, c2.b)
	local radius = c1.radius + c2.radius

	if dist2 <= radius * radius then
		return p1, p2
	end

	return false
end

function intersect.closest_point_segment_segment(p1, p2, p3, p4)
	local s  -- Distance of intersection along segment 1
	local t  -- Distance of intersection along segment 2
	local c1 -- Collision point on segment 1
	local c2 -- Collision point on segment 2

	local d1 = p2 - p1 -- Direction of segment 1
	local d2 = p4 - p3 -- Direction of segment 2
	local r  = p1 - p3
	local a  = d1:dot(d1)
	local e  = d2:dot(d2)
	local f  = d2:dot(r)

	-- Check if both segments degenerate into points
	if a <= DBL_EPSILON and e <= DBL_EPSILON then
		s  = 0
		t  = 0
		c1 = p1
		c2 = p3
		return (c1 - c2):dot(c1 - c2), s, t, c1, c2
	end

	-- Check if segment 1 degenerates into a point
	if a <= DBL_EPSILON then
		s = 0
		t = utils.clamp(f / e, 0, 1)
	else
		local c = d1:dot(r)

		-- Check is segment 2 degenerates into a point
		if e <= DBL_EPSILON then
			t = 0
			s = utils.clamp(-c / a, 0, 1)
		else
			local b     = d1:dot(d2)
			local denom = a * e - b * b

			if abs(denom) > 0 then
				s = utils.clamp((b * f - c * e) / denom, 0, 1)
			else
				s = 0
			end

			t = (b * s + f) / e

			if t < 0 then
				t = 0
				s = utils.clamp(-c / a, 0, 1)
			elseif t > 1 then
				t = 1
				s = utils.clamp((b - c) / a, 0, 1)
			end
		end
	end

	c1 = p1 + d1 * s
	c2 = p3 + d2 * t

	return (c1 - c2):dot(c1 - c2), c1, c2, s, t
end


end
