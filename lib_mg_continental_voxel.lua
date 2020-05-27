

minetest.set_mapgen_setting('mg_name','singlenode',true)
minetest.set_mapgen_setting('flags','nolight',true)
--minetest.set_mapgen_params({mgname="singlenode"})

--local storage = minetest.get_mod_storage()

--if lib_mg_continental.nodes == "default" then
	--local c_sand		= minetest.get_content_id("default:sand")
	--local c_stone		= minetest.get_content_id("default:stone")
	--local c_dirt		= minetest.get_content_id("default:dirt")
	--local c_dirtgrass	= minetest.get_content_id("default:dirt_with_grass")
	--local c_dirtgreengrass	= minetest.get_content_id("default:dirt_with_grass")
	--local c_water		= minetest.get_content_id("default:water_source")
--elseif lib_mg_continental.nodes == "lib_materials" then
	local c_desertsand	= minetest.get_content_id("lib_materials:sand_desert")
	local c_desertsandstone	= minetest.get_content_id("lib_materials:stone_sandstone_desert")
	local c_desertstone	= minetest.get_content_id("lib_materials:stone_desert")
	local c_sand		= minetest.get_content_id("lib_materials:sand")
	local c_sandstone	= minetest.get_content_id("lib_materials:stone_sandstone")
	local c_stone		= minetest.get_content_id("lib_materials:stone")
	--local c_brick		= minetest.get_content_id("lib_materials:stone_brick")
	--local c_block		= minetest.get_content_id("lib_materials:stone_block")
	--local c_desertstoneblock= minetest.get_content_id("lib_materials:stone_desert_block")
	--local c_desertstonebrick= minetest.get_content_id("lib_materials:stone_desert_brick")
	local c_obsidian	= minetest.get_content_id("lib_materials:stone_obsidian")
	local c_dirt		= minetest.get_content_id("lib_materials:dirt")
	local c_dirtgrass	= minetest.get_content_id("lib_materials:dirt_with_grass")
	local c_dirtdrygrass	= minetest.get_content_id("lib_materials:dirt_with_grass_dry")
	local c_dirtbrowngrass	= minetest.get_content_id("lib_materials:dirt_with_grass_brown")
	local c_dirtgreengrass		= minetest.get_content_id("lib_materials:dirt_with_grass_green")
	local c_dirtjunglegrass	= minetest.get_content_id("lib_materials:dirt_with_grass_jungle_01")
	local c_dirtperma	= minetest.get_content_id("lib_materials:dirt_permafrost")
	local c_top		= minetest.get_content_id("lib_materials:dirt_with_grass_green")
	local c_coniferous	= minetest.get_content_id("lib_materials:litter_coniferous")
	local c_rainforest	= minetest.get_content_id("lib_materials:litter_rainforest")
	local c_snow		= minetest.get_content_id("lib_materials:dirt_with_snow")
	local c_water		= minetest.get_content_id("lib_materials:liquid_water_source")
	local c_river		= minetest.get_content_id("lib_materials:liquid_water_river_source")
	local c_muddy		= minetest.get_content_id("lib_materials:liquid_water_river_muddy_source")
	local c_swamp		= minetest.get_content_id("lib_materials:liquid_water_swamp_source")
	local c_tree		= minetest.get_content_id("lib_ecology:tree_default_trunk")
--end

local c_air		= minetest.get_content_id("air")
local c_ignore		= minetest.get_content_id("ignore")

local abs   = math.abs
local max   = math.max
local min   = math.min
local sqrt  = math.sqrt
local floor = math.floor
local modf = math.modf
local random = math.random

local mult = 1.0				--lib_materials.mapgen_scale_factor or 8
local c_mult = mult				--lib_materials.mapgen_scale_factor or 8
local mg_noise_spread = 240
local mg_distance_measurement = "m"
local mg_scale_factor = mult
local voronoi_scaled = true

				--729	--358	--31	--29	--43	--17	--330	--83
--[[
	729 = 9^3	358 = 7^2 + 15		693 = 9*11*7		15^3 = 3375
	1331 = 11^3	2431 = 13*17*11		4913 = 17^3		13^3 = 2197
--]]

local voronoi_type = "recursive"     --"single" or "recursive"
local voronoi_cells = 2197
local voronoi_recursion_1 = 17
local voronoi_recursion_2 = 17
local voronoi_recursion_3 = 17

local convex = false

local map_size = 60000
local map_world_size = 10000
local map_base_scale = 100
local map_size_scale = 10
local map_scale = map_base_scale * map_size_scale

--3    0.1    0.05
local map_noise_scale_multiplier = 5
local map_tectonic_scale = map_world_size / map_scale					--10000 / (100 * 10) = 10
local map_noise_scale = map_tectonic_scale * map_noise_scale_multiplier			--10 * 3

local v_cscale
local v_mscale
if voronoi_scaled == true then
--defaults
		--v_cscale = 0.1
		--v_mscale = 0.125
		--v_cscale = 0.0125*mult
	v_cscale = 0.025 * mult
	--v_cscale = 0.5 * mult
		--v_cscale = 0.03125*mult
		--v_cscale = 0.05*mult
		--v_pscale = 0.01875*mult
	v_pscale = 0.05 * mult
	--v_pscale = 1.0 * mult
		--v_pscale = 0.05*mult
		--v_pscale = 0.075*mult
		--v_pscale = 0.1*mult
		--v_mscale = 0.03125*mult
	v_mscale = 0.0625 * mult
	--v_mscale = 1.25 * mult
		--v_mscale = 0.125*mult
		--v_mscale = 0.03125*mult
		--v_cscale = 0.05
		--v_mscale = 0.0625
else
	v_cscale = 0.005
	v_pscale = 0.01
	v_mscale = 0.0125
end

--loads default data set from mod path.  If false, or not found, will attempt to load data from world path.  If data not found, data is generated.
local voronoi_mod_defaults = false

local heightmap_base = 5
local noisemap_base = 7
local cliffmap_base = 7
		
local mg_golden_ratio = ((1 + (5^0.5)) * 0.5)				-- is 1.61803398875
local mg_golden_ratio_double = mg_golden_ratio * 2			-- is 3.2360679775
local mg_golden_ratio_half = mg_golden_ratio * 0.5			-- is 0.809016994375
local mg_golden_ratio_tenth = mg_golden_ratio * 0.1			-- is 0.161803398875
local mg_golden_ratio_fivetenths = mg_golden_ratio * 0.05		-- is 0.0809016994375

	--euler_mascheroni_const = 0.5772156649-0153286060-6512090082-4024310421-5933593992
local euler_mascheroni_const = 0.5772156649
	--euler_number = 2.7182818284-5904523536-0287471352-6624977572-4709369995
local euler_number = 2.7182818284
--##		
--##		sqrt(2) = 1.41421356237
--##		sqrt(3) = 1.73205080757
--##		sqrt(5) = 2.2360679775
--##		sqrt(6) = 2.44948974278
--##		sqrt(7) = 2.64575131106
--##		sqrt(8) = 2.82842712475
--##		sqrt(10) = 3.16227766017
--##		sqrt(11) = 3.31662479036
--##		sqrt(12) = 3.46410161514
--##		sqrt(13) = 3.60555127546
--##		sqrt(14) = 3.74165738677
--##		sqrt(15) = 3.87298334621
--##		sqrt(17) = 4.12310562562
--##		sqrt(18) = 4.24264068712
--##		sqrt(19) = 4.35889894354
--##		sqrt() = 
--##		pi = 3.14159265359
--##		
--##		


local np_terrain = {
	offset = 0,
	scale = (mg_noise_spread * 0.25) * mult,
	seed = 5934,
	spread = {x = ((mg_noise_spread * 10) * mult), y = ((mg_noise_spread * 10) * mult), z = ((mg_noise_spread * 10) * mult)},
	octaves = 5,			--8				higher =
	persist = 0.6,			--0.625				higher = rougher
	lacunarity = 2.19,		--2.19		--1.89 or 2.0 or 2.11		lower = rougher
	--flags = "defaults"
}

--[[
local np_terrain = {
	offset = -4,
	scale = map_noise_scale,
	seed = 5934,
	spread = {x = ((map_world_size/map_size_scale)*mult), y = ((map_world_size/map_size_scale)*mult), z = ((map_world_size/map_size_scale)*mult)},
	octaves = 5,			--8				higher =
	persist = 0.6,			--0.625				higher = rougher
	lacunarity = 2.19,		--2.19		--1.89 or 2.0 or 2.11		lower = rougher
	--flags = "defaults"
}
--]]
--	seed = 567891,
local np_var = {
	offset = 0,						
	scale = 60*mult,
	spread = {x = 640*mult, y =640*mult, z = 640*mult},
	seed = 567891,
	octaves = 4,
	persist = 0.4,
	lacunarity = 1.89,
	--flags = "eased"
}
--
--	spread = {x = 32, y =32, z = 32},
--	seed = 2345,
local np_hills = {
	offset = 2.5,					-- off/scale ~ 2:3
	scale = -3.5,
	spread = {x = 640*mult, y =640*mult, z = 640*mult},
	seed = 5934,
	octaves = 3,
	persist = 0.40,
	lacunarity = 2.0,
	flags = "absvalue"
}
--
--	seed = 78901,
local np_cliffs = {
	offset = 0,					
	scale = 0.72,
	spread = {x = 1800*c_mult, y = 1800*c_mult, z = 1800*c_mult},
	seed = 5934,
	octaves = 2,
	persist = 0.4,
	lacunarity = 2.11,
--	flags = "absvalue"
}

local np_heat = {
	flags = "defaults",
	lacunarity = 2,
	offset = 50,
	scale = 50,
	spread = {x = 1000, y = 1000, z = 1000},
	seed = 5349,
	octaves = 3,
	persistence = 0.5,
}
local np_heat_blend = {
	flags = "defaults",
	lacunarity = 2,
	offset = 0,
	scale = 1.5,
	spread = {x = 8, y = 8, z = 8},
	seed = 13,
	octaves = 2,
	persistence = 1,
}
local np_humid = {
	flags = "defaults",
	lacunarity = 2,
	offset = 50,
	scale = 50,
	spread = {x = 1000, y = 1000, z = 1000},
	seed = 842,
	octaves = 3,
	persistence = 0.5,
}
local np_humid_blend = {
	flags = "defaults",
	lacunarity = 2,
	offset = 0,
	scale = 1.5,
	spread = {x = 8, y = 8, z = 8},
	seed = 90003,
	octaves = 2,
	persistence = 1,
}

local nobj_terrain = nil
local isln_terrain = nil

local nobj_var = nil
local isln_var = nil

local nobj_hills = nil
local isln_hills = nil

local nobj_cliffs = nil
local isln_cliffs = nil

local nobj_heatmap = nil
local nbase_heatmap = nil
local nobj_heatblend = nil
local nbase_heatblend = nil
local nobj_humiditymap = nil
local nbase_humiditymap = nil
local nobj_humidityblend = nil
local nbase_humidityblend = nil

lib_mg_continental.points = {}
--lib_mg_continental.cells = {}
--lib_mg_continental.vertices = {}

--lib_mg_continental.current_ccell_idx = 0
--lib_mg_continental.current_ccell_neighbors = {}
--lib_mg_continental.current_ccell_vertices = {}

--lib_mg_continental.current_pcell_idx = 0
--lib_mg_continental.current_pcell_neighbors = {}
--lib_mg_continental.current_pcell_vertices = {}

--lib_mg_continental.current_mcell_idx = 0
--lib_mg_continental.current_mcell_neighbors = {}
--lib_mg_continental.current_mcell_vertices = {}

lib_mg_continental.heightmap = {}
lib_mg_continental.biomemap = {} 

local hills_offset = 64*mult
local hills_thresh = math.floor((np_terrain.scale)*0.5)
local shelf_thresh = math.floor((np_terrain.scale)*0.5) 
local cliffs_thresh = math.floor((np_terrain.scale)*0.5)

local function max_height(noiseprm)
	local height = 0					--	30		18
	local scale = noiseprm.scale				--	18		10.8
	for i=1,noiseprm.octaves do				--	10.8		6.48
		height=height + scale				--	6.48		3.88
		scale = scale * noiseprm.persist		--	3.88		2.328
	end							--	-----		------
	return height+noiseprm.offset				--			41.496 + (-4)
end								--			37.496

local function min_height(noiseprm)
	local height = 0
	local scale = noiseprm.scale
	for i=1,noiseprm.octaves do
		height=height - scale
		scale = scale * noiseprm.persist
	end	
	return height+noiseprm.offset
end

local base_min = min_height(np_terrain)
local base_max = max_height(np_terrain)
local base_rng = (base_max-base_min)
local easing_factor = 1/(base_max*base_max*4)

function lib_mg_continental.get_terrain_height(theight,hheight,cheight)
		-- parabolic gradient
	if theight > 0 and theight < shelf_thresh then
		theight = theight * (theight*theight/(shelf_thresh*shelf_thresh)*0.5 + 0.5)
	end	
		-- hills
	if theight > hills_thresh then
		theight = theight + max((theight-hills_thresh) * hheight,0)
		-- cliffs
	elseif theight > 1 and theight < hills_thresh then 
		local clifh = max(min(cheight,1),0) 
		if clifh > 0 then
			clifh = -1*(clifh-1)*(clifh-1) + 1
			theight = theight + (hills_thresh-theight) * clifh * ((theight<2) and theight-1 or 1)
		end
	end
	return theight
end
 
function lib_mg_continental.get_terrain_height_shelf(theight)
		-- parabolic gradient
	if theight > 0 and theight < shelf_thresh then
		theight = theight * (theight*theight/(shelf_thresh*shelf_thresh)*0.5 + 0.5)
	end

	return theight
end
--
function lib_mg_continental.get_terrain_height_hills_adjustable_shelf(theight,hheight,cheight,shlf_thresh)
		-- parabolic gradient
	if theight > 0 and theight < shlf_thresh then
		theight = theight * (theight*theight/(shlf_thresh*shlf_thresh)*0.5 + 0.5)
	end	
		-- hills
	if theight > hills_thresh then
		theight = theight + math.max((theight-hills_thresh) * hheight,0)
		-- cliffs
	elseif theight > 1 and theight < hills_thresh then 
		local clifh = math.max(math.min(cheight,1),0) 
		if clifh > 0 then
			clifh = -1*(clifh-1)*(clifh-1) + 1
			theight = theight + (hills_thresh-theight) * clifh * ((theight<2) and theight-1 or 1)
		end
	end
	return theight
end

function lib_mg_continental.get_terrain_height_cliffs_hills(theight,hheight,cheight)
		-- hills
	if theight > hills_thresh then
		theight = theight + math.max((theight-hills_thresh) * hheight,0)
		-- cliffs
	elseif theight > 1 and theight < hills_thresh then 
		local clifh = math.max(math.min(cheight,1),0) 
		if clifh > 0 then
			clifh = -1*(clifh-1)*(clifh-1) + 1
			theight = theight + (hills_thresh-theight) * clifh * ((theight<2) and theight-1 or 1)
		end
	end
	return theight
end
--
function lib_mg_continental.get_direction_to_pos(a,b)
	local t_compass
	local t_dir = {x = 0, z = 0}

	if a.z < b.z then
		t_dir.z = 1
		t_compass = "N"
	elseif a.z > b.z then
		t_dir.z = -1
		t_compass = "S"
	else
		t_dir.z = 0
		t_compass = ""
	end
	if a.x < b.x then
		t_dir.x = 1
		t_compass = t_compass .. "E"
	elseif a.x > b.x then
		t_dir.x = -1
		t_compass = t_compass .. "W"
	else
		t_dir.x = 0
		t_compass = t_compass .. ""
	end
	return t_dir, t_compass
end

function lib_mg_continental.get_height_dir(a,b)
	
end

function lib_mg_continental.get_distance_average(a,b)						--get_avg_distance(a,b)
    return ((abs(a.x-b.x) + abs(a.z-b.z)) * 0.5)					--returns the average distance between two points
end

function lib_mg_continental.get_distance_chebyshev(a,b)						--get_distance(a,b)
    return (max(abs(a.x-b.x), abs(a.z-b.z)))					--returns the chebyshev distance between two points
end

function lib_mg_continental.get_distance_combo(a,b,d_type)						--get_distance(a,b)

	local this_dist
	
	if d_type == "x" then
		local d_a = lib_mg_continental.get_distance_average({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_c = lib_mg_continental.get_distance_chebyshev({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_e = lib_mg_continental.get_distance_euclid({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_m = lib_mg_continental.get_distance_manhattan({x = a.x, z = a.z}, {x = b.x, z = b.z})
		this_dist = (d_a + d_c + d_e + d_m) * 0.25
	elseif d_type == "r" then
		local d_a = lib_mg_continental.get_distance_average({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_c = lib_mg_continental.get_distance_chebyshev({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_e = lib_mg_continental.get_distance_euclid({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_m = lib_mg_continental.get_distance_manhattan({x = a.x, z = a.z}, {x = b.x, z = b.z})
		this_dist = d_a + d_c + d_e + d_m
	elseif d_type == "ac" then
		local d_a = lib_mg_continental.get_distance_average({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_c = lib_mg_continental.get_distance_chebyshev({x = a.x, z = a.z}, {x = b.x, z = b.z})
		this_dist = (d_a + d_c) * 0.5
	elseif d_type == "ae" then
		local d_a = lib_mg_continental.get_distance_average({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_e = lib_mg_continental.get_distance_euclid({x = a.x, z = a.z}, {x = b.x, z = b.z})
		this_dist = (d_a + d_e) * 0.5
	elseif d_type == "am" then
		local d_a = lib_mg_continental.get_distance_average({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_m = lib_mg_continental.get_distance_manhattan({x = a.x, z = a.z}, {x = b.x, z = b.z})
		this_dist = (d_a + d_m) * 0.5
	elseif d_type == "ce" then
		local d_c = lib_mg_continental.get_distance_chebyshev({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_e = lib_mg_continental.get_distance_euclid({x = a.x, z = a.z}, {x = b.x, z = b.z})
		this_dist = (d_c + d_e) * 0.5
	elseif d_type == "cm" then
		local d_c = lib_mg_continental.get_distance_chebyshev({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_m = lib_mg_continental.get_distance_manhattan({x = a.x, z = a.z}, {x = b.x, z = b.z})
		this_dist = (d_c + d_m) * 0.5
	elseif d_type == "em" then
		local d_e = lib_mg_continental.get_distance_euclid({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_m = lib_mg_continental.get_distance_manhattan({x = a.x, z = a.z}, {x = b.x, z = b.z})
		this_dist = (d_e + d_m) * 0.5
	elseif d_type == "ace" then
		local d_a = lib_mg_continental.get_distance_average({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_c = lib_mg_continental.get_distance_chebyshev({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_e = lib_mg_continental.get_distance_euclid({x = a.x, z = a.z}, {x = b.x, z = b.z})
		this_dist = (d_a + d_c + d_e) * 0.35
	elseif d_type == "acm" then
		local d_a = lib_mg_continental.get_distance_average({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_c = lib_mg_continental.get_distance_chebyshev({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_m = lib_mg_continental.get_distance_manhattan({x = a.x, z = a.z}, {x = b.x, z = b.z})
		this_dist = (d_a + d_c + d_m) * 0.35
	elseif d_type == "aem" then
		local d_a = lib_mg_continental.get_distance_average({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_e = lib_mg_continental.get_distance_euclid({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_m = lib_mg_continental.get_distance_manhattan({x = a.x, z = a.z}, {x = b.x, z = b.z})
		this_dist = (d_a + d_e + d_m) * 0.35
	elseif d_type == "cem" then
		local d_c = lib_mg_continental.get_distance_chebyshev({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_e = lib_mg_continental.get_distance_euclid({x = a.x, z = a.z}, {x = b.x, z = b.z})
		local d_m = lib_mg_continental.get_distance_manhattan({x = a.x, z = a.z}, {x = b.x, z = b.z})
		this_dist = (d_c + d_e + d_m) * 0.35
	else
		this_dist = 0
	end

	return this_dist

end

function lib_mg_continental.get_distance_euclid(a,b)
	local dx = a.x - b.x
	local dz = a.z - b.z
	return (dx*dx+dz*dz)^0.5
end

function lib_mg_continental.get_distance_manhattan(a,b)					--get_manhattan_distance(a,b)
    return (abs(a.x-b.x) + abs(a.z-b.z))					--returns the manhattan distance between two points
end

function lib_mg_continental.get_distance_3d_average(a,b)						--get_avg_distance(a,b)
    return ((abs(a.x-b.x) + abs(a.y-b.y) + abs(a.z-b.z)) / 3)					--returns the average distance between two points
end

function lib_mg_continental.get_distance_3d_chebyshev(a,b)						--get_distance(a,b)
    return (max(abs(a.x-b.x), max(abs(a.y-b.y), abs(a.z-b.z))))					--returns the chebyshev distance between two points
end

function lib_mg_continental.get_distance_3d_combo(a,b,d_type)						--get_distance(a,b)

	local this_dist
	
	if d_type == "x" then
		local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		this_dist = (d_a + d_c + d_e + d_m) * 0.25
	elseif d_type == "r" then
		local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		this_dist = d_a + d_c + d_e + d_m
	elseif d_type == "ac" then
		local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x,y = a.y,  z = a.z}, {x = b.x, y = b.y, z = b.z})
		this_dist = (d_a + d_c) * 0.5
	elseif d_type == "ae" then
		local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		this_dist = (d_a + d_e) * 0.5
	elseif d_type == "am" then
		local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		this_dist = (d_a + d_m) * 0.5
	elseif d_type == "ce" then
		local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		this_dist = (d_c + d_e) * 0.5
	elseif d_type == "cm" then
		local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		this_dist = (d_c + d_m) * 0.5
	elseif d_type == "em" then
		local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		this_dist = (d_e + d_m) * 0.5
	elseif d_type == "ace" then
		local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		this_dist = (d_a + d_c + d_e) * 0.35
	elseif d_type == "acm" then
		local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		this_dist = (d_a + d_c + d_m) * 0.35
	elseif d_type == "aem" then
		local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		this_dist = (d_a + d_e + d_m) * 0.35
	elseif d_type == "cem" then
		local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		this_dist = (d_c + d_e + d_m) * 0.35
	else
		this_dist = 0
	end

	return this_dist

end

function lib_mg_continental.get_distance_3d_euclid(a,b)
	local dx = a.x - b.x
	local dy = a.y - b.y
	local dz = a.z - b.z
	return (dx*dx+dy*dy+dz*dz)^0.5
end

function lib_mg_continental.get_distance_3d_manhattan(a,b)					--get_manhattan_distance(a,b)
    return (abs(a.x-b.x) + abs(a.y-b.y) + abs(a.z-b.z))					--returns the manhattan distance between two points
end

function lib_mg_continental.get_midpoint(a,b)						--get_midpoint(a,b)
	return ((a.x+b.x) * 0.5), ((a.z+b.z) * 0.5)					--returns the midpoint between two points
end

function lib_mg_continental.get_triangulation_2d(a,b,c)					--get_2d_triangulation(a,b,c)
	return ((a.x+b.x+c.x)/3), ((a.z+b.z+c.z)/3)				--returns the triangulated point between three points (average pos)
end

function lib_mg_continental.get_triangulation_3d(a,b,c)					--get_3d_triangulation(a,b,c)
	return ((a.x+b.x+c.x)/3), ((a.y+b.y+c.y)/3), ((a.z+b.z+c.z)/3)		--returns the 3D triangulated point between three points (average pos)
end

function lib_mg_continental.get_slope(a,b)
	local run = a.x-b.x
	local rise = a.z-b.z
	return (rise/run), rise, run
end

function lib_mg_continental.get_slope_inverse(a,b)
	local run = a.x-b.x
	local rise = a.z-b.z
	return (run/rise), run, rise
end

function lib_mg_continental.get_line_inverse(a,b)
	local run = a.x-b.x
	local rise = a.z-b.z
	local inverse = (run - rise) / 2
	local c = {
		x = a.x + inverse,
		y = b.z + inverse
	}
	local d = {
		x = b.x - inverse,
		y = a.z - inverse
	}
	return c, d
end

function lib_mg_continental.lerp(noise_a, noise_b, n_mod)
	return noise_a * (1 - n_mod) + noise_b * n_mod
end

function lib_mg_continental.steps(noise, h)
	local w = math.abs(noise)				--n_base
	local k = math.floor(h / w)
	local f = (h - k * w) / w
	local s = math.min(2 * f, 1.0)
	return (k + s) * w
end

function lib_mg_continental.bias(noise, bias)
	return (noise / ((((1.0 / bias) - 2.0) * (1.0 - noise)) + 1.0))
end

function lib_mg_continental.gain(noise, gain)
	if noise < 0.5 then
		return bias(noise * 2.0, gain) / 2.0
	else
		return bias(noise * 2.0 - 1.0, 1.0 - gain) / 2.0 + 0.5
	end
end

--
-- save list of generated lib_mg_continental
--
function lib_mg_continental.save(pobj, pfilename)
  local file = io.open(lib_mg_continental.path_world.."/"..pfilename.."", "w")
  if file then
    file:write(minetest.serialize(pobj))
    file:close()
  end
end
--
-- load list of generated lib_mg_continental
--
function lib_mg_continental.load(pfilename)
	local file = io.open(lib_mg_continental.path_world.."/"..pfilename.."", "r")
	if file then
		local table = minetest.deserialize(file:read("*all"))
		if type(table) == "table" then
			return table
		end
	end

	return nil
end

--
-- save .csv file format
--
function lib_mg_continental.save_csv(pobj, pfilename)
	local file = io.open(lib_mg_continental.path_world.."/"..pfilename.."", "w")
	if file then
		file:write(pobj)
		file:close()
	end
end

function lib_mg_continental.load_csv(separator, path)
	local file = io.open(lib_mg_continental.path_world.."/"..path, "r")
	if file then
		local t = {}
		for line in file:lines() do
			if line:sub(1,1) ~= "#" and line:find("[^%"..separator.."% ]") then
				table.insert(t, line:split(separator, true))
			end
		end
		if type(t) == "table" then
			return t
		end
	end

	return nil
end

function lib_mg_continental.load_defaults_csv(separator, path)
	local file = io.open(lib_mg_continental.path_mod.."/sets/"..path, "r")
	if file then
		local t = {}
		for line in file:lines() do
			if line:sub(1,1) ~= "#" and line:find("[^%"..separator.."% ]") then
				table.insert(t, line:split(separator, true))
			end
		end
		if type(t) == "table" then
			return t
		end
	end

	return nil
end

-- Create a table of biome ids, so I can use the biomemap.
if not lib_mg_continental.biome_info then

	lib_mg_continental.biome_info = {}

	local b_top = minetest.get_content_id("lib_materials:dirt_with_grass")
	local b_top_depth = 1
	local b_filler = minetest.get_content_id("lib_materials:dirt")
	local b_filler_depth = 4
	local b_stone = minetest.get_content_id("lib_materials:stone")
	local b_water_top = minetest.get_content_id("lib_materials:liquid_water_source")
	local b_water_top_depth = 2
	local b_water = minetest.get_content_id("lib_materials:liquid_water_source")
	local b_river = minetest.get_content_id("lib_materials:liquid_water_river_source")
	local b_riverbed = minetest.get_content_id("lib_materials:stone_gravel")
	local b_riverbed_depth = 2
	local b_cave_liquid = minetest.get_content_id("lib_materials:liquid_lava_source")
	local b_dungeon = minetest.get_content_id("lib_materials:stone_cobble_mossy")
	local b_dungeon_alt = minetest.get_content_id("lib_materials:stone_brick")
	local b_dungeon_stair = minetest.get_content_id("lib_materials:stone_block")
	local b_node_dust = minetest.get_content_id("air")
	local b_miny = -31000
	local b_maxy = 31000
	local b_heat = 50
	local b_humid = 50

	for name, desc in pairs(minetest.registered_biomes) do

		if desc then

			local b_cid = minetest.get_biome_id(name)


			if desc.node_top and desc.node_top ~= "" then
				b_top = minetest.get_content_id(desc.node_top)
			end

			if desc.depth_top and desc.depth_top ~= "" then
				b_top_depth = desc.depth_top or ""
			end

			if desc.node_filler and desc.node_filler ~= "" then
				b_filler = minetest.get_content_id(desc.node_filler)
			end

			if desc.depth_filler and desc.depth_filler ~= "" then
				b_filler_depth = desc.depth_filler
			end

			if desc.node_stone and desc.node_stone ~= "" then
				b_stone = minetest.get_content_id(desc.node_stone)
			end

			if desc.node_water_top and desc.node_water_top ~= "" then
				b_water_top = minetest.get_content_id(desc.node_water_top)
			end

			if desc.depth_water_top and desc.depth_water_top ~= "" then
				b_water_top_depth = desc.depth_water_top
			end

			if desc.node_water and desc.node_water ~= "" then
				b_water = minetest.get_content_id(desc.node_water)
			end

			if desc.node_river_water and desc.node_river_water ~= "" then
				b_river = minetest.get_content_id(desc.node_river_water)
			end

			if desc.node_riverbed and desc.node_riverbed ~= "" then
				b_riverbed = minetest.get_content_id(desc.node_riverbed)
			end

			if desc.depth_riverbed and desc.depth_riverbed ~= "" then
				b_riverbed_depth = desc.depth_riverbed or ""
			end

			if desc.node_cave_liquid and desc.node_cave_liquid ~= "" then
				b_cave_liquid = minetest.get_content_id(desc.node_cave_liquid)
			end

			if desc.node_dungeon and desc.node_dungeon ~= "" then
				b_dungeon = minetest.get_content_id(desc.node_dungeon)
			end

			if desc.node_dungeon_alt and desc.node_dungeon_alt ~= "" then
				b_dungeon_alt = minetest.get_content_id(desc.node_dungeon_alt)
			end

			if desc.node_dungeon_stair and desc.node_dungeon_stair ~= "" then
				b_dungeon_stair = minetest.get_content_id(desc.node_dungeon_stair)
			end

			if desc.node_dust and desc.node_dust ~= "" then
				b_node_dust = minetest.get_content_id(desc.node_dust)
			end

			if desc.y_min and desc.y_min ~= "" then
				b_miny = desc.y_min or ""
			end

			if desc.y_max and desc.y_max ~= "" then
				b_maxy = desc.y_max or ""
			end

			if desc.heat_point and desc.heat_point ~= "" then
				b_heat = desc.heat_point or ""
			end

			if desc.humidity_point and desc.humidity_point ~= "" then
				b_humid = desc.humidity_point
			end
	
			lib_mg_continental.biome_info[desc.name] = desc.name .. "|" .. b_cid .. "|" .. b_top .. "|" .. b_top_depth .. "|" .. b_filler .. "|" .. b_filler_depth .. "|" .. b_stone .. "|" .. b_water_top
					.. "|" .. b_water_top_depth .. "|" .. b_water .. "|" .. b_river .. "|" .. b_riverbed .. "|" .. b_riverbed_depth .. "|" .. b_cave_liquid .. "|" .. b_dungeon
					.. "|" .. b_dungeon_alt .. "|" .. b_dungeon_stair .. "|" .. b_node_dust .. "|" .. b_miny .. "|" .. b_maxy .. "|" .. b_heat .. "|" .. b_humid .. "\n"


		end
--

	end
end


function lib_mg_continental.get_closest_cell(pos, dist_type, tier)

	if not pos then
		return
	end

	local d_type
	if not dist_type then
		d_type = "e"
	else
		d_type = dist_type
	end
	if not tier then
		tier = 3
	end

	local closest_cell_idx = 0
	--local closest_cell_dist = 0
	local closest_cell_adist = 0
	local closest_cell_cdist = 0
	local closest_cell_edist = 0
	local closest_cell_mdist = 0
	local last_closest_idx = 0
	local last_dist
	local this_dist
	--local edge = false
	local edge = ""

	--local c_slope, c_rise, c_run
	--local c_compass
	--local c_dir = {x = 0, z = 0}

	for i, point in ipairs(lib_mg_continental.points) do

		if point.tier == tier then

			local d_c = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			local d_e = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			local d_m = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			local d_a = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = point.x, z = point.z})

			if d_type == "c" then
				--this_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				this_dist = d_c
			elseif d_type == "e" then
				--this_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				this_dist = d_e
			elseif d_type == "m" then
				--this_dist = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				this_dist = d_m
			elseif d_type == "a" then
				--this_dist = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				this_dist = d_a
			else

				if d_type == "x" then
					this_dist = (d_a + d_c + d_e + d_m) * 0.25
				elseif d_type == "r" then
					this_dist = d_a + d_c + d_e + d_m
				elseif d_type == "ac" then
					this_dist = (d_a + d_c) * 0.5
				elseif d_type == "ae" then
					this_dist = (d_a + d_e) * 0.5
				elseif d_type == "am" then
					this_dist = (d_a + d_m) * 0.5
				elseif d_type == "ce" then
					this_dist = (d_c + d_e) * 0.5
				elseif d_type == "cm" then
					this_dist = (d_c + d_m) * 0.5
				elseif d_type == "em" then
					this_dist = (d_e + d_m) * 0.5
				elseif d_type == "ace" then
					this_dist = (d_a + d_c + d_e) * 0.35
				elseif d_type == "acm" then
					this_dist = (d_a + d_c + d_m) * 0.35
				elseif d_type == "aem" then
					this_dist = (d_a + d_e + d_m) * 0.35
				elseif d_type == "cem" then
					this_dist = (d_c + d_e + d_m) * 0.35
				else
					
				end
			end
	
			if last_dist then
				if last_dist > this_dist then
					closest_cell_idx = i
					--closest_cell_dist = this_dist
					closest_cell_cdist = d_a
					closest_cell_cdist = d_c
					closest_cell_edist = d_e
					closest_cell_mdist = d_m
					last_dist = this_dist
					last_closest_idx = i
					--c_slope, c_rise, c_run = lib_mg_continental.get_slope({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
					--c_dir, c_compass = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				elseif last_dist == this_dist then
					closest_cell_idx = last_closest_idx
					--closest_cell_dist = this_dist
					closest_cell_cdist = d_a
					closest_cell_cdist = d_c
					closest_cell_edist = d_e
					closest_cell_mdist = d_m
					--c_slope, c_rise, c_run = lib_mg_continental.get_slope({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
					--c_dir, c_compass = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
					--edge = true
					edge = tostring("" .. i .. "-" .. last_closest_idx .. "")
				end
			else
				closest_cell_idx = i
				--closest_cell_dist = this_dist
				closest_cell_cdist = d_a
				closest_cell_cdist = d_c
				closest_cell_edist = d_e
				closest_cell_mdist = d_m
				--c_slope, c_rise, c_run = lib_mg_continental.get_slope({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				--c_dir, c_compass = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				last_dist = this_dist
				last_closest_idx = i
			end
		end
	end

	local c_slope, c_rise, c_run = lib_mg_continental.get_slope({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[closest_cell_idx].x, z = lib_mg_continental.points[closest_cell_idx].z})
	local c_dir, c_compass = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[closest_cell_idx].x, z = lib_mg_continental.points[closest_cell_idx].z})

	return closest_cell_idx, closest_cell_adist, closest_cell_cdist, closest_cell_edist, closest_cell_mdist, c_slope, c_rise, c_run, c_dir.x, c_dir.z, c_compass, edge

	--return closest_cell_idx, closest_cell_adist, closest_cell_cdist, closest_cell_edist, closest_cell_mdist, edge
		--return closest_cell_idx, closest_cell_dist, edge
		--return closest_cell_idx, closest_cell_cdist, closest_cell_edist, closest_cell_mdist, edge
end

function lib_mg_continental.get_nearest_cell(pos, dist_type, tier)

	if not pos then
		return
	end

	local d_type
	if not dist_type then
		d_type = "e"
	else
		d_type = dist_type
	end
	if not tier then
		tier = 3
	end

	local closest_cell_idx = 0
	local closest_cell_dist = 0
	local last_closest_idx = 0
	local last_dist
	local this_dist
	local edge = ""

	for i, point in ipairs(lib_mg_continental.points) do

		if point.tier == tier then

			if d_type == "c" then
				this_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "e" then
				this_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "m" then
				this_dist = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "a" then
				this_dist = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			else

			end
	
			if last_dist then
				if last_dist > this_dist then
					closest_cell_idx = i
					closest_cell_dist = this_dist
					last_dist = this_dist
					last_closest_idx = i
				elseif last_dist == this_dist then
					closest_cell_idx = last_closest_idx
					closest_cell_dist = this_dist
					edge = tostring("" .. i .. "-" .. last_closest_idx .. "")
				end
			else
				closest_cell_idx = i
				closest_cell_dist = this_dist
				last_dist = this_dist
				last_closest_idx = i
			end
		end
	end

	return closest_cell_idx, closest_cell_dist, edge
end

function lib_mg_continental.get_nearest_cell_alt(pos, dist_type, tier)

	if not pos then
		return
	end

	local d_type
	if not dist_type then
		d_type = "e"
	else
		d_type = dist_type
	end
	if not tier then
		tier = 3
	end

	local closest_cell_idx = 0
	local closest_cell_dist = 0
	local last_closest_idx = 0
	local last_dist
	local this_dist
	local edge = ""

	for i, point in ipairs(lib_mg_continental.points) do

		if point.tier == tier then

			if d_type == "c" then
				this_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "e" then
				this_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "m" then
				this_dist = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "a" then
				this_dist = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			else
				this_dist = lib_mg_continental.get_distance_combo({x = pos.x, z = pos.z}, {x = point.x, z = point.z}, d_type)
--[[
				local d_c = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				local d_e = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				local d_m = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				local d_a = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = point.x, z = point.z})

				if d_type == "x" then
					this_dist = (d_a + d_c + d_e + d_m) * 0.25
				elseif d_type == "r" then
					this_dist = d_a + d_c + d_e + d_m
				elseif d_type == "ac" then
					this_dist = (d_a + d_c) * 0.5
				elseif d_type == "ae" then
					this_dist = (d_a + d_e) * 0.5
				elseif d_type == "am" then
					this_dist = (d_a + d_m) * 0.5
				elseif d_type == "ce" then
					this_dist = (d_c + d_e) * 0.5
				elseif d_type == "cm" then
					this_dist = (d_c + d_m) * 0.5
				elseif d_type == "em" then
					this_dist = (d_e + d_m) * 0.5
				elseif d_type == "ace" then
					this_dist = (d_a + d_c + d_e) * 0.35
				elseif d_type == "acm" then
					this_dist = (d_a + d_c + d_m) * 0.35
				elseif d_type == "aem" then
					this_dist = (d_a + d_e + d_m) * 0.35
				elseif d_type == "cem" then
					this_dist = (d_c + d_e + d_m) * 0.35
				else
					
				end
--]]
			end
	
			if last_dist then
				if last_dist > this_dist then
					closest_cell_idx = i
					closest_cell_dist = this_dist
					last_dist = this_dist
					last_closest_idx = i
				elseif last_dist == this_dist then
					closest_cell_idx = last_closest_idx
					closest_cell_dist = this_dist
					edge = tostring("" .. i .. "-" .. last_closest_idx .. "")
				end
			else
				closest_cell_idx = i
				closest_cell_dist = this_dist
				last_dist = this_dist
				last_closest_idx = i
			end
		end
	end

	return closest_cell_idx, closest_cell_dist, edge
end

function lib_mg_continental.get_nearest_cell_3d_alt(pos, dist_type, tier)

	if not pos then
		return
	end

	local d_type
	if not dist_type then
		d_type = "e"
	else
		d_type = dist_type
	end
	if not tier then
		tier = 3
	end

	local closest_cell_idx = 0
	local closest_cell_dist = 0
	local last_closest_idx = 0
	local last_dist
	local this_dist
	local edge = ""

	for i, point in ipairs(lib_mg_continental.points) do

		if point.tier == tier then

			if d_type == "c" then
				this_dist = lib_mg_continental.get_distance_3d_chebyshev({x = pos.x, y = pos.y, z = pos.z}, {x = point.x, y = point.y, z = point.z})
			elseif d_type == "e" then
				this_dist = lib_mg_continental.get_distance_3d_euclid({x = pos.x, y = pos.y, z = pos.z}, {x = point.x, y = point.y, z = point.z})
			elseif d_type == "m" then
				this_dist = lib_mg_continental.get_distance_3d_manhattan({x = pos.x, y = pos.y, z = pos.z}, {x = point.x, y = point.y, z = point.z})
			elseif d_type == "a" then
				this_dist = lib_mg_continental.get_distance_3d_average({x = pos.x, y = pos.y, z = pos.z}, {x = point.x, y = point.y, z = point.z})
			else
				this_dist = lib_mg_continental.get_distance_3d_combo({x = pos.x, y = pos.y, z = pos.z}, {x = point.x, y = point.y, z = point.z}, d_type)
			end
	
			if last_dist then
				if last_dist > this_dist then
					closest_cell_idx = i
					closest_cell_dist = this_dist
					last_dist = this_dist
					last_closest_idx = i
				elseif last_dist == this_dist then
					closest_cell_idx = last_closest_idx
					closest_cell_dist = this_dist
					edge = tostring("" .. i .. "-" .. last_closest_idx .. "")
				end
			else
				closest_cell_idx = i
				closest_cell_dist = this_dist
				last_dist = this_dist
				last_closest_idx = i
			end
		end
	end

	return closest_cell_idx, closest_cell_dist, edge
end

function lib_mg_continental.get_nearest_cell1(pos, dist_type, tier)

	if not pos then
		return
	end

	local d_type
	if not dist_type then
		d_type = "e"
	else
		d_type = dist_type
	end
	if not tier then
		tier = 3
	end

	local closest_cell_idx = 0
	local closest_cell_dist = 0
	local last_closest_idx = 0
	local last_dist
	local this_dist
	local edge = ""

	--local c_slope, c_rise, c_run
	--local c_compass
	--local c_dir = {x = 0, z = 0}

	for i, point in ipairs(lib_mg_continental.points) do

		if point.tier == tier then

			if d_type == "c" then
				this_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "e" then
				this_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "m" then
				this_dist = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "a" then
				this_dist = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			else

			end
	
			if last_dist then
				if last_dist > this_dist then
					closest_cell_idx = i
					closest_cell_dist = this_dist
					last_dist = this_dist
					last_closest_idx = i
					--c_slope, c_rise, c_run = lib_mg_continental.get_slope({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
					--c_dir, c_compass = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				elseif last_dist == this_dist then
					closest_cell_idx = last_closest_idx
					closest_cell_dist = this_dist
					--c_slope, c_rise, c_run = lib_mg_continental.get_slope({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
					--c_dir, c_compass = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
					edge = tostring("" .. i .. "-" .. last_closest_idx .. "")
				end
			else
				closest_cell_idx = i
				closest_cell_dist = this_dist
				--c_slope, c_rise, c_run = lib_mg_continental.get_slope({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				--c_dir, c_compass = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				last_dist = this_dist
				last_closest_idx = i
			end
		end
	end

	--local c_slope, c_rise, c_run = lib_mg_continental.get_slope({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[closest_cell_idx].x, z = lib_mg_continental.points[closest_cell_idx].z})
	local c_dir, c_compass = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[closest_cell_idx].x, z = lib_mg_continental.points[closest_cell_idx].z})

	return closest_cell_idx, closest_cell_dist, c_dir.x, c_dir.z, c_compass, edge
	--return closest_cell_idx, closest_cell_dist, c_slope, c_rise, c_run, c_dir.x, c_dir.z, c_compass, edge
end

function lib_mg_continental.get_nearest_cell2(pos, dist_type, tier)

	if not pos then
		return
	end

	local d_type
	if not dist_type then
		d_type = "e"
	else
		d_type = dist_type
	end
	if not tier then
		tier = 3
	end

	local closest_cell_idx = 0
	local closest_cell_dist = 0
	local last_closest_idx = 0
	local last_dist
	local this_dist
	local edge = ""

	--local c_slope, c_rise, c_run
	--local c_compass
	--local c_dir = {x = 0, z = 0}

	for i, point in ipairs(lib_mg_continental.points) do

		if point.tier == tier then

			if d_type == "c" then
				this_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "e" then
				this_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "m" then
				this_dist = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "a" then
				this_dist = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			else

				local d_c = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				local d_e = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				local d_m = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				local d_a = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = point.x, z = point.z})

				if d_type == "x" then
					this_dist = (d_a + d_c + d_e + d_m) * 0.25
				elseif d_type == "r" then
					this_dist = d_a + d_c + d_e + d_m
				elseif d_type == "ac" then
					this_dist = (d_a + d_c) * 0.5
				elseif d_type == "ae" then
					this_dist = (d_a + d_e) * 0.5
				elseif d_type == "am" then
					this_dist = (d_a + d_m) * 0.5
				elseif d_type == "ce" then
					this_dist = (d_c + d_e) * 0.5
				elseif d_type == "cm" then
					this_dist = (d_c + d_m) * 0.5
				elseif d_type == "em" then
					this_dist = (d_e + d_m) * 0.5
				elseif d_type == "ace" then
					this_dist = (d_a + d_c + d_e) * 0.35
				elseif d_type == "acm" then
					this_dist = (d_a + d_c + d_m) * 0.35
				elseif d_type == "aem" then
					this_dist = (d_a + d_e + d_m) * 0.35
				elseif d_type == "cem" then
					this_dist = (d_c + d_e + d_m) * 0.35
				else
					
				end
			end
	
			if last_dist then
				if last_dist > this_dist then
					closest_cell_idx = i
					closest_cell_dist = this_dist
					last_dist = this_dist
					last_closest_idx = i
					--c_slope, c_rise, c_run = lib_mg_continental.get_slope({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
					--c_dir, c_compass = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				elseif last_dist == this_dist then
					closest_cell_idx = last_closest_idx
					closest_cell_dist = this_dist
					--c_slope, c_rise, c_run = lib_mg_continental.get_slope({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
					--c_dir, c_compass = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
					edge = tostring("" .. i .. "-" .. last_closest_idx .. "")
				end
			else
				closest_cell_idx = i
				closest_cell_dist = this_dist
				--c_slope, c_rise, c_run = lib_mg_continental.get_slope({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				--c_dir, c_compass = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				last_dist = this_dist
				last_closest_idx = i
			end
		end
	end

	local c_slope, c_rise, c_run = lib_mg_continental.get_slope({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[closest_cell_idx].x, z = lib_mg_continental.points[closest_cell_idx].z})
	local c_dir, c_compass = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[closest_cell_idx].x, z = lib_mg_continental.points[closest_cell_idx].z})

	return closest_cell_idx, closest_cell_dist, c_slope, c_rise, c_run, c_dir.x, c_dir.z, c_compass, edge
end

function lib_mg_continental.get_nearest_cell_data(pos, dist_type, tier)

	if not pos then
		return
	end

	local d_type
	if not dist_type then
		d_type = "e"
	else
		d_type = dist_type
	end
	if not tier then
		tier = 3
	end

	local closest_cell_idx = 0
	local closest_cell_dist = 0
	local last_closest_idx = 0
	local last_dist
	local this_dist
	local edge = ""

	local p_idx
	local m_idx
	local p_dist
	local m_dist

	for i, point in ipairs(lib_mg_continental.points) do

		if point.tier == tier then

			if d_type == "c" then
				this_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "e" then
				this_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "m" then
				this_dist = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "a" then
				this_dist = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			else

			end
	
			if last_dist then
				if last_dist > this_dist then
					closest_cell_idx = i
					closest_cell_dist = this_dist
					last_dist = this_dist
					last_closest_idx = i
				elseif last_dist == this_dist then
					closest_cell_idx = last_closest_idx
					closest_cell_dist = this_dist
					edge = tostring("" .. i .. "-" .. last_closest_idx .. "")
				end
			else
				closest_cell_idx = i
				closest_cell_dist = this_dist
				last_dist = this_dist
				last_closest_idx = i
			end
		end
	end

	if d_type == "c" then
		p_idx = lib_mg_continental.points[closest_cell_idx].p_ci
		m_idx = lib_mg_continental.points[closest_cell_idx].m_ci
	elseif d_type == "e" then
		p_idx = lib_mg_continental.points[closest_cell_idx].p_ei
		m_idx = lib_mg_continental.points[closest_cell_idx].m_ei
	elseif d_type == "m" then
		p_idx = lib_mg_continental.points[closest_cell_idx].p_mi
		m_idx = lib_mg_continental.points[closest_cell_idx].m_mi
	elseif d_type == "a" then
		p_idx = lib_mg_continental.points[closest_cell_idx].p_ai
		m_idx = lib_mg_continental.points[closest_cell_idx].m_ai
	else
		p_idx = lib_mg_continental.points[closest_cell_idx].p_ei
		m_idx = lib_mg_continental.points[closest_cell_idx].m_ei
	end

	local parent = lib_mg_continental.points[p_idx]
	local master = lib_mg_continental.points[m_idx]

	if d_type == "c" then
		p_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = parent.x, z = parent.z})
		m_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = master.x, z = master.z})
	elseif d_type == "e" then
		p_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = parent.x, z = parent.z})
		m_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = master.x, z = master.z})
	elseif d_type == "m" then
		p_dist = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = parent.x, z = parent.z})
		m_dist = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = master.x, z = master.z})
	elseif d_type == "a" then
		p_dist = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = parent.x, z = parent.z})
		m_dist = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = master.x, z = master.z})
	else

	end

	return closest_cell_idx, closest_cell_dist, p_idx, p_dist, m_idx, m_dist, edge

end

function lib_mg_continental.get_nearest_cell_data2(pos, dist_type, tier)

	if not pos then
		return
	end

	local d_type
	if not dist_type then
		d_type = "e"
	else
		d_type = dist_type
	end
	if not tier then
		tier = 3
	end

	local closest_cell_idx = 0
	local closest_cell_dist = 0
	local last_closest_idx = 0
	local last_dist
	local this_dist
	local edge = ""

	local p_idx
	local m_idx
	local p_dist
	local m_dist

	for i, point in ipairs(lib_mg_continental.points) do

		if point.tier == tier then

			if d_type == "c" then
				this_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "e" then
				this_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "m" then
				this_dist = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			elseif d_type == "a" then
				this_dist = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			else

				local d_c = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				local d_e = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				local d_m = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				local d_a = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = point.x, z = point.z})

				if d_type == "x" then
					this_dist = (d_a + d_c + d_e + d_m) * 0.25
				elseif d_type == "r" then
					this_dist = d_a + d_c + d_e + d_m
				elseif d_type == "ac" then
					this_dist = (d_a + d_c) * 0.5
				elseif d_type == "ae" then
					this_dist = (d_a + d_e) * 0.5
				elseif d_type == "am" then
					this_dist = (d_a + d_m) * 0.5
				elseif d_type == "ce" then
					this_dist = (d_c + d_e) * 0.5
				elseif d_type == "cm" then
					this_dist = (d_c + d_m) * 0.5
				elseif d_type == "em" then
					this_dist = (d_e + d_m) * 0.5
				elseif d_type == "ace" then
					this_dist = (d_a + d_c + d_e) * 0.35
				elseif d_type == "acm" then
					this_dist = (d_a + d_c + d_m) * 0.35
				elseif d_type == "aem" then
					this_dist = (d_a + d_e + d_m) * 0.35
				elseif d_type == "cem" then
					this_dist = (d_c + d_e + d_m) * 0.35
				else
					
				end
			end
	
			if last_dist then
				if last_dist > this_dist then
					closest_cell_idx = i
					closest_cell_dist = this_dist
					last_dist = this_dist
					last_closest_idx = i
				elseif last_dist == this_dist then
					closest_cell_idx = last_closest_idx
					closest_cell_dist = this_dist
					edge = tostring("" .. i .. "-" .. last_closest_idx .. "")
				end
			else
				closest_cell_idx = i
				closest_cell_dist = this_dist
				last_dist = this_dist
				last_closest_idx = i
			end
		end
	end

	local c_slope, c_rise, c_run = lib_mg_continental.get_slope({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[closest_cell_idx].x, z = lib_mg_continental.points[closest_cell_idx].z})
	local c_dir, c_compass = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[closest_cell_idx].x, z = lib_mg_continental.points[closest_cell_idx].z})

	if d_type == "c" then
		p_idx = lib_mg_continental.points[closest_cell_idx].p_ci
		m_idx = lib_mg_continental.points[closest_cell_idx].m_ci
	elseif d_type == "e" then
		p_idx = lib_mg_continental.points[closest_cell_idx].p_ei
		m_idx = lib_mg_continental.points[closest_cell_idx].m_ei
	elseif d_type == "m" then
		p_idx = lib_mg_continental.points[closest_cell_idx].p_mi
		m_idx = lib_mg_continental.points[closest_cell_idx].m_mi
	elseif d_type == "a" then
		p_idx = lib_mg_continental.points[closest_cell_idx].p_ai
		m_idx = lib_mg_continental.points[closest_cell_idx].m_ai
	else
		p_idx = lib_mg_continental.points[closest_cell_idx].p_ei
		m_idx = lib_mg_continental.points[closest_cell_idx].m_ei
	end

	local parent = lib_mg_continental.points[p_idx]
	local master = lib_mg_continental.points[m_idx]

	if d_type == "c" then
		p_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = parent.x, z = parent.z})
		m_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = master.x, z = master.z})
	elseif d_type == "e" then
		p_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = parent.x, z = parent.z})
		m_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = master.x, z = master.z})
	elseif d_type == "m" then
		p_dist = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = parent.x, z = parent.z})
		m_dist = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = master.x, z = master.z})
	elseif d_type == "a" then
		p_dist = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = parent.x, z = parent.z})
		m_dist = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = master.x, z = master.z})
	else
		local d_pc = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].p_ci].x, z = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].p_ci].z})
		local d_pe = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].p_ei].x, z = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].p_ei].z})
		local d_pm = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].p_mi].x, z = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].p_mi].z})
		local d_pa = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].p_ai].x, z = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].p_ai].z})

		local d_mc = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].m_ci].x, z = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].m_ci].z})
		local d_me = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].m_ei].x, z = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].m_ei].z})
		local d_mm = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].m_mi].x, z = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].m_mi].z})
		local d_ma = lib_mg_continental.get_distance_average({x = pos.x, z = pos.z}, {x = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].m_ai].x, z = lib_mg_continental.points[lib_mg_continental.points[closest_cell_idx].m_ai].z})

		if d_type == "x" then
			p_dist = (d_pa + d_pc + d_pe + d_pm) * 0.25
			m_dist = (d_ma + d_mc + d_me + d_mm) * 0.25
		elseif d_type == "r" then
			p_dist = d_pa + d_pc + d_pe + d_pm
			m_dist = d_ma + d_mc + d_me + d_mm
		elseif d_type == "ac" then
			p_dist = (d_pa + d_pc) * 0.5
			m_dist = (d_ma + d_mc) * 0.5
		elseif d_type == "ae" then
			p_dist = (d_pa + d_pe) * 0.5
			m_dist = (d_ma + d_me) * 0.5
		elseif d_type == "am" then
			p_dist = (d_pa + d_pm) * 0.5
			m_dist = (d_ma + d_mm) * 0.5
		elseif d_type == "ce" then
			p_dist = (d_pc + d_pe) * 0.5
			m_dist = (d_mc + d_me) * 0.5
		elseif d_type == "cm" then
			p_dist = (d_pc + d_pm) * 0.5
			m_dist = (d_mc + d_mm) * 0.5
		elseif d_type == "em" then
			p_dist = (d_pe + d_pm) * 0.5
			m_dist = (d_me + d_mm) * 0.5
		elseif d_type == "ace" then
			p_dist = (d_pa + d_pc + d_pe) * 0.35
			m_dist = (d_ma + d_mc + d_me) * 0.35
		elseif d_type == "acm" then
			p_dist = (d_pa + d_pc + d_pm) * 0.35
			m_dist = (d_ma + d_mc + d_mm) * 0.35
		elseif d_type == "aem" then
			p_dist = (d_pa + d_pe + d_pm) * 0.35
			m_dist = (d_ma + d_me + d_mm) * 0.35
		elseif d_type == "cem" then
			p_dist = (d_pc + d_pe + d_pm) * 0.35
			m_dist = (d_mc + d_me + d_mm) * 0.35
		else
			
		end
	end
	local p_slope, p_rise, p_run = lib_mg_continental.get_slope({x = pos.x, z = pos.z}, {x = parent.x, z = parent.z})
	local p_dir, p_comp = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = parent.x, z = parent.z})
	local m_slope, m_rise, m_run = lib_mg_continental.get_slope({x = pos.x, z = pos.z}, {x = master.x, z = master.z})
	local m_dir, m_comp = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = master.x, z = master.z})


	return closest_cell_idx, closest_cell_dist, c_slope, c_rise, c_run, c_dir.x, c_dir.z, c_compass, p_idx, p_dist, p_slope, p_rise, p_run, p_dir.x, p_dir.z, p_comp, m_idx, m_dist, m_slope, m_rise, m_run, m_dir.x, m_dir.z, m_comp, edge

end

function lib_mg_continental.get_closest_midpoint(pos, cell_idx)

	local c_midpoint
	local m_dist
	local this_dist
	local this_cdist
	local this_mdist
	local last_dist

	for i_c, i_cell in pairs(lib_mg_continental.cells) do

		if i_cell.c_i ==  cell_idx then

			this_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = i_cell.m_x, z = i_cell.m_z})
	
			if last_dist then
				if last_dist >= this_dist then
					last_dist = this_dist
					c_midpoint = i_c
					m_dist =  this_dist
					this_cdist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = i_cell.m_x, z = i_cell.m_z})
					this_mdist = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = i_cell.m_x, z = i_cell.m_z})
				end
			else
					last_dist = this_dist
			end
		end
	end

	--return lib_mg_continental.cells[c_midpoint]
	return c_midpoint, m_dist, this_cdist, this_mdist

end
--[[
function lib_mg_continental.get_closest_neighbor(cell_idx)

	local t_neighbors = lib_mg_continental.get_cell_neighbors(cell_idx)
	local c_neighbor
	local this_dist
	local last_dist

	for i_n, i_neighbor in pairs(t_neighbors) do

		this_dist = i_neighbor.n_dist

		if last_dist then
			if last_dist >= this_dist then
				last_dist = this_dist
				c_neighbor = i_n
			end
		else
				last_dist = this_dist
		end
	end

	--return lib_mg_continental.cells[c_neighbor]
	return c_neighbor

end

function lib_mg_continental.get_closest_vertex(cell_idx)

	local t_vertices = lib_mg_continental.get_cell_vertices(cell_idx)
	local c_vertex
	local this_dist
	local last_dist

	for i_v, i_vertex in pairs(t_vertices) do

		this_dist = i_vertex.n_dist

		if last_dist then
			if last_dist >= this_dist then
				last_dist = this_dist
				local v_idx = i_vertex.c_i .. "-" .. i_vertex.n1_i .. "-" .. i_vertex.n2_i
				c_vertex = v_idx
			end
		else
				last_dist = this_dist
		end
	end

	--return lib_mg_continental.vertices[c_vertex]
	minetest.log("CELL_IDX: " .. cell_idx .. ";   CLOSEST V:  " .. c_vertex .. "")
	print("CELL_IDX: " .. cell_idx .. ";   CLOSEST V:  " .. c_vertex .. "")
	return c_vertex

end

function lib_mg_continental.get_farthest_cell(pos, dist_type, tier)

	if not pos then
		return
	end

	local d_type
	if not dist_type then
		d_type = "e"
	else
		d_type = dist_type
	end
	if not tier then
		tier = 3
	end

	local farthest_cell_idx = 0
	local farthest_cell_cdist = 0
	local farthest_cell_edist = 0
	local farthest_cell_mdist = 0
	local last_farthest_idx = 0
	local last_dist
	local this_dist
	local edge = false

	for i, point in ipairs(lib_mg_continental.points) do

		if point.tier == tier then

			local d_c = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			local d_e = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			local d_m = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
	
			if dist_type == "c" then
				this_dist = d_c
			elseif dist_type == "e" then
				this_dist = d_e
			elseif dist_type == "m" then
				this_dist = d_m
			else
	
			end
	
			if last_dist then
				if last_dist < this_dist then
					farthest_cell_idx = i
					farthest_cell_cdist = d_c
					farthest_cell_edist = d_e
					farthest_cell_mdist = d_m
					last_dist = this_dist
					last_farthest_idx = i
				elseif last_dist == this_dist then
					farthest_cell_idx = last_closest_idx
					farthest_cell_cdist = d_c
					farthest_cell_edist = d_e
					farthest_cell_mdist = d_m
					edge = true
				end
			else
				farthest_cell_idx = i
				farthest_cell_cdist = d_c
				farthest_cell_edist = d_e
				farthest_cell_mdist = d_m
				last_dist = this_dist
				last_farthest_idx = i
			end
		end
	end
	return farthest_cell_idx, farthest_cell_cdist, farthest_cell_edist, farthest_cell_mdist, edge
end


function lib_mg_continental.get_cell_neighbors(cell_idx, p_tier)

	local t_neighbors = {}
	local t_tier

	for i_c, cell in pairs(lib_mg_continental.cells) do

		if cell.c_i ==  cell_idx then

			if not p_tier then
				t_tier = lib_mg_continental.points[cell.c_i].tier
			else
				t_tier = p_tier
			end
				

			if lib_mg_continental.points[cell.n_i].tier == t_tier then

				t_neighbors[cell.n_i] = {}
				t_neighbors[cell.n_i].c_i = cell.c_i
				t_neighbors[cell.n_i].c_x = cell.c_x
				t_neighbors[cell.n_i].c_z = cell.c_z
				t_neighbors[cell.n_i].n_i = cell.n_i
				t_neighbors[cell.n_i].n_x = cell.n_x
				t_neighbors[cell.n_i].n_z = cell.n_z
				t_neighbors[cell.n_i].cn_d = cell.cn_d
				t_neighbors[cell.n_i].n_d = cell.n_d
				t_neighbors[cell.n_i].cn_c = cell.cn_c
				t_neighbors[cell.n_i].cn_s = cell.cn_s
				t_neighbors[cell.n_i].cn_sx = cell.cn_sx
				t_neighbors[cell.n_i].cn_sz = cell.cn_sz
				t_neighbors[cell.n_i].cm_d = cell.cm_d
				t_neighbors[cell.n_i].nm_d = cell.nm_d
				t_neighbors[cell.n_i].m_x = cell.m_x
				t_neighbors[cell.n_i].m_z = cell.m_z
				t_neighbors[cell.n_i].e_s = cell.e_s
				t_neighbors[cell.n_i].e_sx = cell.e_sx
				t_neighbors[cell.n_i].e_sz = cell.e_sz
	
			end
		end
	end

	return t_neighbors

end

function lib_mg_continental.get_cell_vertices(cell_idx)

	local t_vertices = {}

	for i_v, i_vertex in pairs(lib_mg_continental.vertices) do

		if i_vertex.c_i == cell_idx then

			--local v_idx = i_vertex.c_i .. "-" .. i_vertex.n1_i .. "-" .. i_vertex.n2_i

			t_vertices[i_v] = {}
			t_vertices[i_v].c_i = i_vertex.c_i
			t_vertices[i_v].c_x = i_vertex.c_x
			t_vertices[i_v].c_z = i_vertex.c_z

			t_vertices[i_v].n1_i = i_vertex.n1_i
			t_vertices[i_v].n1_x = i_vertex.n1_x
			t_vertices[i_v].n1_z = i_vertex.n1_z

			t_vertices[i_v].n2_i = i_vertex.n2_i
			t_vertices[i_v].n2_x = i_vertex.n2_x
			t_vertices[i_v].n2_z = i_vertex.n2_z

			t_vertices[i_v].v_x = i_vertex.v_x
			t_vertices[i_v].v_z = i_vertex.v_z
			t_vertices[i_v].v_d = i_vertex.v_d
			t_vertices[i_v].v_c = i_vertex.v_c

			t_vertices[i_v].cv_s = i_vertex.cv_s
			t_vertices[i_v].cv_sx = i_vertex.cv_sx
			t_vertices[i_v].cv_sz = i_vertex.cv_sz

		end

	end

	--minetest.log(c_vertex)
	--print(c_vertex)

	return t_vertices

end

function lib_mg_continental.calculate_cell_vertices(cell_idx)

	local t_vertex = {}

	for i_c, i_cell in pairs(lib_mg_continental.cells) do
		if i_cell.c_i ==  cell_idx then
			if lib_mg_continental.points[i_cell.n_i].tier == lib_mg_continental.points[i_cell.c_i].tier then
				for i_n, i_neighbor in pairs(lib_mg_continental.cells) do
					if i_neighbor.c_i ==  i_cell.n_i then
						if lib_mg_continental.points[i_neighbor.n_i].tier == lib_mg_continental.points[i_neighbor.c_i].tier then
							for i_c, i_triple in pairs(lib_mg_continental.cells) do
								if (i_triple.c_i ==  i_neighbor.n_i) and (i_triple.c_i ~=  i_cell.c_i) then
									if lib_mg_continental.points[i_neighbor.n_i].tier == lib_mg_continental.points[i_neighbor.c_i].tier then
						
										local v_idx = i_cell.c_i .. "-" .. i_neighbor.c_i .. "-" .. i_triple.c_i
										--local c_pos = {x = i_cell.c_x, z = i_cell.c_z}
										--local n_pos = {x = i_neighbor.c_x, z = i_neighbor.c_z}
										--local t_pos = {x = i_triple.c_x, z = i_triple.c_z}
						
										--local tri_x, tri_z = lib_mg_continental.get_triangulation_2d(c_pos, n_pos, t_pos)
										local tri_x, tri_z = lib_mg_continental.get_triangulation_2d({x = i_cell.c_x, z = i_cell.c_z}, {x = i_neighbor.c_x, z = i_neighbor.c_z}, {x = i_triple.c_x, z = i_triple.c_z})
										local cv_slope, cv_rise, cv_run = lib_mg_continental.get_slope({x = i_cell.c_x, z = i_cell.c_z}, {x = tri_x, z = tri_z})
										--local edge_slope, edge_run, edge_rise = lib_mg_continental.get_slope_inverse({x = i_cell.c_x, z = i_cell.c_z}, {x = tri_x, z = tri_z})

										local t_compass
										local t_dir = {x = 0, z = 0}
						
										t_vertex[v_idx] = {}
										t_vertex[v_idx].c_i = i_cell.c_i
										t_vertex[v_idx].c_x = i_cell.c_x
										t_vertex[v_idx].c_z = i_cell.c_z
											--t_vertex[v_idx].c_pos = c_pos

										t_vertex[v_idx].n1_i = i_neighbor.c_i
										t_vertex[v_idx].n1_x = i_neighbor.c_x
										t_vertex[v_idx].n1_z = i_neighbor.c_z
											--t_vertex[v_idx].n1_pos = n_pos

										t_vertex[v_idx].n2_i = i_triple.c_i
										t_vertex[v_idx].n2_x = i_triple.c_x
										t_vertex[v_idx].n2_z = i_triple.c_z
											--t_vertex[v_idx].n2_pos = t_pos

										t_vertex[v_idx].v_x = tri_x
										t_vertex[v_idx].v_z = tri_z
											--t_vertex[v_idx].v_pos = {x = tri_x, z = tri_z}
						
										if tri_z > i_cell.c_z then
											t_dir.z = 1
											t_compass = "N"
										elseif tri_z < i_cell.c_z then
											t_dir.z = -1
											t_compass = "S"
										else
											t_dir.z = 0
											t_compass = ""
										end
										if tri_x > i_cell.c_x then
											t_dir.x = 1
											t_compass = t_compass .. "E"
										elseif tri_x < i_cell.c_x then
											t_dir.x = -1
											t_compass = t_compass .. "W"
										else
											t_dir.x = 0
											t_compass = t_compass .. ""
										end
										t_vertex[v_idx].v_d = t_dir
										t_vertex[v_idx].v_c = t_compass
	
											--t_vertex[v_idx].v_pos = {x = tri_x, z = tri_z}
										t_vertex[v_idx].cv_s = cv_slope
										t_vertex[v_idx].cv_sx = cv_run
										t_vertex[v_idx].cv_sz = cv_rise
									end
								end
							end
						end
					end
				end
			end
		end
	end

	--minetest.log("VERTICES: " .. dump(t_vertex))
	--print("VERTICES: " .. dump(t_vertex))

	return t_vertex

end

function lib_mg_continental.get_vertices_data()

	--local t_vertex = {}

	local temp_list = "#Idx|C_I|C_Pos|N1_I|N1_Pos|N2_I|N2_Pos|V_Pos\n"
	--local temp_vertices = "#Idx|C_I|C_Pos|N1_I|N1_Pos|N2_I|N2_Pos|V_Pos\n"
	local temp_vertices = ""
	local temp_vertex = ""
	
	local t0 = os.clock()
	minetest.log("[lib_mg_continental] Voronoi Vertices Data generation start")

	for i_c, i_cell in pairs(lib_mg_continental.cells) do

		if lib_mg_continental.points[i_cell.n_i].tier == lib_mg_continental.points[i_cell.c_i].tier then

			for i_n, i_neighbor in pairs(lib_mg_continental.cells) do

				if i_neighbor.c_i ==  i_cell.n_i then

					if lib_mg_continental.points[i_neighbor.n_i].tier == lib_mg_continental.points[i_neighbor.c_i].tier then

						for i_c, i_triple in pairs(lib_mg_continental.cells) do

							if (i_triple.c_i ==  i_neighbor.n_i) and (i_triple.c_i ~=  i_cell.c_i) then

								if lib_mg_continental.points[i_neighbor.n_i].tier == lib_mg_continental.points[i_neighbor.c_i].tier then
					
									local v_idx = i_cell.c_i .. "-" .. i_neighbor.c_i .. "-" .. i_triple.c_i
									--local c_pos = {x = i_cell.c_x, z = i_cell.c_z}
									--local n_pos = {x = i_neighbor.c_x, z = i_neighbor.c_z}
									--local t_pos = {x = i_triple.c_x, z = i_triple.c_z}
					
									--local tri_x, tri_z = lib_mg_continental.get_triangulation_2d(c_pos, n_pos, t_pos)
									local tri_x, tri_z = lib_mg_continental.get_triangulation_2d({x = i_cell.c_x, z = i_cell.c_z}, {x = i_neighbor.c_x, z = i_neighbor.c_z}, {x = i_triple.c_x, z = i_triple.c_z})
									local cv_slope, cv_rise, cv_run = lib_mg_continental.get_slope({x = i_cell.c_x, z = i_cell.c_z}, {x = tri_x, z = tri_z})
									--local edge_slope, edge_run, edge_rise = lib_mg_continental.get_slope_inverse({x = i_cell.c_x, z = i_cell.c_z}, {x = tri_x, z = tri_z})

									local t_compass
									local t_dir = {x = 0, z = 0}
						
									lib_mg_continental.vertices[v_idx] = {}
									lib_mg_continental.vertices[v_idx].c_i = i_cell.c_i
									lib_mg_continental.vertices[v_idx].c_x = i_cell.c_x
									lib_mg_continental.vertices[v_idx].c_z = i_cell.c_z
										--lib_mg_continental.vertices[v_idx].c_pos = c_pos

									lib_mg_continental.vertices[v_idx].n1_i = i_neighbor.c_i
									lib_mg_continental.vertices[v_idx].n1_x = i_neighbor.c_x
									lib_mg_continental.vertices[v_idx].n1_z = i_neighbor.c_z
										--lib_mg_continental.vertices[v_idx].n1_pos = n_pos

									lib_mg_continental.vertices[v_idx].n2_i = i_triple.c_i
									lib_mg_continental.vertices[v_idx].n2_x = i_triple.c_x
									lib_mg_continental.vertices[v_idx].n2_z = i_triple.c_z
										--lib_mg_continental.vertices[v_idx].n2_pos = t_pos

									lib_mg_continental.vertices[v_idx].v_x = tri_x
									lib_mg_continental.vertices[v_idx].v_z = tri_z

									if tri_z > i_cell.c_z then
										t_dir.z = 1
										t_compass = "N"
									elseif tri_z < i_cell.c_z then
										t_dir.z = -1
										t_compass = "S"
									else
										t_dir.z = 0
										t_compass = ""
									end
									if tri_x > i_cell.c_x then
										t_dir.x = 1
										t_compass = t_compass .. "E"
									elseif tri_x < i_cell.c_x then
										t_dir.x = -1
										t_compass = t_compass .. "W"
									else
										t_dir.x = 0
										t_compass = t_compass .. ""
									end
									--lib_mg_continental.vertices[v_idx].v_d = t_dir
									--lib_mg_continental.vertices[v_idx].v_c = t_compass

										--lib_mg_continental.vertices[v_idx].v_pos = {x = tri_x, z = tri_z}
									lib_mg_continental.vertices[v_idx].cv_s = cv_slope
									lib_mg_continental.vertices[v_idx].cv_sx = cv_run
									lib_mg_continental.vertices[v_idx].cv_sz = cv_rise
					
									--	     "|{" .. t_dir.z .. "," .. t_dir.x .. "}|" .. t_compass .. 
									temp_vertex = v_idx .. "|".. i_cell.c_i .. "|".. i_cell.c_x .. "|" .. i_cell.c_z .. 
										     "|".. i_neighbor.c_i .. "|".. i_neighbor.c_x .. "|" .. i_neighbor.c_z .. 
										     "|".. i_triple.c_i .. "|".. i_triple.c_x .. "|" .. i_triple.c_z .. 
										     "|".. tri_x .. "|" .. tri_z .. 
										     "|".. cv_slope .. "|" .. cv_run .. "|" .. cv_rise .. "\n"

									--temp_vertex = v_idx .. "|".. i_cell.c_i .. 
									--	     "|".. i_neighbor.c_i .. 
									--	     "|".. i_triple.c_i .. 
									--	     "|".. tri_x .. "|" .. tri_z .. 
									--	     "|".. cv_slope .. "|" .. cv_run .. "|" .. cv_rise .. "\n"
								end
							end
						end

						temp_vertices = temp_vertex
						temp_vertex = ""

					end
				end
			end

			temp_list = temp_list .. temp_vertices
			temp_vertices = ""

		end
	end

	local t1 = os.clock()
	minetest.log("[lib_mg_continental] Voronoi Vertices Data generation time " .. (t1-t0) .. " ms")
	print("[lib_mg_continental] Voronoi Vertices Data generation time " .. (t1-t0) .. " ms")

	local lm_cells = lib_mg_continental.cells
	local lm_vertices = lib_mg_continental.vertices

	minetest.log("[lib_mg_continental] # of Cells: " .. #lm_cells .. ";  # of Vertices: " .. #lm_vertices .. ";")
	print("[lib_mg_continental] # of Cells: " .. #lib_mg_continental.cells .. ";  # of Vertices: " .. #lib_mg_continental.vertices .. ";")

	--minetest.log("VERTICES: " .. dump(lib_mg_continental.vertices))
	--print("VERTICES: " .. dump(t_vertex))

	--for i_v, i_vertex in pairs(lib_mg_continental.vertices) do
	--	temp_vertices = temp_vertices .. i_v .. "|".. i_vertex.c_i .. "|".. i_vertex.c_x .. "|" .. i_vertex.c_z .. 
	--		     "|".. i_vertex.n1_i .. "|".. i_vertex.n1_x .. "|" .. i_vertex.n1_z .. 
	--		     "|".. i_vertex.n2_i .. "|".. i_vertex.n2_x .. "|" .. i_vertex.n2_z .. 
	--		     "|".. i_vertex.v_x .. "|" .. i_vertex.v_z .. "\n"
	--end

	lib_mg_continental.save_csv(temp_list, "lib_mg_continental_data_vertices.txt")

	-- Random cell generation finished. Check the timer to know the elapsed time.
	local t2 = os.clock()
	minetest.log("[lib_mg_continental] Voronoi Vertices Data save time " .. (t2-t1) .. " ms")
	print("[lib_mg_continental] Voronoi Vertices Data save time " .. (t2-t1) .. " ms")

	-- Print generation time of this mapchunk.
	local chugent = math.ceil((os.clock() - t0) * 1000)
	minetest.log("[lib_mg_continental] Voronoi Vertices Data Total Time " .. chugent .. " seconds")
	print("[lib_mg_continental] Voronoi Vertices Data Total Time " .. chugent .. " seconds")

end

function lib_mg_continental.get_cell_data()

	local t0 = os.clock()
	minetest.log("[lib_mg_continental] Voronoi Cell Data (Cells, Neighbors, Midpoints) generation start")

			-- C = Cell, L = Link, N = Neighbor, M = Midpoint

			-- Index|Cell_Index|Link_Index|Cell_Zpos|CellXpos|Cell_Parent|Cell_Tier
			-- |Neighbor_Index|Neighbor_Zpos|Neighbor_Xpos|Neighbor_Parent|Neighbor_Tier
			-- |CellNeighbor_Distance|CN_Dir|CN_Compass
			-- |CellNeighbor_Slope|CellNeighbor_Run|CellNeighbor_Rise
			-- |CellMidpoint_Distance|NeighborMidpoint_Distance
			-- |Midpoint_Zpos|Midpoint_Xpos|Edge_Slope|Edge_Run|Edge_Rise

			-- "#Idx|C_Idx|L_Idx|C_Z|C_X|C_P|C_T|N_Idx|N_Z|N_X|N_P|N_T|CN_Dist|CN_Dir|CN_Compass|CN_Slope|CN_Run|CN_Rise|CM_Dist|NM_Dist|M_Z|M_X|E_Slope|E_Run|E_Rise\n"

	local temp_cells = "#C = Cell, L = Link, N = Neighbor, M = Midpoint, E = Edge\n" .. 
			   "#Index|Cell_Index|Link_Index|Cell_Zpos|Cell_Xpos|Cell_Parent|Cell_Tier" ..
			   "|Neighbor_Index|Neighbor_Zpos|Neighbor_Xpos|Neighbor_Parent|Neighbor_Tier" ..
			   "|CellNeighbor_Distance|CellNeighbor_Dir|CellNeighbor_Compass" ..
			   "|CellNeighbor_Slope|CellNeighbor_Run|CellNeighbor_Rise" ..
			   "|CellMidpoint_Distance|NeighborMidpoint_Distance" ..
			   "|Midpoint_Zpos|Midpoint_Xpos" ..
			   "|Edge_Slope|Edge_Run|Edge_Rise\n"

	for i, i_point in ipairs(lib_mg_continental.points) do

		--local tt1 = os.clock()
		temp_cells = temp_cells .. "#Idx|C_I|L_I|C_Z|C_X|N_I|N_Z|N_X|CN_D|N_D|CN_C|CN_S|CN_SX|CN_SZ|CM_D|NM_D|M_Z|M_X|E_S|E_SX|E_SZ\n"

		for k,  k_point in ipairs(lib_mg_continental.points) do
	
			local neighbor_add = false
			local t_compass
			local t_dir = {x = 0, z = 0}

			if i ~= k then

				local t_mid_x, t_mid_z = lib_mg_continental.get_midpoint({x = k_point.x, z = k_point.z}, {x = i_point.x, z = i_point.z})

				local t_mid_cell = lib_mg_continental.get_closest_cell({x = t_mid_x, z = t_mid_z}, "e")
				local t_mid_tier = lib_mg_continental.get_closest_cell({x = t_mid_x, z = t_mid_z}, "e", k_point.tier)

				if (t_mid_cell) == i or (t_mid_cell == k) then
					neighbor_add = true
				end
				if (t_mid_tier) == i or (t_mid_tier == k) then
					neighbor_add = true
				end

			end

			if neighbor_add == true then
				local m_point_x, m_point_z = lib_mg_continental.get_midpoint({x = k_point.x, z = k_point.z}, {x = i_point.x, z = i_point.z})
				local cn_dist = lib_mg_continental.get_distance_euclid({x = k_point.x, z = k_point.z}, {x = i_point.x, z = i_point.z})
				local cm_dist = lib_mg_continental.get_distance_euclid({x = m_point_x, z = m_point_z}, {x = i_point.x, z = i_point.z})
				local nm_dist = lib_mg_continental.get_distance_euclid({x = m_point_x, z = m_point_z}, {x = k_point.x, z = k_point.z})
				local cn_slope, cn_rise, cn_run = lib_mg_continental.get_slope({x = k_point.x, z = k_point.z}, {x = i_point.x, z = i_point.z})
				local edge_slope, edge_run, edge_rise = lib_mg_continental.get_slope_inverse({x = k_point.x, z = k_point.z}, {x = i_point.x, z = i_point.z})


				lib_mg_continental.cells[i .. "-" .. k] = {}
				lib_mg_continental.cells[i .. "-" .. k].c_i = i
				lib_mg_continental.cells[i .. "-" .. k].l_i = i .. "-" .. k
				lib_mg_continental.cells[i .. "-" .. k].c_z = i_point.z
				lib_mg_continental.cells[i .. "-" .. k].c_x = i_point.x
				--lib_mg_continental.cells[i .. "-" .. k].c_p = i_point.parent
				--lib_mg_continental.cells[i .. "-" .. k].c_t = i_point.tier
				lib_mg_continental.cells[i .. "-" .. k].n_i = k
				lib_mg_continental.cells[i .. "-" .. k].n_z = k_point.z
				lib_mg_continental.cells[i .. "-" .. k].n_x = k_point.x
				--lib_mg_continental.cells[i .. "-" .. k].n_p = k_point.parent
				--lib_mg_continental.cells[i .. "-" .. k].n_t = k_point.tier
				lib_mg_continental.cells[i .. "-" .. k].cn_d = cn_dist
				if k_point.z > i_point.z then
					t_dir.z = 1
					t_compass = "N"
				elseif k_point.z < i_point.z then
					t_dir.z = -1
					t_compass = "S"
				else
					t_dir.z = 0
					t_compass = ""
				end
				if k_point.x > i_point.x then
					t_dir.x = 1
					t_compass = t_compass .. "E"
				elseif k_point.x < i_point.x then
					t_dir.x = -1
					t_compass = t_compass .. "W"
				else
					t_dir.x = 0
					t_compass = t_compass .. ""
				end
				lib_mg_continental.cells[i .. "-" .. k].n_d = t_dir
				lib_mg_continental.cells[i .. "-" .. k].cn_c = t_compass
				lib_mg_continental.cells[i .. "-" .. k].cn_s = cn_slope
				lib_mg_continental.cells[i .. "-" .. k].cn_sx = cn_run
				lib_mg_continental.cells[i .. "-" .. k].cn_sz = cn_rise
				lib_mg_continental.cells[i .. "-" .. k].cm_d = cm_dist
				lib_mg_continental.cells[i .. "-" .. k].nm_d = nm_dist
				lib_mg_continental.cells[i .. "-" .. k].m_z = m_point_z
				lib_mg_continental.cells[i .. "-" .. k].m_x = m_point_x
				lib_mg_continental.cells[i .. "-" .. k].e_s = edge_slope
				lib_mg_continental.cells[i .. "-" .. k].e_sx = edge_run
				lib_mg_continental.cells[i .. "-" .. k].e_sz = edge_rise

				-- "|" .. i_point.parent .. "|" .. i_point.tier ..
				-- "|" .. k_point.parent .."|" .. k_point.tier ..
				temp_cells = temp_cells .. i .. "-" .. k .. "|".. i .. "|" .. i .. "-" .. k .. "|" .. i_point.z .. "|" .. i_point.x ..
					"|" .. k .. "|" .. k_point.z .. "|" .. k_point.x .. 
					"|" .. cn_dist .. "|{" .. t_dir.z .. "," .. t_dir.x .. "}|" .. t_compass .. 
					"|" .. cn_slope .. "|" .. cn_run .. "|" .. cn_rise .. 
					"|" .. cm_dist .. "|" .. nm_dist .. 
					"|" .. m_point_z .. "|" .. m_point_x .. 
					"|" .. edge_slope .. "|" .. edge_run .. "|" .. edge_rise .. "\n"
			end
		end

		temp_cells = temp_cells .. "#" .. "\n"

		--local t_elapsed = (i / #lib_mg_continental.points) * 100
		--local tt2 = os.clock()
		--print("[lib_mg_continental] Voronoi Cell Data -- Time Elapsed " .. (tt2-tt1) .. " ms")
		--print("[lib_mg_continental] Voronoi Cell Data -- Percentage Complete " .. t_elapsed .. "%")
		--print("[lib_mg_continental] Voronoi Cell Data -- Total Time Elapsed " .. (tt2-t0) .. " ms")

	end

	-- Random cell generation finished. Check the timer to know the elapsed time.
	local t1 = os.clock()
	minetest.log("[lib_mg_continental] Voronoi Cell Data (Cells, Neighbors, Midpoints) generation time " .. (t1-t0) .. " ms")

	lib_mg_continental.save_csv(temp_cells, "lib_mg_continental_data_cells.txt")

	-- Random cell generation finished. Check the timer to know the elapsed time.
	local t2 = os.clock()
	minetest.log("[lib_mg_continental] Voronoi Cell Data (Cells, Neighbors, Midpoints) save time " .. (t2-t1) .. " ms")

	-- Print generation time of this mapchunk.
	local chugent = math.ceil(os.clock() - t0)
	local ch_gen_time
	local ch_gen_str = ""
	if chugent < 60 then
		ch_gen_time = chugent
		ch_gen_str = "seconds"
	elseif (chugent >= 60) and (chugent < 3600) then
		ch_gen_time = chugent / 60
		ch_gen_str = "minutes"
	elseif (chugent >= 3600) and (chugent < (3600*24)) then
		ch_gen_time = chugent / (3600*24)
		ch_gen_str = "hours"
	elseif (chugent >= (3600*24)) then
		ch_gen_time = chugent / (3600*24)
		ch_gen_str = "days"
	else
		ch_gen_time = chugent
		ch_gen_str = "milliseconds"
	end

	minetest.log("[lib_mg_continental] Voronoi Cell Data Total Time " .. ch_gen_time .. " " .. ch_gen_str)

end
--]]
function lib_mg_continental.make_voronoi_recursive(cells_x, cells_y, cells_z, size)

	if not cells_x or not cells_y or not cells_z or not size then
		return
	end

	-- Start time of voronoi generation.
	local t0 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Generation Start")

	local temp_points = "#Cell_Idx|Cell_Z|Cell_X|Master_Idx|Parent_Idx|Tier\n" ..
			    "#C_Idx|C_Z|C_X|M_Idx|P_Idx|Tier\n"

	--Prevents points from too near edges, ideally creating more evenly sized cells.
	local size_offset = size * 0.1
	local size_half = size * 0.5
--[[
	local cells_sqrt = cells_x^0.5
	local cells_grid_size, cells_grid_rmdr = modf(cells_sqrt / 1)
	local cells_grid_size_half = cells_grid_size * 0.5
	local cells_count = cells_x - (cells_grid_size^2)
	local map_grid_size = (size - (size_offset * 2)) / cells_grid_size
	local x_cntr = size_offset
	local z_cntr = map_grid_size
	local t_points = {}
	local t_idx = 1

	for i_x = 1, cells_grid_size do
		for i_z = 1, cells_grid_size do
			local t_pt_x = math.random(x_cntr, z_cntr) - size_half
			local t_pt_z = math.random(x_cntr, z_cntr) - size_half
			t_points[t_idx] = {}
			t_points[t_idx].x = t_pt_x
			t_points[t_idx].z = t_pt_z
			t_idx = t_idx + 1
			z_cntr = z_cntr + map_grid_size
		end
		x_cntr = x_cntr + map_grid_size
		z_cntr = map_grid_size
	end
--]]
	local v_idx = 1

	for i_c = 1, cells_x do

		--local m_pt_x = t_points[v_idx].x
		--local m_pt_z = t_points[v_idx].z
		local m_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
		local m_pt_z = math.random(1 + size_offset, size - size_offset) - size_half

		--for pt, pts in pairs(t_points) do
		--	if abs(c_pt_x - pts.x) <= map_grid_size then
		--		c_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
		--	end
		--	if abs(c_pt_z - pts.z) <= map_grid_size then
		--		c_pt_z = math.random(1 + size_offset, size - size_offset) - size_half
		--	end
		--	--if lib_mg_continental.get_distance_euclid({x = c_pt_x, z = c_pt_z}, {x = pts.x, z = pts.z}) <= map_grid_size then
		--	--	c_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
		--	--	c_pt_z = math.random(1 + size_offset, size - size_offset) - size_half
		--	--end
		--end

		lib_mg_continental.points[v_idx] = {}
		lib_mg_continental.points[v_idx].z = m_pt_z
		lib_mg_continental.points[v_idx].x = m_pt_x

		lib_mg_continental.points[v_idx].m_ai = v_idx
		lib_mg_continental.points[v_idx].m_ad = v_idx
		lib_mg_continental.points[v_idx].m_as = v_idx
		lib_mg_continental.points[v_idx].m_asz = v_idx
		lib_mg_continental.points[v_idx].m_asx = v_idx
		lib_mg_continental.points[v_idx].m_adx = v_idx
		lib_mg_continental.points[v_idx].m_adz = v_idx
		lib_mg_continental.points[v_idx].m_ac = v_idx

		lib_mg_continental.points[v_idx].m_ci = v_idx
		lib_mg_continental.points[v_idx].m_cd = v_idx
		lib_mg_continental.points[v_idx].m_cs = v_idx
		lib_mg_continental.points[v_idx].m_csz = v_idx
		lib_mg_continental.points[v_idx].m_csx = v_idx
		lib_mg_continental.points[v_idx].m_cdx = v_idx
		lib_mg_continental.points[v_idx].m_cdz = v_idx
		lib_mg_continental.points[v_idx].m_cc = v_idx

		lib_mg_continental.points[v_idx].m_ei = v_idx
		lib_mg_continental.points[v_idx].m_ed = v_idx
		lib_mg_continental.points[v_idx].m_es = v_idx
		lib_mg_continental.points[v_idx].m_esz = v_idx
		lib_mg_continental.points[v_idx].m_esx = v_idx
		lib_mg_continental.points[v_idx].m_edx = v_idx
		lib_mg_continental.points[v_idx].m_edz = v_idx
		lib_mg_continental.points[v_idx].m_ec = v_idx

		lib_mg_continental.points[v_idx].m_mi = v_idx
		lib_mg_continental.points[v_idx].m_md = v_idx
		lib_mg_continental.points[v_idx].m_ms = v_idx
		lib_mg_continental.points[v_idx].m_msz = v_idx
		lib_mg_continental.points[v_idx].m_msx = v_idx
		lib_mg_continental.points[v_idx].m_mdx = v_idx
		lib_mg_continental.points[v_idx].m_mdz = v_idx
		lib_mg_continental.points[v_idx].m_mc = v_idx

		lib_mg_continental.points[v_idx].p_ai = v_idx
		lib_mg_continental.points[v_idx].p_ad = v_idx
		lib_mg_continental.points[v_idx].p_as = v_idx
		lib_mg_continental.points[v_idx].p_asz = v_idx
		lib_mg_continental.points[v_idx].p_asx = v_idx
		lib_mg_continental.points[v_idx].p_adx = v_idx
		lib_mg_continental.points[v_idx].p_adz = v_idx
		lib_mg_continental.points[v_idx].p_ac = v_idx

		lib_mg_continental.points[v_idx].p_ci = v_idx
		lib_mg_continental.points[v_idx].p_cd = v_idx
		lib_mg_continental.points[v_idx].p_cs = v_idx
		lib_mg_continental.points[v_idx].p_csz = v_idx
		lib_mg_continental.points[v_idx].p_csx = v_idx
		lib_mg_continental.points[v_idx].p_cdx = v_idx
		lib_mg_continental.points[v_idx].p_cdz = v_idx
		lib_mg_continental.points[v_idx].p_cc = v_idx

		lib_mg_continental.points[v_idx].p_ei = v_idx
		lib_mg_continental.points[v_idx].p_ed = v_idx
		lib_mg_continental.points[v_idx].p_es = v_idx
		lib_mg_continental.points[v_idx].p_esz = v_idx
		lib_mg_continental.points[v_idx].p_esx = v_idx
		lib_mg_continental.points[v_idx].p_edx = v_idx
		lib_mg_continental.points[v_idx].p_edz = v_idx
		lib_mg_continental.points[v_idx].p_ec = v_idx

		lib_mg_continental.points[v_idx].p_mi = v_idx
		lib_mg_continental.points[v_idx].p_md = v_idx
		lib_mg_continental.points[v_idx].p_ms = v_idx
		lib_mg_continental.points[v_idx].p_msz = v_idx
		lib_mg_continental.points[v_idx].p_msx = v_idx
		lib_mg_continental.points[v_idx].p_mdx = v_idx
		lib_mg_continental.points[v_idx].p_mdz = v_idx
		lib_mg_continental.points[v_idx].p_mc = v_idx
		lib_mg_continental.points[v_idx].tier = 1
		--t_points[v_idx] = {x = m_pt_x, z = m_pt_z}
		temp_points = temp_points .. v_idx .. "|" .. m_pt_z .. "|" .. m_pt_x .. 
				"|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. 
				"|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. 
				"|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. 
				"|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. 
				"|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. 
				"|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. 
				"|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. 
				"|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. "|" .. v_idx .. 
				"|" .. "1" .. "\n"

		v_idx = v_idx + 1

	end
	temp_points = temp_points .. "#" .. "\n"
	local t1 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Tier 1 Generation Time: " .. (t1-t0) .. " ms")


	--#(cells_x * (cells_y - 1))
	for i_t = 1, (cells_x * cells_y) do

		local p_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
		local p_pt_z = math.random(1 + size_offset, size - size_offset) - size_half
		local c_ai, c_ad, c_as, c_asz, c_asx, c_adx, c_adz, c_ac = lib_mg_continental.get_nearest_cell2({x = p_pt_x, z = p_pt_z}, "a", 1)
		local c_ci, c_cd, c_cs, c_csz, c_csx, c_cdx, c_cdz, c_cc = lib_mg_continental.get_nearest_cell2({x = p_pt_x, z = p_pt_z}, "c", 1)
		local c_ei, c_ed, c_es, c_esz, c_esx, c_edx, c_edz, c_ec = lib_mg_continental.get_nearest_cell2({x = p_pt_x, z = p_pt_z}, "e", 1)
		local c_mi, c_md, c_ms, c_msz, c_msx, c_mdx, c_mdz, c_mc = lib_mg_continental.get_nearest_cell2({x = p_pt_x, z = p_pt_z}, "m", 1)

		lib_mg_continental.points[v_idx] = {}
		lib_mg_continental.points[v_idx].z = p_pt_z
		lib_mg_continental.points[v_idx].x = p_pt_x
		lib_mg_continental.points[v_idx].m_ai = c_ai
		lib_mg_continental.points[v_idx].m_ad = c_ad
		lib_mg_continental.points[v_idx].m_as = c_as
		lib_mg_continental.points[v_idx].m_asz = c_asz
		lib_mg_continental.points[v_idx].m_asx = c_asx
		lib_mg_continental.points[v_idx].m_adx = c_adx
		lib_mg_continental.points[v_idx].m_adz = c_adz
		lib_mg_continental.points[v_idx].m_ac = c_ac

		lib_mg_continental.points[v_idx].m_ci = c_ci
		lib_mg_continental.points[v_idx].m_cd = c_cd
		lib_mg_continental.points[v_idx].m_cs = c_cs
		lib_mg_continental.points[v_idx].m_csz = c_csz
		lib_mg_continental.points[v_idx].m_csx = c_csx
		lib_mg_continental.points[v_idx].m_cdx = c_cdx
		lib_mg_continental.points[v_idx].m_cdz = c_cdz
		lib_mg_continental.points[v_idx].m_cc = c_cc

		lib_mg_continental.points[v_idx].m_ei = c_ei
		lib_mg_continental.points[v_idx].m_ed = c_ed
		lib_mg_continental.points[v_idx].m_es = c_es
		lib_mg_continental.points[v_idx].m_esz = c_esz
		lib_mg_continental.points[v_idx].m_esx = c_esx
		lib_mg_continental.points[v_idx].m_edx = c_edx
		lib_mg_continental.points[v_idx].m_edz = c_edz
		lib_mg_continental.points[v_idx].m_ec = c_ec

		lib_mg_continental.points[v_idx].m_mi = c_mi
		lib_mg_continental.points[v_idx].m_md = c_md
		lib_mg_continental.points[v_idx].m_ms = c_ms
		lib_mg_continental.points[v_idx].m_msz = c_msz
		lib_mg_continental.points[v_idx].m_msx = c_msx
		lib_mg_continental.points[v_idx].m_mdx = c_mdx
		lib_mg_continental.points[v_idx].m_mdz = c_mdz
		lib_mg_continental.points[v_idx].m_mc = c_mc

		lib_mg_continental.points[v_idx].p_ai = c_ai
		lib_mg_continental.points[v_idx].p_ad = c_ad
		lib_mg_continental.points[v_idx].p_as = c_as
		lib_mg_continental.points[v_idx].p_asz = c_asz
		lib_mg_continental.points[v_idx].p_asx = c_asx
		lib_mg_continental.points[v_idx].p_adx = c_adx
		lib_mg_continental.points[v_idx].p_adz = c_adz
		lib_mg_continental.points[v_idx].p_ac = c_ac

		lib_mg_continental.points[v_idx].p_ci = c_ci
		lib_mg_continental.points[v_idx].p_cd = c_cd
		lib_mg_continental.points[v_idx].p_cs = c_cs
		lib_mg_continental.points[v_idx].p_csz = c_csz
		lib_mg_continental.points[v_idx].p_csx = c_csx
		lib_mg_continental.points[v_idx].p_cdx = c_cdx
		lib_mg_continental.points[v_idx].p_cdz = c_cdz
		lib_mg_continental.points[v_idx].p_cc = c_cc

		lib_mg_continental.points[v_idx].p_ei = c_ei
		lib_mg_continental.points[v_idx].p_ed = c_ed
		lib_mg_continental.points[v_idx].p_es = c_es
		lib_mg_continental.points[v_idx].p_esz = c_esz
		lib_mg_continental.points[v_idx].p_esx = c_esx
		lib_mg_continental.points[v_idx].p_edx = c_edx
		lib_mg_continental.points[v_idx].p_edz = c_edz
		lib_mg_continental.points[v_idx].p_ec = c_ec

		lib_mg_continental.points[v_idx].p_mi = c_mi
		lib_mg_continental.points[v_idx].p_md = c_md
		lib_mg_continental.points[v_idx].p_ms = c_ms
		lib_mg_continental.points[v_idx].p_msz = c_msz
		lib_mg_continental.points[v_idx].p_msx = c_msx
		lib_mg_continental.points[v_idx].p_mdx = c_mdx
		lib_mg_continental.points[v_idx].p_mdz = c_mdz
		lib_mg_continental.points[v_idx].p_mc = c_mc
		lib_mg_continental.points[v_idx].tier = 2
		temp_points = temp_points .. v_idx .. "|" .. p_pt_z .. "|" .. p_pt_x .. 
				"|" .. c_ai .. "|" .. c_ad .. "|" .. c_as .. "|" .. c_asz .. "|" .. c_asx .. "|" .. c_adx .. "|" .. c_adz .. "|" .. c_ac .. 
				"|" .. c_ci .. "|" .. c_cd .. "|" .. c_cs .. "|" .. c_csz .. "|" .. c_csx .. "|" .. c_cdx .. "|" .. c_cdz .. "|" .. c_cc .. 
				"|" .. c_ei .. "|" .. c_ed .. "|" .. c_es .. "|" .. c_esz .. "|" .. c_esx .. "|" .. c_edx .. "|" .. c_edz .. "|" .. c_ec .. 
				"|" .. c_mi .. "|" .. c_md .. "|" .. c_ms .. "|" .. c_msz .. "|" .. c_msx .. "|" .. c_mdx .. "|" .. c_mdz .. "|" .. c_mc .. 
				"|" .. c_ai .. "|" .. c_ad .. "|" .. c_as .. "|" .. c_asz .. "|" .. c_asx .. "|" .. c_adx .. "|" .. c_adz .. "|" .. c_ac .. 
				"|" .. c_ci .. "|" .. c_cd .. "|" .. c_cs .. "|" .. c_csz .. "|" .. c_csx .. "|" .. c_cdx .. "|" .. c_cdz .. "|" .. c_cc .. 
				"|" .. c_ei .. "|" .. c_ed .. "|" .. c_es .. "|" .. c_esz .. "|" .. c_esx .. "|" .. c_edx .. "|" .. c_edz .. "|" .. c_ec .. 
				"|" .. c_mi .. "|" .. c_md .. "|" .. c_ms .. "|" .. c_msz .. "|" .. c_msx .. "|" .. c_mdx .. "|" .. c_mdz .. "|" .. c_mc .. 
				"|" .. "2" .. "\n"

		v_idx = v_idx + 1
	end
	temp_points = temp_points .. "#" .. "\n"
	local t2 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Tier 2 Generation Time: " .. (t2-t1) .. " ms")


	--#((cells_x * cells_y * cells_z) - (cells_x * cells_y))
	for i_c = 1, (cells_x * cells_y * cells_z) do

		local c_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
		local c_pt_z = math.random(1 + size_offset, size - size_offset) - size_half
		local m_ai, m_ad, m_as, m_asz, m_asx, m_adx, m_adz, m_ac = lib_mg_continental.get_nearest_cell2({x = c_pt_x, z = c_pt_z}, "a", 1)
		local m_ci, m_cd, m_cs, m_csz, m_csx, m_cdx, m_cdz, m_cc = lib_mg_continental.get_nearest_cell2({x = c_pt_x, z = c_pt_z}, "c", 1)
		local m_ei, m_ed, m_es, m_esz, m_esx, m_edx, m_edz, m_ec = lib_mg_continental.get_nearest_cell2({x = c_pt_x, z = c_pt_z}, "e", 1)
		local m_mi, m_md, m_ms, m_msz, m_msx, m_mdx, m_mdz, m_mc = lib_mg_continental.get_nearest_cell2({x = c_pt_x, z = c_pt_z}, "m", 1)
		local p_ai, p_ad, p_as, p_asz, p_asx, p_adx, p_adz, p_ac = lib_mg_continental.get_nearest_cell2({x = c_pt_x, z = c_pt_z}, "a", 2)
		local p_ci, p_cd, p_cs, p_csz, p_csx, p_cdx, p_cdz, p_cc = lib_mg_continental.get_nearest_cell2({x = c_pt_x, z = c_pt_z}, "c", 2)
		local p_ei, p_ed, p_es, p_esz, p_esx, p_edx, p_edz, p_ec = lib_mg_continental.get_nearest_cell2({x = c_pt_x, z = c_pt_z}, "e", 2)
		local p_mi, p_md, p_ms, p_msz, p_msx, p_mdx, p_mdz, p_mc = lib_mg_continental.get_nearest_cell2({x = c_pt_x, z = c_pt_z}, "m", 2)

		lib_mg_continental.points[v_idx] = {}
		lib_mg_continental.points[v_idx].z = c_pt_z
		lib_mg_continental.points[v_idx].x = c_pt_x
		lib_mg_continental.points[v_idx].m_ai = m_ai
		lib_mg_continental.points[v_idx].m_ad = m_ad
		lib_mg_continental.points[v_idx].m_as = m_as
		lib_mg_continental.points[v_idx].m_asz = m_asz
		lib_mg_continental.points[v_idx].m_asx = m_asx
		lib_mg_continental.points[v_idx].m_adx = m_adx
		lib_mg_continental.points[v_idx].m_adz = m_adz
		lib_mg_continental.points[v_idx].m_ac = m_ac

		lib_mg_continental.points[v_idx].m_ci = m_ci
		lib_mg_continental.points[v_idx].m_cd = m_cd
		lib_mg_continental.points[v_idx].m_cs = m_cs
		lib_mg_continental.points[v_idx].m_csz = m_csz
		lib_mg_continental.points[v_idx].m_csx = m_csx
		lib_mg_continental.points[v_idx].m_cdx = m_cdx
		lib_mg_continental.points[v_idx].m_cdz = m_cdz
		lib_mg_continental.points[v_idx].m_cc = m_cc

		lib_mg_continental.points[v_idx].m_ei = m_ei
		lib_mg_continental.points[v_idx].m_ed = m_ed
		lib_mg_continental.points[v_idx].m_es = m_es
		lib_mg_continental.points[v_idx].m_esz = m_esz
		lib_mg_continental.points[v_idx].m_esx = m_esx
		lib_mg_continental.points[v_idx].m_edx = m_edx
		lib_mg_continental.points[v_idx].m_edz = m_edz
		lib_mg_continental.points[v_idx].m_ec = m_ec

		lib_mg_continental.points[v_idx].m_mi = m_mi
		lib_mg_continental.points[v_idx].m_md = m_md
		lib_mg_continental.points[v_idx].m_ms = m_ms
		lib_mg_continental.points[v_idx].m_msz = m_msz
		lib_mg_continental.points[v_idx].m_msx = m_msx
		lib_mg_continental.points[v_idx].m_mdx = m_mdx
		lib_mg_continental.points[v_idx].m_mdz = m_mdz
		lib_mg_continental.points[v_idx].m_mc = m_mc

		lib_mg_continental.points[v_idx].p_ai = p_ai
		lib_mg_continental.points[v_idx].p_ad = p_ad
		lib_mg_continental.points[v_idx].p_as = p_as
		lib_mg_continental.points[v_idx].p_asz = p_asz
		lib_mg_continental.points[v_idx].p_asx = p_asx
		lib_mg_continental.points[v_idx].p_adx = p_adx
		lib_mg_continental.points[v_idx].p_adz = p_adz
		lib_mg_continental.points[v_idx].p_ac = p_ac

		lib_mg_continental.points[v_idx].p_ci = p_ci
		lib_mg_continental.points[v_idx].p_cd = p_cd
		lib_mg_continental.points[v_idx].p_cs = p_cs
		lib_mg_continental.points[v_idx].p_csz = p_csz
		lib_mg_continental.points[v_idx].p_csx = p_csx
		lib_mg_continental.points[v_idx].p_cdx = p_cdx
		lib_mg_continental.points[v_idx].p_cdz = p_cdz
		lib_mg_continental.points[v_idx].p_cc = p_cc

		lib_mg_continental.points[v_idx].p_ei = p_ei
		lib_mg_continental.points[v_idx].p_ed = p_ed
		lib_mg_continental.points[v_idx].p_es = p_es
		lib_mg_continental.points[v_idx].p_esz = p_esz
		lib_mg_continental.points[v_idx].p_esx = p_esx
		lib_mg_continental.points[v_idx].p_edx = p_edx
		lib_mg_continental.points[v_idx].p_edz = p_edz
		lib_mg_continental.points[v_idx].p_ec = p_ec

		lib_mg_continental.points[v_idx].p_mi = p_mi
		lib_mg_continental.points[v_idx].p_md = p_md
		lib_mg_continental.points[v_idx].p_ms = p_ms
		lib_mg_continental.points[v_idx].p_msz = p_msz
		lib_mg_continental.points[v_idx].p_msx = p_msx
		lib_mg_continental.points[v_idx].p_mdx = p_mdx
		lib_mg_continental.points[v_idx].p_mdz = p_mdz
		lib_mg_continental.points[v_idx].p_mc = p_mc
		lib_mg_continental.points[v_idx].tier = 3
		temp_points = temp_points .. v_idx .. "|" .. c_pt_z .. "|" .. c_pt_x .. 
				"|" .. m_ai .. "|" .. m_ad .. "|" .. m_as .. "|" .. m_asz .. "|" .. m_asx .. "|" .. m_adx .. "|" .. m_adz .. "|" .. m_ac .. 
				"|" .. m_ci .. "|" .. m_cd .. "|" .. m_cs .. "|" .. m_csz .. "|" .. m_csx .. "|" .. m_cdx .. "|" .. m_cdz .. "|" .. m_cc .. 
				"|" .. m_ei .. "|" .. m_ed .. "|" .. m_es .. "|" .. m_esz .. "|" .. m_esx .. "|" .. m_edx .. "|" .. m_edz .. "|" .. m_ec .. 
				"|" .. m_mi .. "|" .. m_md .. "|" .. m_ms .. "|" .. m_msz .. "|" .. m_msx .. "|" .. m_mdx .. "|" .. m_mdz .. "|" .. m_mc .. 
				"|" .. p_ai .. "|" .. p_ad .. "|" .. p_as .. "|" .. p_asz .. "|" .. p_asx .. "|" .. p_adx .. "|" .. p_adz .. "|" .. p_ac .. 
				"|" .. p_ci .. "|" .. p_cd .. "|" .. p_cs .. "|" .. p_csz .. "|" .. p_csx .. "|" .. p_cdx .. "|" .. p_cdz .. "|" .. p_cc .. 
				"|" .. p_ei .. "|" .. p_ed .. "|" .. p_es .. "|" .. p_esz .. "|" .. p_esx .. "|" .. p_edx .. "|" .. p_edz .. "|" .. p_ec .. 
				"|" .. p_mi .. "|" .. p_md .. "|" .. p_ms .. "|" .. p_msz .. "|" .. p_msx .. "|" .. p_mdx .. "|" .. p_mdz .. "|" .. p_mc .. 
				"|" .. "3" .. "\n"

		v_idx = v_idx + 1

	end
	temp_points = temp_points .. "#" .. "\n"
	local t3 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Tier 3 Generation Time: " .. (t3-t2) .. " ms")

	lib_mg_continental.save_csv(temp_points, "lib_mg_continental_data_points.txt")
	local t4 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Save Data Time: " .. (t4-t3) .. " ms")

	-- Random Points generation finished. Check the timer to know the elapsed time.
	local t5 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Total Generation Time: " .. (t5-t0) .. " ms")

end

function lib_mg_continental.make_voronoi_recursive_lite(cells_x, cells_y, cells_z, size, dist_type)

	if not cells_x or not cells_y or not cells_z or not size then
		return
	end

	local d_type
	if dist_type and (dist_type ~= "") then
		d_type = dist_type
	else
		d_type = "e"
	end

	-- Start time of voronoi generation.
	local t0 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Generation Start")

	local temp_points = "#Cell_Idx|Cell_Z|Cell_X|Tier\n" ..
			    "#C_Idx|C_Z|C_X|Tier\n"

	--Prevents points from too near edges, ideally creating more evenly sized cells.
	local size_offset = size * 0.1
	local size_half = size * 0.5

	local v_idx = 1

	for i_c = 1, cells_x do

		--local m_pt_x = t_points[v_idx].x
		--local m_pt_z = t_points[v_idx].z
		local m_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
		local m_pt_z = math.random(1 + size_offset, size - size_offset) - size_half

		lib_mg_continental.points[v_idx] = {}
		lib_mg_continental.points[v_idx].z = m_pt_z
		lib_mg_continental.points[v_idx].x = m_pt_x

		lib_mg_continental.points[v_idx].tier = 1

		--t_points[v_idx] = {x = m_pt_x, z = m_pt_z}
		temp_points = temp_points .. v_idx .. "|" .. m_pt_z .. "|" .. m_pt_x .. 
				"|" .. "1" .. "\n"

		v_idx = v_idx + 1

	end
	temp_points = temp_points .. "#" .. "\n"
	local t1 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Tier 1 Generation Time: " .. (t1-t0) .. " ms")


	--#(cells_x * (cells_y - 1))
	for i_t = 1, (cells_x * cells_y) do

		local p_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
		local p_pt_z = math.random(1 + size_offset, size - size_offset) - size_half

		lib_mg_continental.points[v_idx] = {}
		lib_mg_continental.points[v_idx].z = p_pt_z
		lib_mg_continental.points[v_idx].x = p_pt_x

		lib_mg_continental.points[v_idx].tier = 2

		temp_points = temp_points .. v_idx .. "|" .. p_pt_z .. "|" .. p_pt_x .. 
				"|" .. "2" .. "\n"

		v_idx = v_idx + 1
	end
	temp_points = temp_points .. "#" .. "\n"
	local t2 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Tier 2 Generation Time: " .. (t2-t1) .. " ms")


	--#((cells_x * cells_y * cells_z) - (cells_x * cells_y))
	for i_c = 1, (cells_x * cells_y * cells_z) do

		local c_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
		local c_pt_z = math.random(1 + size_offset, size - size_offset) - size_half

		lib_mg_continental.points[v_idx] = {}
		lib_mg_continental.points[v_idx].z = c_pt_z
		lib_mg_continental.points[v_idx].x = c_pt_x

		lib_mg_continental.points[v_idx].tier = 3

		temp_points = temp_points .. v_idx .. "|" .. c_pt_z .. "|" .. c_pt_x .. 
				"|" .. "3" .. "\n"

		v_idx = v_idx + 1

	end
	temp_points = temp_points .. "#" .. "\n"
	local t3 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Tier 3 Generation Time: " .. (t3-t2) .. " ms")

	lib_mg_continental.save_csv(temp_points, "lib_mg_continental_data_points.txt")
	local t4 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Save Data Time: " .. (t4-t3) .. " ms")

	-- Random Points generation finished. Check the timer to know the elapsed time.
	local t5 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Total Generation Time: " .. (t5-t0) .. " ms")

end

function lib_mg_continental.make_voronoi_recursive_3d_lite(cells_x, cells_y, cells_z, size, dist_type)

	if not cells_x or not cells_y or not cells_z or not size then
		return
	end

	local d_type
	if dist_type and (dist_type ~= "") then
		d_type = dist_type
	else
		d_type = "e"
	end

	-- Start time of voronoi generation.
	local t0 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Generation Start")

	local temp_points = "#Cell_Idx|Cell_Z|Cell_Y|Cell_X|Master_Idx|Parent_Idx|Tier\n" ..
			    "#C_Idx|C_Z|C_Y|C_X|M_Idx|P_Idx|Tier\n"

	--Prevents points from too near edges, ideally creating more evenly sized cells.
	local size_offset = size * 0.1
	local size_half = size * 0.5

	local v_idx = 1

	for i_c = 1, cells_x do

		local m_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
		local m_pt_y = math.random(base_min, base_rng)
		local m_pt_z = math.random(1 + size_offset, size - size_offset) - size_half

		lib_mg_continental.points[v_idx] = {}

		lib_mg_continental.points[v_idx].z = m_pt_z
		lib_mg_continental.points[v_idx].y = m_pt_y
		lib_mg_continental.points[v_idx].x = m_pt_x

		lib_mg_continental.points[v_idx].tier = 1

		--t_points[v_idx] = {x = m_pt_x, z = m_pt_z}
		temp_points = temp_points .. v_idx .. "|" .. m_pt_z .. "|" .. m_pt_y .. "|" .. m_pt_x .. 
				"|" .. "1" .. "\n"

		v_idx = v_idx + 1

	end
	temp_points = temp_points .. "#" .. "\n"
	local t1 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Tier 1 Generation Time: " .. (t1-t0) .. " ms")


	--#(cells_x * (cells_y - 1))
	for i_t = 1, (cells_x * cells_y) do

		local p_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
		local p_pt_y = math.random(base_min, base_rng)
		local p_pt_z = math.random(1 + size_offset, size - size_offset) - size_half

		lib_mg_continental.points[v_idx] = {}
		lib_mg_continental.points[v_idx].z = p_pt_z
		lib_mg_continental.points[v_idx].y = p_pt_y
		lib_mg_continental.points[v_idx].x = p_pt_x

		lib_mg_continental.points[v_idx].tier = 2

		temp_points = temp_points .. v_idx .. "|" .. p_pt_z .. "|" .. p_pt_y .. "|" .. p_pt_x .. 
				"|" .. "2" .. "\n"

		v_idx = v_idx + 1
	end
	temp_points = temp_points .. "#" .. "\n"
	local t2 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Tier 2 Generation Time: " .. (t2-t1) .. " ms")


	--#((cells_x * cells_y * cells_z) - (cells_x * cells_y))
	for i_c = 1, (cells_x * cells_y * cells_z) do

		local c_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
		local c_pt_y = math.random(base_min, base_rng)
		local c_pt_z = math.random(1 + size_offset, size - size_offset) - size_half

		lib_mg_continental.points[v_idx] = {}
		lib_mg_continental.points[v_idx].z = c_pt_z
		lib_mg_continental.points[v_idx].y = c_pt_y
		lib_mg_continental.points[v_idx].x = c_pt_x


		lib_mg_continental.points[v_idx].tier = 3

		temp_points = temp_points .. v_idx .. "|" .. c_pt_z .. "|" .. c_pt_y .. "|" .. c_pt_x .. 
				"|" .. "3" .. "\n"

		v_idx = v_idx + 1

	end
	temp_points = temp_points .. "#" .. "\n"
	local t3 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Tier 3 Generation Time: " .. (t3-t2) .. " ms")

	lib_mg_continental.save_csv(temp_points, "lib_mg_continental_data_points.txt")
	local t4 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Save Data Time: " .. (t4-t3) .. " ms")

	-- Random Points generation finished. Check the timer to know the elapsed time.
	local t5 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Total Generation Time: " .. (t5-t0) .. " ms")

end

function lib_mg_continental.load_points()

	local t_points
	local t_scale = 0.1

	if voronoi_mod_defaults == true then
		t_points = lib_mg_continental.load_defaults_csv("|", "lib_mg_continental_data_points.txt")
	end

	if (t_points == nil) then
		t_points = lib_mg_continental.load_csv("|", "lib_mg_continental_data_points.txt")
	end

	if (t_points == nil) then

		minetest.log("[lib_mg_continental] Voronoi Cell Points file not found.  Using randomly generated points.")
		print("[lib_mg_continental] Voronoi Cell Points file not found.  Using randomly generated points.")

		if voronoi_type == "single" then
			lib_mg_continental.get_points(voronoi_cells, map_size)
		else
			--lib_mg_continental.get_points2(voronoi_recursion_1, voronoi_recursion_2, voronoi_recursion_3, map_size)
			lib_mg_continental.make_voronoi_recursive(voronoi_recursion_1, voronoi_recursion_2, voronoi_recursion_3, map_size, mg_distance_measurement)
		end

	else

		for i_p, p_point in ipairs(t_points) do
	
			local idx, p_z, p_x, p_mai, p_mad, p_mas, p_masz, p_masx, p_madx, p_madz, p_mac, p_mci, p_mcd, p_mcs, p_mcsz, p_mcsx, p_mcdx, p_mcdz, p_mcc, p_mei, p_med, p_mes, p_mesz, p_mesx, p_medx, p_medz, p_mec, p_mmi, p_mmd, p_mms, p_mmsz, p_mmsx, p_mmdx, p_mmdz, p_mmc, p_pai, p_pad, p_pas, p_pasz, p_pasx, p_padx, p_padz, p_pac, p_pci, p_pcd, p_pcs, p_pcsz, p_pcsx, p_pcdx, p_pcdz, p_pcc, p_pei, p_ped, p_pes, p_pesz, p_pesx, p_pedx, p_pedz, p_pec, p_pmi, p_pmd, p_pms, p_pmsz, p_pmsx, p_pmdx, p_pmdz, p_pmc, p_tier = unpack(p_point)

			lib_mg_continental.points[tonumber(idx)] = {}
			if voronoi_scaled then
	
				lib_mg_continental.points[tonumber(idx)].z = (tonumber(p_z) * t_scale)
				lib_mg_continental.points[tonumber(idx)].x = (tonumber(p_x) * t_scale)
--
				lib_mg_continental.points[tonumber(idx)].m_ai = tonumber(p_mai)
				lib_mg_continental.points[tonumber(idx)].m_ad = (tonumber(p_mad) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_as = (tonumber(p_mas) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_asz = (tonumber(p_masz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_asx = (tonumber(p_masx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_adx = (tonumber(p_madx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_adz = (tonumber(p_madz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_ac = tonumber(p_mac)
	
				lib_mg_continental.points[tonumber(idx)].m_ci = tonumber(p_mci)
				lib_mg_continental.points[tonumber(idx)].m_cd = (tonumber(p_mcd) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_cs = (tonumber(p_mcs) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_csz = (tonumber(p_mcsz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_csx = (tonumber(p_mcsx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_cdx = (tonumber(p_mcdx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_cdz = (tonumber(p_mcdz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_cc = tonumber(p_mcc)
	
				lib_mg_continental.points[tonumber(idx)].m_ei = tonumber(p_mei)
				lib_mg_continental.points[tonumber(idx)].m_ed = (tonumber(p_med) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_es = (tonumber(p_mes) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_esz = (tonumber(p_mesz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_esx = (tonumber(p_mesx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_edx = (tonumber(p_medx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_edz = (tonumber(p_medz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_ec = tonumber(p_mec)
	
				lib_mg_continental.points[tonumber(idx)].m_mi = tonumber(p_mmi)
				lib_mg_continental.points[tonumber(idx)].m_md = (tonumber(p_mmd) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_ms = (tonumber(p_mms) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_msz = (tonumber(p_mmsz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_msx = (tonumber(p_mmsx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_mdx = (tonumber(p_mmdx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_mdz = (tonumber(p_mmdz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].m_mc = tonumber(p_mmc)
	
				lib_mg_continental.points[tonumber(idx)].p_ai = tonumber(p_pai)
				lib_mg_continental.points[tonumber(idx)].p_ad = (tonumber(p_pad) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_as = (tonumber(p_pas) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_asz = (tonumber(p_pasz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_asx = (tonumber(p_pasx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_adx = (tonumber(p_padx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_adz = (tonumber(p_padz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_ac = tonumber(p_pac)
	
				lib_mg_continental.points[tonumber(idx)].p_ci = tonumber(p_pci)
				lib_mg_continental.points[tonumber(idx)].p_cd = (tonumber(p_pcd) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_cs = (tonumber(p_pcs) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_csz = (tonumber(p_pcsz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_csx = (tonumber(p_pcsx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_cdx = (tonumber(p_pcdx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_cdz = (tonumber(p_pcdz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_cc = tonumber(p_pcc)
	
				lib_mg_continental.points[tonumber(idx)].p_ei = tonumber(p_pei)
				lib_mg_continental.points[tonumber(idx)].p_ed = (tonumber(p_ped) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_es = (tonumber(p_pes) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_esz = (tonumber(p_pesz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_esx = (tonumber(p_pesx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_edx = (tonumber(p_pedx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_edz = (tonumber(p_pedz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_ec = tonumber(p_pec)
	
				lib_mg_continental.points[tonumber(idx)].p_mi = tonumber(p_pmi)
				lib_mg_continental.points[tonumber(idx)].p_md = (tonumber(p_pmd) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_ms = (tonumber(p_pms) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_msz = (tonumber(p_pmsz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_msx = (tonumber(p_pmsx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_mdx = (tonumber(p_pmdx) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_mdz = (tonumber(p_pmdz) * t_scale)
				lib_mg_continental.points[tonumber(idx)].p_mc = tonumber(p_pmc)
--
--[[
				lib_mg_continental.points[tonumber(idx)].m_ai = tonumber(p_mai)
				lib_mg_continental.points[tonumber(idx)].m_ad = tonumber(p_mad)
				lib_mg_continental.points[tonumber(idx)].m_as = tonumber(p_mas)
				lib_mg_continental.points[tonumber(idx)].m_asz = tonumber(p_masz)
				lib_mg_continental.points[tonumber(idx)].m_asx = tonumber(p_masx)
				lib_mg_continental.points[tonumber(idx)].m_adx = tonumber(p_madx)
				lib_mg_continental.points[tonumber(idx)].m_adz = tonumber(p_madz)
				lib_mg_continental.points[tonumber(idx)].m_ac = tonumber(p_mac)
	
				lib_mg_continental.points[tonumber(idx)].m_ci = tonumber(p_mci)
				lib_mg_continental.points[tonumber(idx)].m_cd = tonumber(p_mcd)
				lib_mg_continental.points[tonumber(idx)].m_cs = tonumber(p_mcs)
				lib_mg_continental.points[tonumber(idx)].m_csz = tonumber(p_mcsz)
				lib_mg_continental.points[tonumber(idx)].m_csx = tonumber(p_mcsx)
				lib_mg_continental.points[tonumber(idx)].m_cdx = tonumber(p_mcdx)
				lib_mg_continental.points[tonumber(idx)].m_cdz = tonumber(p_mcdz)
				lib_mg_continental.points[tonumber(idx)].m_cc = tonumber(p_mcc)
	
				lib_mg_continental.points[tonumber(idx)].m_ei = tonumber(p_mei)
				lib_mg_continental.points[tonumber(idx)].m_ed = tonumber(p_med)
				lib_mg_continental.points[tonumber(idx)].m_es = tonumber(p_mes)
				lib_mg_continental.points[tonumber(idx)].m_esz = tonumber(p_mesz)
				lib_mg_continental.points[tonumber(idx)].m_esx = tonumber(p_mesx)
				lib_mg_continental.points[tonumber(idx)].m_edx = tonumber(p_medx)
				lib_mg_continental.points[tonumber(idx)].m_edz = tonumber(p_medz)
				lib_mg_continental.points[tonumber(idx)].m_ec = tonumber(p_mec)
	
				lib_mg_continental.points[tonumber(idx)].m_mi = tonumber(p_mmi)
				lib_mg_continental.points[tonumber(idx)].m_md = tonumber(p_mmd)
				lib_mg_continental.points[tonumber(idx)].m_ms = tonumber(p_mms)
				lib_mg_continental.points[tonumber(idx)].m_msz = tonumber(p_mmsz)
				lib_mg_continental.points[tonumber(idx)].m_msx = tonumber(p_mmsx)
				lib_mg_continental.points[tonumber(idx)].m_mdx = tonumber(p_mmdx)
				lib_mg_continental.points[tonumber(idx)].m_mdz = tonumber(p_mmdz)
				lib_mg_continental.points[tonumber(idx)].m_mc = tonumber(p_mmc)
	
				lib_mg_continental.points[tonumber(idx)].p_ai = tonumber(p_pai)
				lib_mg_continental.points[tonumber(idx)].p_ad = tonumber(p_pad)
				lib_mg_continental.points[tonumber(idx)].p_as = tonumber(p_pas)
				lib_mg_continental.points[tonumber(idx)].p_asz = tonumber(p_pasz)
				lib_mg_continental.points[tonumber(idx)].p_asx = tonumber(p_pasx)
				lib_mg_continental.points[tonumber(idx)].p_adx = tonumber(p_padx)
				lib_mg_continental.points[tonumber(idx)].p_adz = tonumber(p_padz)
				lib_mg_continental.points[tonumber(idx)].p_ac = tonumber(p_pac)
	
				lib_mg_continental.points[tonumber(idx)].p_ci = tonumber(p_pci)
				lib_mg_continental.points[tonumber(idx)].p_cd = tonumber(p_pcd)
				lib_mg_continental.points[tonumber(idx)].p_cs = tonumber(p_pcs)
				lib_mg_continental.points[tonumber(idx)].p_csz = tonumber(p_pcsz)
				lib_mg_continental.points[tonumber(idx)].p_csx = tonumber(p_pcsx)
				lib_mg_continental.points[tonumber(idx)].p_cdx = tonumber(p_pcdx)
				lib_mg_continental.points[tonumber(idx)].p_cdz = tonumber(p_pcdz)
				lib_mg_continental.points[tonumber(idx)].p_cc = tonumber(p_pcc)
	
				lib_mg_continental.points[tonumber(idx)].p_ei = tonumber(p_pei)
				lib_mg_continental.points[tonumber(idx)].p_ed = tonumber(p_ped)
				lib_mg_continental.points[tonumber(idx)].p_es = tonumber(p_pes)
				lib_mg_continental.points[tonumber(idx)].p_esz = tonumber(p_pesz)
				lib_mg_continental.points[tonumber(idx)].p_esx = tonumber(p_pesx)
				lib_mg_continental.points[tonumber(idx)].p_edx = tonumber(p_pedx)
				lib_mg_continental.points[tonumber(idx)].p_edz = tonumber(p_pedz)
				lib_mg_continental.points[tonumber(idx)].p_ec = tonumber(p_pec)
	
				lib_mg_continental.points[tonumber(idx)].p_mi = tonumber(p_pmi)
				lib_mg_continental.points[tonumber(idx)].p_md = tonumber(p_pmd)
				lib_mg_continental.points[tonumber(idx)].p_ms = tonumber(p_pms)
				lib_mg_continental.points[tonumber(idx)].p_msz = tonumber(p_pmsz)
				lib_mg_continental.points[tonumber(idx)].p_msx = tonumber(p_pmsx)
				lib_mg_continental.points[tonumber(idx)].p_mdx = tonumber(p_pmdx)
				lib_mg_continental.points[tonumber(idx)].p_mdz = tonumber(p_pmdz)
				lib_mg_continental.points[tonumber(idx)].p_mc = tonumber(p_pmc)
--]]
				lib_mg_continental.points[tonumber(idx)].tier = tonumber(p_tier)
	
			else
	
				lib_mg_continental.points[tonumber(idx)].z = tonumber(p_z)
				lib_mg_continental.points[tonumber(idx)].x = tonumber(p_x)
	
				lib_mg_continental.points[tonumber(idx)].m_ai = tonumber(p_mai)
				lib_mg_continental.points[tonumber(idx)].m_ad = tonumber(p_mad)
				lib_mg_continental.points[tonumber(idx)].m_as = tonumber(p_mas)
				lib_mg_continental.points[tonumber(idx)].m_asz = tonumber(p_masz)
				lib_mg_continental.points[tonumber(idx)].m_asx = tonumber(p_masx)
				lib_mg_continental.points[tonumber(idx)].m_adx = tonumber(p_madx)
				lib_mg_continental.points[tonumber(idx)].m_adz = tonumber(p_madz)
				lib_mg_continental.points[tonumber(idx)].m_ac = tonumber(p_mac)
	
				lib_mg_continental.points[tonumber(idx)].m_ci = tonumber(p_mci)
				lib_mg_continental.points[tonumber(idx)].m_cd = tonumber(p_mcd)
				lib_mg_continental.points[tonumber(idx)].m_cs = tonumber(p_mcs)
				lib_mg_continental.points[tonumber(idx)].m_csz = tonumber(p_mcsz)
				lib_mg_continental.points[tonumber(idx)].m_csx = tonumber(p_mcsx)
				lib_mg_continental.points[tonumber(idx)].m_cdx = tonumber(p_mcdx)
				lib_mg_continental.points[tonumber(idx)].m_cdz = tonumber(p_mcdz)
				lib_mg_continental.points[tonumber(idx)].m_cc = tonumber(p_mcc)
	
				lib_mg_continental.points[tonumber(idx)].m_ei = tonumber(p_mei)
				lib_mg_continental.points[tonumber(idx)].m_ed = tonumber(p_med)
				lib_mg_continental.points[tonumber(idx)].m_es = tonumber(p_mes)
				lib_mg_continental.points[tonumber(idx)].m_esz = tonumber(p_mesz)
				lib_mg_continental.points[tonumber(idx)].m_esx = tonumber(p_mesx)
				lib_mg_continental.points[tonumber(idx)].m_edx = tonumber(p_medx)
				lib_mg_continental.points[tonumber(idx)].m_edz = tonumber(p_medz)
				lib_mg_continental.points[tonumber(idx)].m_ec = tonumber(p_mec)
	
				lib_mg_continental.points[tonumber(idx)].m_mi = tonumber(p_mmi)
				lib_mg_continental.points[tonumber(idx)].m_md = tonumber(p_mmd)
				lib_mg_continental.points[tonumber(idx)].m_ms = tonumber(p_mms)
				lib_mg_continental.points[tonumber(idx)].m_msz = tonumber(p_mmsz)
				lib_mg_continental.points[tonumber(idx)].m_msx = tonumber(p_mmsx)
				lib_mg_continental.points[tonumber(idx)].m_mdx = tonumber(p_mmdx)
				lib_mg_continental.points[tonumber(idx)].m_mdz = tonumber(p_mmdz)
				lib_mg_continental.points[tonumber(idx)].m_mc = tonumber(p_mmc)
	
				lib_mg_continental.points[tonumber(idx)].p_ai = tonumber(p_pai)
				lib_mg_continental.points[tonumber(idx)].p_ad = tonumber(p_pad)
				lib_mg_continental.points[tonumber(idx)].p_as = tonumber(p_pas)
				lib_mg_continental.points[tonumber(idx)].p_asz = tonumber(p_pasz)
				lib_mg_continental.points[tonumber(idx)].p_asx = tonumber(p_pasx)
				lib_mg_continental.points[tonumber(idx)].p_adx = tonumber(p_padx)
				lib_mg_continental.points[tonumber(idx)].p_adz = tonumber(p_padz)
				lib_mg_continental.points[tonumber(idx)].p_ac = tonumber(p_pac)
	
				lib_mg_continental.points[tonumber(idx)].p_ci = tonumber(p_pci)
				lib_mg_continental.points[tonumber(idx)].p_cd = tonumber(p_pcd)
				lib_mg_continental.points[tonumber(idx)].p_cs = tonumber(p_pcs)
				lib_mg_continental.points[tonumber(idx)].p_csz = tonumber(p_pcsz)
				lib_mg_continental.points[tonumber(idx)].p_csx = tonumber(p_pcsx)
				lib_mg_continental.points[tonumber(idx)].p_cdx = tonumber(p_pcdx)
				lib_mg_continental.points[tonumber(idx)].p_cdz = tonumber(p_pcdz)
				lib_mg_continental.points[tonumber(idx)].p_cc = tonumber(p_pcc)
	
				lib_mg_continental.points[tonumber(idx)].p_ei = tonumber(p_pei)
				lib_mg_continental.points[tonumber(idx)].p_ed = tonumber(p_ped)
				lib_mg_continental.points[tonumber(idx)].p_es = tonumber(p_pes)
				lib_mg_continental.points[tonumber(idx)].p_esz = tonumber(p_pesz)
				lib_mg_continental.points[tonumber(idx)].p_esx = tonumber(p_pesx)
				lib_mg_continental.points[tonumber(idx)].p_edx = tonumber(p_pedx)
				lib_mg_continental.points[tonumber(idx)].p_edz = tonumber(p_pedz)
				lib_mg_continental.points[tonumber(idx)].p_ec = tonumber(p_pec)
	
				lib_mg_continental.points[tonumber(idx)].p_mi = tonumber(p_pmi)
				lib_mg_continental.points[tonumber(idx)].p_md = tonumber(p_pmd)
				lib_mg_continental.points[tonumber(idx)].p_ms = tonumber(p_pms)
				lib_mg_continental.points[tonumber(idx)].p_msz = tonumber(p_pmsz)
				lib_mg_continental.points[tonumber(idx)].p_msx = tonumber(p_pmsx)
				lib_mg_continental.points[tonumber(idx)].p_mdx = tonumber(p_pmdx)
				lib_mg_continental.points[tonumber(idx)].p_mdz = tonumber(p_pmdz)
				lib_mg_continental.points[tonumber(idx)].p_mc = tonumber(p_pmc)
	
				lib_mg_continental.points[tonumber(idx)].tier = tonumber(p_tier)
	
			end

		end

		minetest.log("[lib_mg_continental] Voronoi Cell Points loaded from file.")

	end
end

function lib_mg_continental.load_points_lite()

	local t_points
	local t_scale = mg_scale_factor

	if voronoi_mod_defaults == true then
		t_points = lib_mg_continental.load_defaults_csv("|", "lib_mg_continental_data_points.txt")
	end

	if (t_points == nil) then
		t_points = lib_mg_continental.load_csv("|", "lib_mg_continental_data_points.txt")
	end

	if (t_points == nil) then

		minetest.log("[lib_mg_continental] Voronoi Cell Points file not found.  Using randomly generated points.")
		print("[lib_mg_continental] Voronoi Cell Points file not found.  Using randomly generated points.")

		if voronoi_type == "single" then
			lib_mg_continental.get_points(voronoi_cells, map_size)
		else
			--lib_mg_continental.get_points2(voronoi_recursion_1, voronoi_recursion_2, voronoi_recursion_3, map_size)
			lib_mg_continental.make_voronoi_recursive_lite(voronoi_recursion_1, voronoi_recursion_2, voronoi_recursion_3, map_size, mg_distance_measurement)
		end

	else

		for i_p, p_point in ipairs(t_points) do
	
			local idx, p_z, p_x, p_tier = unpack(p_point)

			lib_mg_continental.points[tonumber(idx)] = {}
			if voronoi_scaled then
	
				lib_mg_continental.points[tonumber(idx)].z = (tonumber(p_z) * t_scale)
				lib_mg_continental.points[tonumber(idx)].x = (tonumber(p_x) * t_scale)
--
				lib_mg_continental.points[tonumber(idx)].tier = tonumber(p_tier)
	
			else
	
				lib_mg_continental.points[tonumber(idx)].z = tonumber(p_z)
				lib_mg_continental.points[tonumber(idx)].x = tonumber(p_x)
	
				lib_mg_continental.points[tonumber(idx)].tier = tonumber(p_tier)
	
			end

		end

		minetest.log("[lib_mg_continental] Voronoi Cell Points loaded from file.")

	end
end

function lib_mg_continental.load_points_3d_lite()

	local t_points
	local t_scale = mg_scale_factor

	if voronoi_mod_defaults == true then
		t_points = lib_mg_continental.load_defaults_csv("|", "lib_mg_continental_data_points.txt")
	end

	if (t_points == nil) then
		t_points = lib_mg_continental.load_csv("|", "lib_mg_continental_data_points.txt")
	end

	if (t_points == nil) then

		minetest.log("[lib_mg_continental] Voronoi Cell Points file not found.  Using randomly generated points.")
		print("[lib_mg_continental] Voronoi Cell Points file not found.  Using randomly generated points.")

		if voronoi_type == "single" then
			lib_mg_continental.get_points(voronoi_cells, map_size)
		else
			--lib_mg_continental.get_points2(voronoi_recursion_1, voronoi_recursion_2, voronoi_recursion_3, map_size)
			lib_mg_continental.make_voronoi_recursive_3d_lite(voronoi_recursion_1, voronoi_recursion_2, voronoi_recursion_3, map_size, mg_distance_measurement)
		end

	else

		for i_p, p_point in ipairs(t_points) do
	
			local idx, p_z, p_y, p_x, p_tier = unpack(p_point)

			lib_mg_continental.points[tonumber(idx)] = {}
			if voronoi_scaled then
	
				lib_mg_continental.points[tonumber(idx)].z = (tonumber(p_z) * t_scale)
				lib_mg_continental.points[tonumber(idx)].y = (tonumber(p_y) * t_scale)
				lib_mg_continental.points[tonumber(idx)].x = (tonumber(p_x) * t_scale)
--
				lib_mg_continental.points[tonumber(idx)].tier = tonumber(p_tier)
	
			else
	
				lib_mg_continental.points[tonumber(idx)].z = tonumber(p_z)
				lib_mg_continental.points[tonumber(idx)].y = tonumber(p_y)
				lib_mg_continental.points[tonumber(idx)].x = tonumber(p_x)
	
				lib_mg_continental.points[tonumber(idx)].tier = tonumber(p_tier)
	
			end

		end

		minetest.log("[lib_mg_continental] Voronoi Cell Points loaded from file.")

	end
end

--[[
function lib_mg_continental.load_cells()

	local t_cells
	if voronoi_mod_defaults == true then
		t_cells = lib_mg_continental.load_defaults_csv("|", "lib_mg_continental_data_cells.txt")
	end

	if (t_cells == nil) then
		t_cells = lib_mg_continental.load_csv("|", "lib_mg_continental_data_cells.txt")
	end

	if (t_cells == nil) then

		minetest.log("[lib_mg_continental] Voronoi Cell Data file not found.  Generating data instead.")
		print("[lib_mg_continental] Voronoi Cell Data file not found.  Generating data instead.")
		minetest.log("This is processing intensive, and may take a while, but only needs to run once to generate the data.  Please be patient.")
		print("This is processing intensive, and may take a while, but only needs to run once to generate the data.  Please be patient.")

		lib_mg_continental.get_cell_data()

	else

		for i_c, c_point in pairs(t_cells) do
	
			--local idx, c_idx, l_idx, c_posz, c_posx, c_parent, c_tier, n_idx, n_posz, n_posx, n_parent, n_tier, cn_dist, n_dir, cn_compass, cn_slope, cn_run, cn_rise, cm_dist, nm_dist, m_posz, m_posx, edge_slope, edge_run, edge_rise = unpack(c_point)
			local idx, c_idx, l_idx, c_posz, c_posx, n_idx, n_posz, n_posx, cn_dist, n_dir, cn_compass, cn_slope, cn_run, cn_rise, cm_dist, nm_dist, m_posz, m_posx, edge_slope, edge_run, edge_rise = unpack(c_point)
	
			lib_mg_continental.cells[idx] = {}
			lib_mg_continental.cells[idx].c_i = tonumber(c_idx)
			lib_mg_continental.cells[idx].l_i = tonumber(l_idx)
			if voronoi_scaled then

				lib_mg_continental.cells[idx].c_z = (tonumber(c_posz) * 0.1)
				lib_mg_continental.cells[idx].c_x = (tonumber(c_posx) * 0.1)
				lib_mg_continental.cells[idx].n_i = tonumber(n_idx)
				lib_mg_continental.cells[idx].n_z = (tonumber(n_posz) * 0.1)
				lib_mg_continental.cells[idx].n_x = (tonumber(n_posx) * 0.1)
				lib_mg_continental.cells[idx].cn_d = (tonumber(cn_dist) * 0.1)
				lib_mg_continental.cells[idx].cn_s = (tonumber(cn_slope) * 0.1)
				lib_mg_continental.cells[idx].cn_sx = (tonumber(cn_run) * 0.1)
				lib_mg_continental.cells[idx].cn_sz = (tonumber(cn_rise) * 0.1)
				lib_mg_continental.cells[idx].cm_d = (tonumber(cm_dist) * 0.1)
				lib_mg_continental.cells[idx].nm_d = (tonumber(nm_dist) * 0.1)
				lib_mg_continental.cells[idx].m_z = (tonumber(m_posz) * 0.1)
				lib_mg_continental.cells[idx].m_x = (tonumber(m_posx) * 0.1)
				lib_mg_continental.cells[idx].e_s = (tonumber(edge_slope) * 0.1)
				lib_mg_continental.cells[idx].e_sx = (tonumber(edge_run) * 0.1)
				lib_mg_continental.cells[idx].e_sz = (tonumber(edge_rise) * 0.1)

			else

				lib_mg_continental.cells[idx].c_z = tonumber(c_posz)
				lib_mg_continental.cells[idx].c_x = tonumber(c_posx)
				lib_mg_continental.cells[idx].n_i = tonumber(n_idx)
				lib_mg_continental.cells[idx].n_z = tonumber(n_posz)
				lib_mg_continental.cells[idx].n_x = tonumber(n_posx)
				lib_mg_continental.cells[idx].cn_d = tonumber(cn_dist)
				lib_mg_continental.cells[idx].cn_s = tonumber(cn_slope)
				lib_mg_continental.cells[idx].cn_sx = tonumber(cn_run)
				lib_mg_continental.cells[idx].cn_sz = tonumber(cn_rise)
				lib_mg_continental.cells[idx].cm_d = tonumber(cm_dist)
				lib_mg_continental.cells[idx].nm_d = tonumber(nm_dist)
				lib_mg_continental.cells[idx].m_z = tonumber(m_posz)
				lib_mg_continental.cells[idx].m_x = tonumber(m_posx)
				lib_mg_continental.cells[idx].e_s = tonumber(edge_slope)
				lib_mg_continental.cells[idx].e_sx = tonumber(edge_run)
				lib_mg_continental.cells[idx].e_sz = tonumber(edge_rise)

			end
			--lib_mg_continental.cells[idx].c_p =  c_parent
			--lib_mg_continental.cells[idx].c_t =  c_tier
			--lib_mg_continental.cells[idx].n_p =  n_parent
			--lib_mg_continental.cells[idx].n_t =  n_tier
			lib_mg_continental.cells[idx].n_d = n_dir
			lib_mg_continental.cells[idx].cn_c = cn_compass
		end
		minetest.log("[lib_mg_continental] Voronoi Cell Data loaded from file.")

	end
end
function lib_mg_continental.load_vertices()

	local t_vertices
	if voronoi_mod_defaults == true then
		t_vertices = lib_mg_continental.load_defaults_csv("|", "lib_mg_continental_data_vertices.txt")
	end

	if (t_vertices == nil) then
		t_vertices = lib_mg_continental.load_csv("|", "lib_mg_continental_data_vertices.txt")
	end

	if (t_vertices == nil) then

		minetest.log("[lib_mg_continental] Voronoi Vertex Data file not found.  Generating data instead.")
		print("[lib_mg_continental] Voronoi Vertex Data file not found.  Generating data instead.")
		minetest.log("This is processing intensive, and may take a while, but only needs to run once to generate the data.  Please be patient.")
		print("This is processing intensive, and may take a while, but only needs to run once to generate the data.  Please be patient.")

		lib_mg_continental.get_vertices_data()

	else

		for i_v, t_vertex in pairs(t_vertices) do
			--#Idx|C_I|C_Pos|N1_I|N1_Pos|N2_I|N2_Pos|V_Pos
			--#v_i|c_i|c_x|c_z|n1_i|n1_x|n1_z|n2_i|n2_x|n2_z|v_x|v_z
			local v_idx, c_idx, c_posx, c_posz, n1_idx, n1_posx, n1_posz, n2_idx, n2_posx, n2_posz, v_posx, v_posz, cv_slope, cv_run, cv_rise = unpack(t_vertex)
			--local v_idx, c_idx, c_posx, c_posz, n1_idx, n1_posx, n1_posz, n2_idx, n2_posx, n2_posz, v_posx, v_posz, v_dir, v_compass, cv_slope, cv_run, cv_rise = unpack(t_vertex)
			--local v_idx, c_idx, n1_idx, n2_idx, v_posx, v_posz, cv_slope, cv_run, cv_rise = unpack(t_vertex)
	
			lib_mg_continental.vertices[v_idx] = {}
			lib_mg_continental.vertices[v_idx].c_i = tonumber(c_idx)
			if voronoi_scaled then

				lib_mg_continental.vertices[v_idx].c_z = (tonumber(c_posz) * 0.1)
				lib_mg_continental.vertices[v_idx].c_x = (tonumber(c_posx) * 0.1)
				lib_mg_continental.vertices[v_idx].n1_i = tonumber(n1_idx)
				lib_mg_continental.vertices[v_idx].n1_x = (tonumber(n1_posx) * 0.1)
				lib_mg_continental.vertices[v_idx].n1_z = (tonumber(n1_posz) * 0.1)
				lib_mg_continental.vertices[v_idx].n2_i = tonumber(n2_idx)
				lib_mg_continental.vertices[v_idx].n2_x = (tonumber(n2_posx) * 0.1)
				lib_mg_continental.vertices[v_idx].n2_z = (tonumber(n2_posz) * 0.1)
				lib_mg_continental.vertices[v_idx].v_x = (tonumber(v_posx) * 0.1)
				lib_mg_continental.vertices[v_idx].v_z = (tonumber(v_posz) * 0.1)
				lib_mg_continental.vertices[v_idx].cv_s = (tonumber(cv_slope) * 0.1)
				lib_mg_continental.vertices[v_idx].cv_sx = (tonumber(cv_run) * 0.1)
				lib_mg_continental.vertices[v_idx].cv_sz = (tonumber(cv_rise) * 0.1)

			else

				lib_mg_continental.vertices[v_idx].c_z = tonumber(c_posz)
				lib_mg_continental.vertices[v_idx].c_x = tonumber(c_posx)
				lib_mg_continental.vertices[v_idx].n1_i = tonumber(n1_idx)
				lib_mg_continental.vertices[v_idx].n1_x = tonumber(n1_posx)
				lib_mg_continental.vertices[v_idx].n1_z = tonumber(n1_posz)
				lib_mg_continental.vertices[v_idx].n2_i = tonumber(n2_idx)
				lib_mg_continental.vertices[v_idx].n2_x = tonumber(n2_posx)
				lib_mg_continental.vertices[v_idx].n2_z = tonumber(n2_posz)
				lib_mg_continental.vertices[v_idx].v_x = tonumber(v_posx)
				lib_mg_continental.vertices[v_idx].v_z = tonumber(v_posz)
				lib_mg_continental.vertices[v_idx].cv_s = tonumber(cv_slope)
				lib_mg_continental.vertices[v_idx].cv_sx = tonumber(cv_run)
				lib_mg_continental.vertices[v_idx].cv_sz = tonumber(cv_rise)

			end
			--lib_mg_continental.vertices[v_idx].v_d = v_dir
			--lib_mg_continental.vertices[v_idx].v_c = v_compass
		end
		minetest.log("[lib_mg_continental] Voronoi Vertex Data loaded from file.")

	end
end
--]]

minetest.log("[lib_mg_continental ] Voronoi Data Processing ...")
lib_mg_continental.load_points_lite()
--lib_mg_continental.load_points_3d_lite()
--lib_mg_continental.load_cells()
--lib_mg_continental.load_vertices()
lib_mg_continental.edgemap = {}
minetest.log("[lib_mg_continental] Voronoi Data Processing Completed.")
minetest.log("[lib_mg_continental] Base Max:" .. base_max)
print("[lib_mg_continental] Base Max:" .. base_max)
minetest.log("[lib_mg_continental] Base Min:" .. base_min)
print("[lib_mg_continental] Base Min:" .. base_min)


local mapgen_times = {
	liquid_lighting = {},
	loops = {},
	make_chunk = {},
	noisemaps = {},
	preparation = {},
	writing = {},
}

local data = {}


minetest.register_on_generated(function(minp, maxp, seed)
	
	-- Start time of mapchunk generation.
	local t0 = os.clock()
	
	--ShadMOrdre
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	--
	
	local sidelen = maxp.x - minp.x + 1
	local permapdims3d = {x = sidelen, y = sidelen, z = 0}

	--ShadMOrdre
	local overlen = sidelen + 5
	local chulens = {x = overlen, y = overlen, z = 1}
	local minpos  = {x = x0 - 3, y = z0 - 3}
	--

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	data = vm:get_data()
	local a = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local csize = vector.add(vector.subtract(maxp, minp), 1)
--
	----base terrain
	nobj_terrain = nobj_terrain or minetest.get_perlin_map(np_terrain, csize)
	isln_terrain=nobj_terrain:get_2d_map({x=minp.x,y=minp.z})

	---- base variation
	nobj_var = nobj_var or minetest.get_perlin_map(np_var, csize)		
	isln_var = nobj_var:get_2d_map({x=minp.x,y=minp.z})
	
	-- hills
	nobj_hills = nobj_hills or minetest.get_perlin_map(np_hills, permapdims3d)
	isln_hills = nobj_hills:get_2d_map({x=minp.x,y=minp.z})
	
	---- cliffs
	nobj_cliffs = nobj_cliffs or minetest.get_perlin_map(np_cliffs, permapdims3d)
	isln_cliffs = nobj_cliffs:get_2d_map({x=minp.x,y=minp.z})


	nobj_heatmap = nobj_heatmap or minetest.get_perlin_map(np_heat, chulens)
	nbase_heatmap = nobj_heatmap:get2dMap_flat({x=minp.x, y=minp.z})
	nobj_heatblend = nobj_heatblend or minetest.get_perlin_map(np_heat_blend, chulens)
	nbase_heatblend = nobj_heatblend:get2dMap_flat({x=minp.x, y=minp.z})
	nobj_humiditymap = nobj_humiditymap or minetest.get_perlin_map(np_humid, chulens)
	nbase_humiditymap = nobj_humiditymap:get2dMap_flat({x=minp.x, y=minp.z})
	nobj_humidityblend = nobj_humidityblend or minetest.get_perlin_map(np_humid_blend, chulens)
	nbase_humidityblend = nobj_humidityblend:get2dMap_flat({x=minp.x, y=minp.z})


	-- Mapgen preparation is now finished. Check the timer to know the elapsed time.
	local t1 = os.clock()

	local write = false
	
	local center_of_chunk = { 
		x = maxp.x - lib_mg_continental.half_map_chunk_size, 
		y = maxp.y - lib_mg_continental.half_map_chunk_size, 
		z = maxp.z - lib_mg_continental.half_map_chunk_size
	} 


--2D HEIGHTMAP GENERATION
	local index2d = 0

	local t_point = lib_mg_continental.points

	local dm = mg_distance_measurement
--
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do

			index2d = (z - minp.z) * csize.x + (x - minp.x) + 1

			local theight
			local vheight
			local tedge = ""

				--local c_idx, c_dist, p_idx, p_dist, m_idx, m_dist, c_edge = lib_mg_continental.get_nearest_cell_data({x = x, z = z}, dm, 3)

				--local c_idx, c_dist, c_slope, c_rise, c_run, c_dir_x, c_dir_z, c_compass, p_idx, p_dist, p_slope, p_rise, p_run, p_dir_x, p_dir_z, p_compass, m_idx, m_dist, m_slope, m_rise, m_run, m_dir_x, m_dir_z, m_compass, c_edge = lib_mg_continental.get_nearest_cell_data({x = x, z = z}, dm, 3)

				--local c_idx, c_adist, c_cdist, c_edist, c_mdist, c_slope, c_rise, c_run, c_dir_x, c_dir_z, c_compass, c_edge = lib_mg_continental.get_closest_cell({x = x, z = z}, dm, 3)
				--local p_idx, p_adist, p_cdist, p_edist, p_mdist, p_slope, p_rise, p_run, p_dir_x, p_dir_z, p_compass, p_edge = lib_mg_continental.get_closest_cell({x = x, z = z}, dm, 2)
				--local m_idx, m_adist, m_cdist, m_edist, m_mdist, m_slope, m_rise, m_run, m_dir_x, m_dir_z, m_compass, m_edge = lib_mg_continental.get_closest_cell({x = x, z = z}, dm, 1)

				--local c_idx, c_dist, c_slope, c_rise, c_run, c_dir_x, c_dir_z, c_compass, c_edge = lib_mg_continental.get_nearest_cell({x = x, z = z}, dm, 3)
				--local p_idx, p_dist, p_slope, p_rise, p_run, p_dir_x, p_dir_z, p_compass, p_edge = lib_mg_continental.get_nearest_cell({x = x, z = z}, dm, 2)
				--local m_idx, m_dist, m_slope, m_rise, m_run, m_dir_x, m_dir_z, m_compass, m_edge = lib_mg_continental.get_nearest_cell({x = x, z = z}, dm, 1)

				--local c_cidx, c_cdist, c_cdir_x, c_cdir_z, c_ccompass, c_cedge = lib_mg_continental.get_nearest_cell({x = x, z = z}, "c", 3)
				--local c_midx, c_mdist, c_mdir_x, c_mdir_z, c_mcompass, c_medge = lib_mg_continental.get_nearest_cell({x = x, z = z}, "m", 3)

				--local c_idx, c_dist, c_dir_x, c_dir_z, c_compass, c_edge = lib_mg_continental.get_nearest_cell({x = x, z = z}, dm, 3)
				--local p_idx, p_dist, p_dir_x, p_dir_z, p_compass, p_edge = lib_mg_continental.get_nearest_cell({x = x, z = z}, dm, 2)
				--local m_idx, m_dist, m_dir_x, m_dir_z, m_compass, m_edge = lib_mg_continental.get_nearest_cell({x = x, z = z}, dm, 1)

				--local c_idx, c_dist, c_edge = lib_mg_continental.get_nearest_cell_3d_alt({x = x, y = y, z = z}, dm, 3)
				--local p_idx, p_dist, p_edge = lib_mg_continental.get_nearest_cell_3d_alt({x = x, y = y, z = z}, dm, 2)
				--local m_idx, m_dist, m_edge = lib_mg_continental.get_nearest_cell_3d_alt({x = x, y = y, z = z}, dm, 1)

			local c_idx, c_dist, c_edge = lib_mg_continental.get_nearest_cell_alt({x = x, z = z}, dm, 3)
			local p_idx, p_dist, p_edge = lib_mg_continental.get_nearest_cell_alt({x = x, z = z}, dm, 2)
			local m_idx, m_dist, m_edge = lib_mg_continental.get_nearest_cell_alt({x = x, z = z}, dm, 1)

				--local p_idx = t_point[c_idx].p_i
				--local m_idx = t_point[c_idx].m_i

				--local p_dist = lib_mg_continental.get_distance_combo({x = x, z = z}, {x = t_point[p_idx].x, z = t_point[p_idx].z})
				--local m_dist = lib_mg_continental.get_distance_combo({x = x, z = z}, {x = t_point[m_idx].x, z = t_point[m_idx].z})

				--local t_p = t_point[t_point[c_idx].p_i]
				--local t_m = t_point[t_point[c_idx].m_i]

				--local p_dist = lib_mg_continental.get_distance_combo({x = x, z = z}, {x = t_p.x, z = t_p.z}, dm)
				--local m_dist = lib_mg_continental.get_distance_combo({x = x, z = z}, {x = t_m.x, z = t_m.z}, dm)

				--local c_dist = (c_cdist + c_mdist) * 0.5
				--local p_dist = (p_cdist + p_mdist) * 0.5
				--local m_dist = (m_cdist + m_mdist) * 0.5

			if (c_edge ~= "") or (p_edge ~= "") or (m_edge ~= "") then
				tedge = c_edge
					--if (c_edge ~= "") then
					--	tedge = c_edge
					--elseif (p_edge ~= "") then
					--	tedge = p_edge
					--elseif (m_edge ~= "") then
					--	tedge = m_edge
					--else
					--	tedge = ""
					--end
			else
				tedge = ""
			end

				--local c_mid_x, c_mid_z = lib_mg_continental.get_midpoint({x = k_point.x, z = k_point.z}, {x = i_point.x, z = i_point.z})
				--local nc_slope, nc_rise, nc_run = lib_mg_continental.get_slope({x = k_point.x, z = k_point.z}, {x = i_point.x, z = i_point.z})
				--local nc_dir, nc_compass = lib_mg_continental.get_direction_to_pos({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				--local ce_slope, ce_run, ce_rise = lib_mg_continental.get_slope_inverse({x = k_point.x, z = k_point.z}, {x = i_point.x, z = i_point.z})

				--local n2c_dir = {x = c_dir_x, z = c_dir_z}
				--local n2p_dir = {x = p_dir_x, z = p_dir_z}
				--local n2m_dir = {x = m_dir_x, z = m_dir_z}
				--local c2p_dir = {x = t_point[c_idx].p_cdx, z = t_point[c_idx].p_cdz}
				--local c2m_dir = {x = t_point[c_idx].m_cdx, z = t_point[c_idx].m_cdz}
				--local p2m_dir = {x = t_point[p_idx].m_cdx, z = t_point[p_idx].m_cdz}

				--local n2c_dist = c_dist
			local n2p_dist = p_dist
				--local n2m_dist = m_dist
			local c2p_dist = lib_mg_continental.get_distance_combo({x = t_point[c_idx].x, z = t_point[c_idx].z}, {x = t_point[p_idx].x, z = t_point[p_idx].z}, dm)
			local c2m_dist = lib_mg_continental.get_distance_combo({x = t_point[c_idx].x, z = t_point[c_idx].z}, {x = t_point[m_idx].x, z = t_point[m_idx].z}, dm)
			local p2m_dist = lib_mg_continental.get_distance_combo({x = t_point[p_idx].x, z = t_point[p_idx].z}, {x = t_point[m_idx].x, z = t_point[m_idx].z}, dm)

			local mcontinental = (m_dist * v_cscale)
			local pcontinental = (p_dist * v_pscale)
			local ccontinental = (c_dist * v_mscale)

			--local mcontinental = (base_max)
			--local pcontinental = (p2m_dist * v_pscale)
			--local ccontinental = (c2m_dist * v_cscale)

				--mcontinental = lib_mg_continental.get_terrain_height_shelf(m_dist) * v_mscale
				--pcontinental = mcontinental + lib_mg_continental.get_terrain_height_shelf(p_dist) * v_mscale
				--ccontinental = pcontinental + lib_mg_continental.get_terrain_height_shelf(c_dist * 0.5) * v_cscale

				--local pcontinental = mcontinental + (p_dist) * v_mscale
			if (c2m_dist >= p2m_dist) then
				if (n2p_dist >= c2p_dist) then
					vheight = lib_mg_continental.get_terrain_height_shelf(mcontinental + pcontinental + ccontinental)
				else
					vheight = lib_mg_continental.get_terrain_height_shelf(mcontinental + pcontinental)
				end
			else
				vheight = lib_mg_continental.get_terrain_height_shelf(mcontinental)
			end

			--if (m_dist >= p_dist) then
			--	if (p_dist >= c_dist) then
			--		vheight = lib_mg_continental.get_terrain_height_shelf(mcontinental - pcontinental - ccontinental)
			--	else
			--		vheight = lib_mg_continental.get_terrain_height_shelf(mcontinental - pcontinental)
			--	end
			--else
			--	vheight = lib_mg_continental.get_terrain_height_shelf(mcontinental)
			--end


			--vheight = lib_mg_continental.get_terrain_height_shelf(mcontinental + pcontinental - ccontinental)
				--vheight = lib_mg_continental.get_terrain_height_shelf(ccontinental)
				--vheight = lib_mg_continental.get_terrain_height_shelf((m_dist * v_mscale) - (p_dist * v_pscale) - (c_dist * v_cscale))
				----vheight = lib_mg_continental.get_terrain_height_shelf((m_dist - p_dist - (c_dist * 0.5)) * v_mscale)
					--vheight = lib_mg_continental.get_terrain_height_shelf((m_dist - p_dist - ((c_dist * 0.5) * v_cscale)) * v_mscale)
					--manhattan --vheight = lib_mg_continental.get_terrain_height_shelf(((m_dist + p_dist) * v_mscale) + ((c_dist * 0.5) * v_cscale))


			--local nterrain = isln_terrain[z-minp.z+1][x-minp.x+1]
			local nterrain = isln_terrain[z-minp.z+1][x-minp.x+1] + (convex and isln_var[z-minp.z+1][x-minp.x+1] or 0)
			local hterrain = isln_hills[z-minp.z+1][x-minp.x+1]
			local cterrain = isln_cliffs[z-minp.z+1][x-minp.x+1]

			local vterrain = lib_mg_continental.get_terrain_height_shelf(vheight)
			--local vterrain


			--if voronoi_scaled == true then
			--	vterrain = lib_mg_continental.get_terrain_height_shelf(vheight)
			--	--vterrain = ((base_min * 0.5) * mult) + ((base_max * mult) - lib_mg_continental.get_terrain_height_shelf(vheight))
			--	theight = lib_mg_continental.get_terrain_height(nterrain,hterrain,cterrain) - vterrain
			--else
			--	vterrain = lib_mg_continental.get_terrain_height_shelf(vheight)
			--	theight = lib_mg_continental.get_terrain_height(nterrain,hterrain,cterrain) - vterrain
			--end


				--theight = vterrain
			--theight = base_max - vterrain
			theight = (lib_mg_continental.get_terrain_height(nterrain,hterrain,cterrain) + base_rng) - vterrain
			--theight = (lib_mg_continental.get_terrain_height(nterrain,hterrain,cterrain) + (base_max + (base_max * 0.5))) - vterrain
			--theight = (lib_mg_continental.get_terrain_height(nterrain,hterrain,cterrain) + base_max) - vterrain
			--theight = (lib_mg_continental.get_terrain_height(nterrain,hterrain,cterrain) - vterrain) + base_rng
				--theight = lib_mg_continental.get_terrain_height((nterrain + vterrain),hterrain,cterrain) - vterrain
				--theight = (lib_mg_continental.get_terrain_height(nterrain,hterrain,cterrain) + lib_mg_continental.get_terrain_height(vterrain,hterrain,cterrain)) - vterrain

				--theight = lib_mg_continental.get_terrain_height(nterrain,hterrain,cterrain) - vterrain
				--theight = lib_mg_continental.get_terrain_height_hills_adjustable_shelf(nterrain,vterrain,cterrain,(((c_dist * 0.5) * v_cscale) * mg_golden_ratio))
		
				--theight = (lib_mg_continental.get_terrain_height(nterrain,hterrain,cterrain) + lib_mg_continental.get_terrain_height(vterrain,hterrain,cterrain)) * 0.5

				--theight = lib_mg_continental.get_terrain_height(ccontinental,hterrain,cterrain)
				--theight = lib_mg_continental.get_terrain_height_cliffs_hills(nterrain,vterrain,cterrain)
				--theight = lib_mg_continental.get_terrain_height_cliffs_hills((nterrain + vterrain),hterrain,cterrain)

			lib_mg_continental.heightmap[index2d] = theight
			lib_mg_continental.edgemap[index2d] = tedge

		end
	end
--
--2D HEIGHTMAP RENDER
	local index2d = 0
	for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			for x = minp.x, maxp.x do
			 
				index2d = (z - minp.z) * csize.x + (x - minp.x) + 1   
				local ivm = a:index(x, y, z)
--[[
				local theight
				local vheight
				local tedge = ""
				local c_idx, c_dist, c_edge = lib_mg_continental.get_nearest_cell_3d_alt({x = x, y = y, z = z}, dm, 3)
				local p_idx, p_dist, p_edge = lib_mg_continental.get_nearest_cell_3d_alt({x = x, y = y, z = z}, dm, 2)
				local m_idx, m_dist, m_edge = lib_mg_continental.get_nearest_cell_3d_alt({x = x, y = y, z = z}, dm, 1)
				if (c_edge ~= "") then
					tedge = c_edge
				else
					tedge = ""
				end
				--vheight = lib_mg_continental.get_terrain_height_shelf(((m_dist - p_dist) * v_mscale) - ((c_dist * 0.5) * v_cscale))
				vheight = lib_mg_continental.get_terrain_height_shelf((c_dist * 0.5) * v_cscale)
				vheight = c_dist * v_cscale
				local vterrain
				if voronoi_scaled == true then
					vterrain = (base_min * 0.5) + ((base_max) - lib_mg_continental.get_terrain_height_shelf(vheight))
				else
					vterrain = (base_min * 2) + ((base_max * 4) - lib_mg_continental.get_terrain_height_shelf(vheight))
				end
				theight = vterrain
				lib_mg_continental.heightmap[index2d] = theight
				lib_mg_continental.edgemap[index2d] = tedge
--]]
				local theight = lib_mg_continental.heightmap[index2d]
				local tedge = lib_mg_continental.edgemap[index2d]

				local fill_depth = 4
				local top_depth = 1

--BUILD BIOMES.
--
				if y <= theight + 1 then
					local t_heat, t_humid, t_altitude, t_name
	
					local nheat = nbase_heatmap[index2d] + nbase_heatblend[index2d]
					local nhumid = nbase_humiditymap[index2d] + nbase_humidityblend[index2d]
	
					if nheat < 12.5 then
						t_heat = "cold"
					elseif nheat >= 12.5 and nheat < 37.5 then
						t_heat = "cool"
					elseif nheat >= 37.5 and nheat < 62.5 then
						t_heat = "temperate"
					elseif nheat >= 62.5 and nheat < 87.5 then
						t_heat = "warm"
					elseif nheat >= 87.5 then
						t_heat = "hot"
					else
						--t_heat = ""
					end
			
					if nhumid < 12.5 then
						t_humid = "arid"
					elseif nhumid >= 12.5 and nhumid < 37.5 then
						t_humid = "semiarid"
					elseif nhumid >= 37.5 and nhumid < 62.5 then
						t_humid = "temperate"
					elseif nhumid >= 62.5 and nhumid < 87.5 then
						t_humid = "semihumid"
					elseif nhumid >= 87.5 then
						t_humid = "humid"
					else
						--t_humid = ""
					end
--[[
					if y >= (lib_materials.ocean_depth * (2 * mult)) and y < (lib_materials.beach_depth * (2 * mult)) then
						t_altitude = "ocean"
					elseif y >= (lib_materials.beach_depth * (2 * mult)) and y < (lib_materials.maxheight_beach * (2 * mult)) then
						t_altitude = "beach"
					elseif y >= (lib_materials.maxheight_beach * (2 * mult)) and y < (lib_materials.maxheight_coastal * (2 * mult)) then
						t_altitude = "coastal"
					elseif y >= (lib_materials.maxheight_coastal * (2 * mult)) and y < (lib_materials.maxheight_lowland * (2 * mult)) then
						t_altitude = "lowland"
					elseif y >= (lib_materials.maxheight_lowland * (2 * mult)) and y < (lib_materials.maxheight_shelf * (2 * mult)) then
						t_altitude = "shelf"
					elseif y >= (lib_materials.maxheight_shelf * (2 * mult)) and y < (lib_materials.maxheight_highland * (2 * mult)) then
						t_altitude = "highland"
					elseif y >= (lib_materials.maxheight_highland * (2 * mult)) and y < (lib_materials.maxheight_mountain * (2 * mult)) then
						t_altitude = "mountain"
					elseif y >= (lib_materials.maxheight_mountain * (2 * mult)) and y < (lib_materials.maxheight_strato * (2 * mult)) then
						t_altitude = "strato"
					else
						--t_altitude = ""
					end
--]]
					if y >= (lib_materials.ocean_depth * mult) and y < (lib_materials.beach_depth * mult) then
						t_altitude = "ocean"
					elseif y >= (lib_materials.beach_depth * mult) and y < (lib_materials.maxheight_beach * mult) then
						t_altitude = "beach"
					elseif y >= (lib_materials.maxheight_beach * mult) and y < (lib_materials.maxheight_coastal * mult) then
						t_altitude = "coastal"
					elseif y >= (lib_materials.maxheight_coastal * mult) and y < (lib_materials.maxheight_lowland * mult) then
						t_altitude = "lowland"
					elseif y >= (lib_materials.maxheight_lowland * mult) and y < (lib_materials.maxheight_shelf * mult) then
						t_altitude = "shelf"
					elseif y >= (lib_materials.maxheight_shelf * mult) and y < (lib_materials.maxheight_highland * mult) then
						t_altitude = "highland"
					elseif y >= (lib_materials.maxheight_highland * mult) and y < (lib_materials.maxheight_mountain * mult) then
						t_altitude = "mountain"
					elseif y >= (lib_materials.maxheight_mountain * mult) and y < (lib_materials.maxheight_strato * mult) then
						t_altitude = "strato"
					else
						--t_altitude = ""
					end
	
					if t_heat and t_heat ~= "" and t_humid and t_humid ~= ""  and t_altitude and t_altitude ~= "" then
						t_name = t_heat .. "_" .. t_humid .. "_" .. t_altitude
					end
	
					if y >= -31000 and y < -20000 then
						t_name = "generic_mantle"
					elseif y >= -20000 and y < -15000 then
						t_name = "stone_basalt_01_layer"
					elseif y >= -15000 and y < -10000 then
						t_name = "stone_brown_layer"
					elseif y >= -10000 and y < -6000 then
						t_name = "stone_sand_layer"
					elseif y >= -6000 and y < -5000 then
						t_name = "desert_stone_layer"
					elseif y >= -5000 and y < -4000 then
						t_name = "desert_sandstone_layer"
					elseif y >= -4000 and y < -3000 then
						t_name = "generic_stone_limestone_01_layer"
					elseif y >= -3000 and y < -2000 then
						t_name = "generic_granite_layer"
					elseif y >= -2000 and y < lib_materials.ocean_depth then
						t_name = "generic_stone_layer"
					else
						
					end
	
					local b_name, b_cid, b_top, b_top_d, b_fill, b_fill_d, b_stone, b_water_top, b_water_top_d, b_water, b_river, b_riverbed, b_riverbed_d
					local b_caveliquid, b_dungeon, b_dungeonalt, b_dungeonstair, b_dust, b_ymin, b_ymax, b_heat, b_humid
			
					if t_name == "" then
						t_name = minetest.get_biome_name(minetest.get_biome_data({x,y,z}).biome)
					end
	
					if t_name and t_name ~= "" then
	
						b_name, b_cid, b_top, b_top_d, b_fill, b_fill_d, b_stone, b_water_top, b_water_top_d, b_water, b_river, b_riverbed, b_riverbed_d, b_caveliquid, b_dungeon, b_dungeonalt, b_dungeonstair, b_dust, b_ymin, b_ymax, b_heat, b_humid = unpack(lib_mg_continental.biome_info[t_name]:split("|", false))
	
						c_stone = b_stone
						c_dirt = b_fill
						fill_depth = tonumber(b_fill_d) or 6
						c_top = b_top
						top_depth = tonumber(b_top_d) or 1
	
					end
	
					lib_mg_continental.biomemap[index2d] = b_cid
				end
--

--NODE PLACEMENT FROM HEIGHTMAP

				if tedge  ~= "" then
					c_dirt = c_stone
				end
	
				if y < (theight - (fill_depth + top_depth)) then
					data[ivm] = c_stone
					write = true
				elseif y >= (theight - (fill_depth + top_depth)) and y < (theight - top_depth) then
					data[ivm] = c_dirt
					write = true
				elseif y >= (theight - top_depth) and y <= theight then
					data[ivm] = c_top
					write = true
				elseif y > theight and y <= 1 then
					data[ivm] = c_water
					write = true
				else
					data[ivm] = c_air
					write = true
				end


			end
		end
	end
	
	local t2 = os.clock()

	if write then
		vm:set_data(data)
	end

	local t3 = os.clock()
	
	if write then

		minetest.generate_ores(vm,minp,maxp)
		minetest.generate_decorations(vm,minp,maxp)
			
		vm:set_lighting({day = 0, night = 0})
		vm:calc_lighting()
		vm:update_liquids()
	end

	local t4 = os.clock()

	if write then
		vm:write_to_map()
	end

	local t5 = os.clock()

	-- Print generation time of this mapchunk.
	local chugent = math.ceil((os.clock() - t0) * 1000)
	print ("[lib_mg_continental_mg_continental] Mapchunk generation time " .. chugent .. " ms")

	table.insert(mapgen_times.noisemaps, 0)
	table.insert(mapgen_times.preparation, t1 - t0)
	table.insert(mapgen_times.loops, t2 - t1)
	table.insert(mapgen_times.writing, t3 - t2 + t5 - t4)
	table.insert(mapgen_times.liquid_lighting, t4 - t3)
	table.insert(mapgen_times.make_chunk, t5 - t0)

	-- Deal with memory issues. This, of course, is supposed to be automatic.
	local mem = math.floor(collectgarbage("count")/1024)
	if mem > 1000 then
		print("lib_mg_continental_mg_continental is manually collecting garbage as memory use has exceeded 500K.")
		collectgarbage("collect")
	end
end)

local function mean( t )
	local sum = 0
	local count= 0

	for k,v in pairs(t) do
		if type(v) == 'number' then
			sum = sum + v
			count = count + 1
		end
	end

	return (sum / count)
end

minetest.register_on_shutdown(function()
	if #mapgen_times.make_chunk == 0 then
		return
	end

	local average, standard_dev
	minetest.log("lib_mg_continental_mg_continental lua Mapgen Times:")

	average = mean(mapgen_times.liquid_lighting)
	minetest.log("  liquid_lighting: - - - - - - - - - - - -  "..average)

	average = mean(mapgen_times.loops)
	minetest.log("  loops: - - - - - - - - - - - - - - - - -  "..average)

	average = mean(mapgen_times.make_chunk)
	minetest.log("  makeChunk: - - - - - - - - - - - - - - -  "..average)

	average = mean(mapgen_times.noisemaps)
	minetest.log("  noisemaps: - - - - - - - - - - - - - - -  "..average)

	average = mean(mapgen_times.preparation)
	minetest.log("  preparation: - - - - - - - - - - - - - -  "..average)

	average = mean(mapgen_times.writing)
	minetest.log("  writing: - - - - - - - - - - - - - - - -  "..average)
end)

--[[
minetest.register_on_newplayer(function(obj)

	local nobj_terrain = minetest.get_perlin_map(np_terrain, {x=1,y=1,z=0})	
	local th=nobj_terrain:get_2d_map({x=1,y=1})
	local height = 0

	--local ntect_idx = lib_mg_continental.mg_data.base_tectonicmap[0][0].closest_idx
	--local ntect_dist = lib_mg_continental.mg_data.base_tectonicmap[0][0].closest_dist
	local ntectonic_idx, ntectonic_dist, ntectonic_edist, ntectonic_edge = lib_mg_continental.get_closest_cell({x = x, y = z})


	if ntectonic_dist == 0 then
		ntectonic_dist = 1
	end
	height = ntectonic_dist / th[1][1]

	minetest.set_timeofday(0.30)

	return true
end)
--]]

