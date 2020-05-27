
--local hills_offset = lib_mg_continental.hills_offset
--local hills_thresh = lib_mg_continental.hills_thresh
--local shelf_thresh = lib_mg_continental.shelf_thresh
--local cliffs_thresh = lib_mg_continental.cliffs_thresh


local abs   = math.abs
local max   = math.max
local sqrt  = math.sqrt
local floor = math.floor


function lib_mg_continental.get_terrain_height_shelf(theight)
		-- parabolic gradient
	if theight > 0 and theight < lib_mg_continental.shelf_thresh then
		theight = theight * (theight*theight/(lib_mg_continental.shelf_thresh*lib_mg_continental.shelf_thresh)*0.5 + 0.5)
	end

	return theight
end

function lib_mg_continental.get_terrain_height_hills_adjustable_shelf(theight,hheight,cheight,shlf_thresh)
		-- parabolic gradient
	if theight > 0 and theight < shlf_thresh then
		theight = theight * (theight*theight/(shlf_thresh*shlf_thresh)*0.5 + 0.5)
	end	
		-- hills
	if theight > lib_mg_continental.hills_thresh then
		theight = theight + math.max((theight-lib_mg_continental.hills_thresh) * hheight,0)
		-- cliffs
	elseif theight > 1 and theight < lib_mg_continental.hills_thresh then 
		local clifh = math.max(math.min(cheight,1),0) 
		if clifh > 0 then
			clifh = -1*(clifh-1)*(clifh-1) + 1
			theight = theight + (lib_mg_continental.hills_thresh-theight) * clifh * ((theight<2) and theight-1 or 1)
		end
	end
	return theight
end

function lib_mg_continental.get_distance(a,b)						--get_distance(a,b)
    return (max(abs(a.x-b.x), abs(a.y-b.y)))					--returns the chebyshev distance between two points
end

function lib_mg_continental.get_avg_distance(a,b)						--get_avg_distance(a,b)
    return ((abs(a.x-b.x) + abs(a.y-b.y)) * 0.5)					--returns the average distance between two points
end

function lib_mg_continental.get_manhattan_distance(a,b)					--get_manhattan_distance(a,b)
    return (abs(a.x-b.x) + abs(a.y-b.y))					--returns the manhattan distance between two points
end

function lib_mg_continental.get_euclid_distance(a,b)
	local dx = a.x - b.x
	local dy = a.y - b.y
	return (dx*dx+dy*dy)^0.5
end

function lib_mg_continental.get_midpoint(a,b)						--get_midpoint(a,b)
	return ((a.x+b.x) * 0.5), ((a.y+b.y) * 0.5)					--returns the midpoint between two points
end

local function get_2d_triangulation(a,b,c)					--get_2d_triangulation(a,b,c)
	return ((a.x+b.x+c.x)/3), ((a.y+b.y+c.y)/3)				--returns the triangulated point between three points (average pos)
end

local function get_3d_triangulation(a,b,c)					--get_3d_triangulation(a,b,c)
	return ((a.x+b.x+c.x)/3), ((a.y+b.y+c.y)/3), ((a.z+b.z+c.z)/3)		--returns the 3D triangulated point between three points (average pos)
end




local function lerp(noise_a, noise_b, n_mod)
	return noise_a * (1 - n_mod) + noise_b * n_mod
end

local function steps(noise, h)
	local w = math.abs(noise)				--n_base
	local k = math.floor(h / w)
	local f = (h - k * w) / w
	local s = math.min(2 * f, 1.0)
	return (k + s) * w
end

local function bias(noise, bias)
	return (noise / ((((1.0 / bias) - 2.0) * (1.0 - noise)) + 1.0))
end

local function gain(noise, gain)
	if noise < 0.5 then
		return bias(noise * 2.0, gain) / 2.0
	else
		return bias(noise * 2.0 - 1.0, 1.0 - gain) / 2.0 + 0.5
	end
end





















