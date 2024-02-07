-- math.lua
--
-- A collection of math utility functions for PICO-8.
--
-- Functions:
--   randib(a,b) --> integer
--   aget(x1,y1,x2,y2) --> float
--   dst(x0,y0,x1,y1) --> float
--   sqr(x) --> float
--
-- Usage:
--   #include "lib/math.lua"
--   local x = randib(1, 10)
--   local y = randb(1, 10)
--   local d = dst(0, 0, 10, 10)
--   local s = sqr(10)
--   local a = aget(0, 0, 10, 10)

function aget(x1,y1,x2,y2) return atan2(-(x1-x2), -(y1-y2)) end

function dst(x0,y0,x1,y1)
    local dx=(x0-x1)/64
    local dy=(y0-y1)/64
    local dsq=dx*dx+dy*dy
    if(dsq<0) return 32767.99999
    return sqrt(dsq)*64
end

function sqr(x) return x*x end

function randib(a,b)
    return flr(rnd(b-a+1))+a
end

function to_degrees(angle)
    return angle*360
end

function map_range(value, original_min, original_max, target_min, target_max)
    local scale = (value - original_min) / (original_max - original_min)
    return target_min + (target_max - target_min) * scale
end

-- function round_float(num, dp)
--     local mult = 10 ^ dp
--     return flr(num * mult) / mult
-- end

function round_float(num, decimal_places)
    local integer_part = flr(num)
    local multiplier = 10 ^ decimal_places
    local decimal_part = flr(num * multiplier) % multiplier
    local decimal_str = tostring(decimal_part)
    while #decimal_str < decimal_places do
        decimal_str = "0" .. decimal_str
    end
    return integer_part .. "." .. decimal_str
end

function randfb(min, max)
    return rnd(max - min) + min
end