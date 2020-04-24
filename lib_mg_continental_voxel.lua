

minetest.set_mapgen_setting('mg_name','singlenode',true)
minetest.set_mapgen_setting('flags','nolight',true)
--minetest.set_mapgen_params({mgname="singlenode"})

--local storage = minetest.get_mod_storage()

--if lib_mg_continental.nodes == "default" then
--	local c_sand		= minetest.get_content_id("default:sand")
--	local c_stone		= minetest.get_content_id("default:stone")
--	local c_dirt		= minetest.get_content_id("default:dirt")
--	local c_dirtgrass	= minetest.get_content_id("default:dirt_with_grass")
--	local c_dirtgreengrass	= minetest.get_content_id("default:dirt_with_grass")
--	local c_water		= minetest.get_content_id("default:water_source")
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

local map_size = 60000
local map_world_size = 10000
local map_base_scale = 100
local map_size_scale = 10
local map_scale = map_base_scale * map_size_scale

--3    0.1    0.05
local map_noise_scale_multiplier = 5
local map_tectonic_scale = map_world_size / map_scale					--10000 / (100 * 10) = 10
local map_noise_scale = map_tectonic_scale * map_noise_scale_multiplier			--10 * 3

				--729	--358	--31	--29	--43	--17	--330	--83
--[[
	729 = 9^3	358 = 7^2 + 15		693 = 9*11*7		15^3 = 3375
	1331 = 11^3	2431 = 13*17*11		4913 = 17^3		13^3 = 2197
--]]

local voronoi_type = "recursive"     --"single" or "recursive"
local voronoi_cells = 1331
local voronoi_recursion_1 = 11
local voronoi_recursion_2 = 11
local voronoi_recursion_3 = 11
local voronoi_scaled = true

local heightmap_base = 5
local noisemap_base = 7
local cliffmap_base = 7
		
local abs   = math.abs
local max   = math.max
local min   = math.min
local sqrt  = math.sqrt
local floor = math.floor
local modf = math.modf
local random = math.random

local convex = false
local mult = 1.2				--lib_materials.mapgen_scale_factor or 8
local c_mult = 1.2				--lib_materials.mapgen_scale_factor or 8

local mg_golden_ratio = ((1 + (5^0.5)) * 0.5)


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

--[[
np_terrain_alt = {
	--flags = "defaults",
	lacunarity = 2.11,
	offset = -4,
	scale = 80,
	spread = {x = 2400, y = 2400, z = 2400},
	seed = 5934,
	octaves = 8,
	persistence = 0.2,
}
np_terrain_base = {
	--flags = "defaults",
	lacunarity = 2.11,
	offset = -4,
	scale = 280,
	spread = {x = 2400, y = 2400, z = 2400},
	seed = 5934,
	octaves = 8,
	persistence = 0.2,
}
np_terrain_height = {
	--flags = "defaults",
	lacunarity = 2.11,
	offset = -0.4,
	scale = 1,
	spread = {x = 500, y = 500, z = 500},
	seed = 4213,
	octaves = 8,
	persistence = 0.2,
}
np_terrain_persist = {
	--flags = "defaults",
	lacunarity = 2.11,
	offset = 0.6,
	scale = 0.1,
	spread = {x = 2000, y = 2000, z = 2000},
	seed = 539,
	octaves = 3,
	persistence = 0.2,
}
--]]

local np_cliffs = {
	offset = 0,					
	scale = 0.72,
	spread = {x = 180*c_mult, y = 180*c_mult, z = 180*c_mult},
	seed = 78901,
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
--local nbase_terrain = nil
local isln_terrain = nil

--local nobj_terrain_alt = nil
--local isln_terrain_alt = nil
--local nobj_terrain_base = nil
--local isln_terrain_base = nil

--local nobj_terrain_height = nil
--local isln_terrain_height = nil
--local nobj_terrain_persist = nil
--local isln_terrain_persist = nil

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
lib_mg_continental.cells = {}

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
local base_rng = base_max-base_min
local easing_factor = 1/(base_max*base_max*4)

function lib_mg_continental.get_terrain_height_shelf(theight)
		-- parabolic gradient
	if theight > 0 and theight < shelf_thresh then
		theight = theight * (theight*theight/(shelf_thresh*shelf_thresh)*0.5 + 0.5)
	end

	return theight
end

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

function lib_mg_continental.get_distance_chebyshev(a,b)						--get_distance(a,b)
    return (max(abs(a.x-b.x), abs(a.z-b.z)))					--returns the chebyshev distance between two points
end

function lib_mg_continental.get_distance_euclid(a,b)
	local dx = a.x - b.x
	local dz = a.z - b.z
	return (dx*dx+dz*dz)^0.5
end

function lib_mg_continental.get_distance_manhattan(a,b)					--get_manhattan_distance(a,b)
    return (abs(a.x-b.x) + abs(a.z-b.z))					--returns the manhattan distance between two points
end

--DEPRRICATE DISTANCE FUNCTIONS BELOW
--[[
function lib_mg_continental.get_distance(a,b)						--get_distance(a,b)
    return (max(abs(a.x-b.x), abs(a.z-b.z)))					--returns the chebyshev distance between two points
end

function lib_mg_continental.get_avg_distance(a,b)						--get_avg_distance(a,b)
    return ((abs(a.x-b.x) + abs(a.z-b.z)) * 0.5)					--returns the average distance between two points
end

function lib_mg_continental.get_manhattan_distance(a,b)					--get_manhattan_distance(a,b)
    return (abs(a.x-b.x) + abs(a.z-b.z))					--returns the manhattan distance between two points
end

function lib_mg_continental.get_euclid_distance(a,b)
	local dx = a.x - b.x
	local dz = a.z - b.z
	return (dx*dx+dz*dz)^0.5
end
--]]
--END DEPRICATION

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

function lib_mg_continental.get_closest_cell_BAK(pos)

	local closest_cell_idx = 0
	local closest_cell_dist
	local closest_cell_edist = 0
	local last_closest_idx = 0
	local last_dist
	local this_dist
	local edge = false

	for i, point in ipairs(lib_mg_continental.points) do

		this_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})

		if last_dist then
			if last_dist > this_dist then
				closest_cell_idx = i
				closest_cell_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				closest_cell_edist = this_dist
				last_dist = this_dist
				last_closest_idx = i
			elseif last_dist == this_dist then
				closest_cell_idx = last_closest_idx
				closest_cell_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				closest_cell_edist = this_dist
				--closest_cell_edist = max(this_dist, last_dist)
				--closest_cell_edist = max(this_dist, last_dist) - (abs(this_dist - last_dist) * 0.5)
				--closest_cell_edist = min(this_dist, last_dist) + (abs(this_dist - last_dist) * 0.5)
				edge = true
			end
		else
			closest_cell_idx = i
			closest_cell_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			closest_cell_edist = this_dist
			last_dist = this_dist
			last_closest_idx = i
		end
	end
	return closest_cell_idx, closest_cell_dist, closest_cell_edist, edge
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
	local closest_cell_cdist = 0
	local closest_cell_edist = 0
	local closest_cell_mdist = 0
	local last_closest_idx = 0
	local last_dist
	local this_dist
	local edge = false

	for i, point in ipairs(lib_mg_continental.points) do

		if point.tier == tier then

			local d_c = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			local d_e = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
			local d_m = lib_mg_continental.get_distance_manhattan({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
	
			if d_type == "c" then
				this_dist = d_c
			elseif d_type == "e" then
				this_dist = d_e
			elseif d_type == "m" then
				this_dist = d_m
			else
	
			end
	
			if last_dist then
				if last_dist > this_dist then
					closest_cell_idx = i
					closest_cell_cdist = d_c
					closest_cell_edist = d_e
					closest_cell_mdist = d_m
					last_dist = this_dist
					last_closest_idx = i
				elseif last_dist == this_dist then
					closest_cell_idx = last_closest_idx
					closest_cell_cdist = d_c
					closest_cell_edist = d_e
					closest_cell_mdist = d_m
					edge = true
				end
			else
				closest_cell_idx = i
				closest_cell_cdist = d_c
				closest_cell_edist = d_e
				closest_cell_mdist = d_m
				last_dist = this_dist
				last_closest_idx = i
			end
		end
	end
	return closest_cell_idx, closest_cell_cdist, closest_cell_edist, closest_cell_mdist, edge
end

function lib_mg_continental.get_closest_cell2(pos, dist_type)

	local closest_cell_idx = 0
	local closest_cell_cdist = 0
	local closest_cell_edist = 0
	local closest_cell_mdist = 0
	local last_closest_idx = 0
	local last_dist
	local this_dist
	local edge = false

	for i, point in ipairs(lib_mg_continental.points) do

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
			if last_dist > this_dist then
				closest_cell_idx = i
				closest_cell_cdist = d_c
				closest_cell_edist = d_e
				closest_cell_mdist = d_m
				last_dist = this_dist
				last_closest_idx = i
			elseif last_dist == this_dist then
				closest_cell_idx = last_closest_idx
				closest_cell_cdist = d_c
				closest_cell_edist = d_e
				closest_cell_mdist = d_m
				edge = true
			end
		else
			closest_cell_idx = i
			closest_cell_cdist = d_c
			closest_cell_edist = d_e
			closest_cell_mdist = d_m
			last_dist = this_dist
			last_closest_idx = i
		end
	end
	return closest_cell_idx, closest_cell_cdist, closest_cell_edist, closest_cell_mdist, edge
end


function lib_mg_continental.get_closest_cell_at_tier(pos, tier)

	local closest_cell_idx = 0
	local closest_cell_dist
	local closest_cell_edist = 0
	local last_closest_idx = 0
	local last_dist
	local this_dist
	local edge = false

	for i, point in ipairs(lib_mg_continental.points) do

		if point.tier == tier then

			this_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
	
			if last_dist then
				if last_dist > this_dist then
					closest_cell_idx = i
					closest_cell_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
					closest_cell_edist = this_dist
					last_dist = this_dist
					last_closest_idx = i
				elseif last_dist == this_dist then
					closest_cell_idx = last_closest_idx
					closest_cell_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
					closest_cell_edist = this_dist
					--closest_cell_edist = max(this_dist, last_dist)
					--closest_cell_edist = max(this_dist, last_dist) - (abs(this_dist - last_dist) * 0.5)
					--closest_cell_edist = min(this_dist, last_dist) + (abs(this_dist - last_dist) * 0.5)
					edge = true
				end
			else
				closest_cell_idx = i
				closest_cell_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				closest_cell_edist = this_dist
				last_dist = this_dist
				last_closest_idx = i
			end
		end
	end
	return closest_cell_idx, closest_cell_dist, closest_cell_edist, edge
end


function lib_mg_continental.get_closest_master(pos)

	local closest_cell_idx = 0
	local closest_cell_dist
	local closest_cell_edist = 0
	local last_closest_idx = 0
	local last_dist
	local this_dist
	local edge = false

	for i, point in ipairs(lib_mg_continental.points) do

		if point.tier == 1 then

			this_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
	
			if last_dist then
				if last_dist > this_dist then
					closest_cell_idx = i
					closest_cell_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
					closest_cell_edist = this_dist
					last_dist = this_dist
					last_closest_idx = i
				elseif last_dist == this_dist then
					closest_cell_idx = last_closest_idx
					closest_cell_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
					closest_cell_edist = this_dist
					--closest_cell_edist = max(this_dist, last_dist)
					--closest_cell_edist = max(this_dist, last_dist) - (abs(this_dist - last_dist) * 0.5)
					--closest_cell_edist = min(this_dist, last_dist) + (abs(this_dist - last_dist) * 0.5)
					edge = true
				end
			else
				closest_cell_idx = i
				closest_cell_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				closest_cell_edist = this_dist
				last_dist = this_dist
				last_closest_idx = i
			end
		end
	end
	return closest_cell_idx, closest_cell_dist, closest_cell_edist, edge
end

function lib_mg_continental.get_closest_parent(pos)

	local closest_cell_idx = 0
	local closest_cell_dist
	local closest_cell_edist = 0
	local last_closest_idx = 0
	local last_dist
	local this_dist
	local edge = false

	for i, point in ipairs(lib_mg_continental.points) do

		if point.tier == 2 then

			this_dist = lib_mg_continental.get_distance_euclid({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
	
			if last_dist then
				if last_dist > this_dist then
					closest_cell_idx = i
					closest_cell_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
					closest_cell_edist = this_dist
					last_dist = this_dist
					last_closest_idx = i
				elseif last_dist == this_dist then
					closest_cell_idx = last_closest_idx
					closest_cell_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
					closest_cell_edist = this_dist
					--closest_cell_edist = max(this_dist, last_dist)
					--closest_cell_edist = max(this_dist, last_dist) - (abs(this_dist - last_dist) * 0.5)
					--closest_cell_edist = min(this_dist, last_dist) + (abs(this_dist - last_dist) * 0.5)
					edge = true
				end
			else
				closest_cell_idx = i
				closest_cell_dist = lib_mg_continental.get_distance_chebyshev({x = pos.x, z = pos.z}, {x = point.x, z = point.z})
				closest_cell_edist = this_dist
				last_dist = this_dist
				last_closest_idx = i
			end
		end
	end
	return closest_cell_idx, closest_cell_dist, closest_cell_edist, edge
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


function lib_mg_continental.get_cell_neighbors_ORIG(cell_idx)

	local t_neighbors = {}

	--local v_idx = 1
	--t_neighbors[v_idx] = {}

	for i_n, i_neighbors in ipairs(lib_mg_continental.cells) do
		if i_neighbors.c_i ==  cell_idx then
			local t_dir = {x = 0, z = 0}
			t_neighbors[i_neighbors.n_i] = {}
			t_neighbors[i_neighbors.n_i].c_idx = i_neighbors.c_i
			t_neighbors[i_neighbors.n_i].n_idx = i_neighbors.n_i
			t_neighbors[i_neighbors.n_i].n_pos = {x = i_neighbors.n_x, z = i_neighbors.n_z}
			t_neighbors[i_neighbors.n_i].m_pos = {x = i_neighbors.m_x, z = i_neighbors.m_z}
			t_neighbors[i_neighbors.n_i].n_dist = i_neighbors.cn_d
			t_neighbors[i_neighbors.n_i].m_dist = i_neighbors.cn_d
			if i_neighbors.n_z > i_neighbors.c_z then
				t_dir.z = 1
			elseif i_neighbors.n_z < i_neighbors.c_z then
				t_dir.z = -1
			else
				t_dir.z = 0
			end
			if i_neighbors.n_x > i_neighbors.c_x then
				t_dir.x = 1
			elseif i_neighbors.n_x < i_neighbors.c_x then
				t_dir.x = -1
			else
				t_dir.x = 0
			end
			t_neighbors[i_neighbors.n_i].n_dir = t_dir
			--v_idx = v_idx + 1
		end
	end

	--print("FUNC NEIGHBORS: " .. dump(t_neighbors))

	return t_neighbors

end

function lib_mg_continental.get_cell_neighbors(cell_idx)

	local t_neighbors = {}

	--local v_idx = 1
	--t_neighbors[v_idx] = {}

	for i_c, cell in ipairs(lib_mg_continental.cells) do
		if cell.c_i ==  cell_idx then
			--local t_dir = {x = 0, z = 0}

			t_neighbors[cell.n_i] = {x = cell.n_x, z = cell.n_z}

			--t_neighbors[cell.n_i] = {}
			--t_neighbors[cell.n_i].c_idx = cell.c_i
			--t_neighbors[cell.n_i].n_idx = cell.n_i
			--t_neighbors[cell.n_i].n_pos = {x = cell.n_x, z = cell.n_z}
			--t_neighbors[cell.n_i].m_pos = {x = cell.m_x, z = cell.m_z}
			--t_neighbors[cell.n_i].n_dist = cell.cn_d
			--t_neighbors[cell.n_i].m_dist = cell.cn_d
			--if cell.n_z > cell.c_z then
			--	t_dir.z = 1
			--elseif cell.n_z < cell.c_z then
			--	t_dir.z = -1
			--else
			--	t_dir.z = 0
			--end
			--if cell.n_x > cell.c_x then
			--	t_dir.x = 1
			--elseif cell.n_x < cell.c_x then
			--	t_dir.x = -1
			--else
			--	t_dir.x = 0
			--end
			--t_neighbors[cell.n_i].n_dir = t_dir
			--v_idx = v_idx + 1
		end
	end

	--print("FUNC NEIGHBORS: " .. dump(t_neighbors))

	return t_neighbors

end



function lib_mg_continental.get_cell_vertices(cell_idx)

	local t_vertex = {}
	local t_neighbors = {}
	--t_neighbors[cell_idx] = {}
	local t_coneighbors = {}
	local c_pos = {x = lib_mg_continental.points[cell_idx].x, z = lib_mg_continental.points[cell_idx].z}

	--local tri = lib_mg_continental.get_triangulation_2d
	local v_idx = 1

	--for i_c, i_cells in ipairs(lib_mg_continental.cells) do
	--	if i_c == cell_idx then
	--		t_neighbors[i_cells.n_i] = {x = i_cells.n_x, z = i_cells.n_z}
	--		c_pos = {x = i_cells.c_x, z = i_cells.c_z}
	--		t_neighbors[v_idx] = {}
	--		t_neighbors[v_idx] = lib_mg_continental.get_cell_neighbors(cell_idx)
	--		v_idx = v_idx + 1
	--	end
	--end

	minetest.log("CELL: " .. cell_idx .. ";  POS: {x = " .. c_pos.x .. ", z = " .. c_pos.z)
	print("CELL: " .. cell_idx .. ";  POS: {x = " .. c_pos.x .. ", z = " .. c_pos.z)

	t_neighbors = lib_mg_continental.get_cell_neighbors(cell_idx)

	minetest.log("NEIGHBORS: " .. dump(t_neighbors))
	print("NEIGHBORS: " .. dump(t_neighbors))

	--v_idx = 1

	for i_n, neighbor in pairs(t_neighbors) do
	--	for i_c, cell in ipairs(lib_mg_continental.cells) do
	--		if i_n == i_c then
	--			t_coneighbors[cell.n_i] = {x = cell.n_x, y = cell.n_z}
	--		end
	--	end

		t_coneighbors[i_n] = {}
		t_coneighbors[i_n] = lib_mg_continental.get_cell_neighbors(neighbor.n_idx)
		--local t_coneighbors = lib_mg_continental.get_cell_neighbors(neighbor.n_idx)

	end

	minetest.log("CONEIGHBORS: " .. dump(t_coneighbors))
	print("CONEIGHBORS: " .. dump(t_coneighbors))

	for i_n, neighbor in pairs(t_neighbors) do

		for i_cn, coneighbor in pairs(t_coneighbors) do

			if i_n == i_cn then

				local tri_x, tri_z = lib_mg_continental.get_triangulation_2d(c_pos, neighbor, coneighbor)
	
				--minetest.log("TRI_X: " .. tri_x .. ";  TRI_Z: " .. tri_z .. "")
				--print("TRI_X: " .. tri_x .. ";  TRI_Z: " .. tri_z .. "")
	
				t_vertex[v_idx] = {}
				t_vertex[v_idx].c_i = cell_idx
				t_vertex[v_idx].c_pos = c_pos
				t_vertex[v_idx].n1_i = i_n
				t_vertex[v_idx].n1_pos = neighbor
				t_vertex[v_idx].n2_i = i_cn
				t_vertex[v_idx].n2_pos = coneighbor
				t_vertex[v_idx].v_pos = {x = tri_x, z = tri_z}

				v_idx = v_idx + 1
			end				

		end

	end

--[[
	local v_idx = 1
	for i_n1, n1 in pairs(t_neighbors) do
		--minetest.log("I_N1: " .. i_n1 .. "; N1: " .. dump(n1))
		--print("I_N1: " .. i_n1 .. "; N1: " .. dump(n1))
		for i_n2, n2 in pairs(t_neighbors) do
			--minetest.log("I_N2: " .. i_n2 .. "; N2: " .. dump(n2))
			--print("I_N2: " .. i_n2 .. "; N2: " .. dump(n2))
			for i_c, i_cell in ipairs(lib_mg_continental.cells) do
				--minetest.log("I_C: " .. i_c .. "; I_CELL: " .. dump(i_cell))
				--print("I_C: " .. i_c .. "; I_CELL: " .. dump(i_cell))
				if ((i_n1 == i_c) and (i_n2 == i_c)) or ((i_n2 == i_cell.n_i) and (i_n1 == i_cell.n_i)) then

					local tri_x, tri_z = lib_mg_continental.get_triangulation_2d(c_pos, n1, n2)

					--minetest.log("TRI_X: " .. tri_x .. ";  TRI_Z: " .. tri_z .. "")
					--print("TRI_X: " .. tri_x .. ";  TRI_Z: " .. tri_z .. "")

					t_vertex[v_idx] = {}
					t_vertex[v_idx].n1 = i_n1
					t_vertex[v_idx].n2 = i_n2
					t_vertex[v_idx].v_pos = {x = tri_x, z = tri_z}

					v_idx = v_idx + 1

					--minetest.log("CELL: " .. cell_idx .. ";  V_I: " .. v_idx .. ";  N1: " .. i_n1 .. ";  N2: " .. i_n2 .. ";  TRI_X: " .. tri_x .. ";  TRI_Z: " .. tri_z .. "")
					--print("CELL: " .. cell_idx .. ";  V_I: " .. v_idx .. ";  N1: " .. i_n1 .. ";  N2: " .. i_n2 .. ";  TRI_X: " .. tri_x .. ";  TRI_Z: " .. tri_z .. "")

					--minetest.log(dump(tri(c_pos, n1, n2)))
					--minetest.log(dump(t_vertex[i_n].v_pos))
					--print(dump(tri(c_pos, n1, n2)))
					--minetest.log(dump(t_vertex[v_idx]))
					--print(dump(t_vertex[v_idx]))

				end
			end
		end
	end
--]]


	minetest.log("VERTICES: " .. dump(t_vertex))
	print("VERTICES: " .. dump(t_vertex))

	return t_vertex

end


function lib_mg_continental.get_cell_data()

	local t0 = os.clock()
	minetest.log("[lib_mg_continental] Voronoi Cell Data (Cells, Neighbors, Midpoints) generation start")

			-- C = Cell, L = Link, N = Neighbor, M = Midpoint
			-- Cell_Index|Link_Index|Cell_Zpos|CellXpos|Neighbor_Index|Neighbor_Zpos|Neighbor_Xpos|Midpoint_Zpos|Midpoint_Xpos|CellNeighbor_Distance|Cell_Distance|Neighbor_Distance
			-- "#C_Idx|L_Idx|C_Z|C_X|N_Idx|N_Z|N_X|M_Z|M_X|CN_Dist|C_Dist|N_Dist\n"
	local temp_cells = "#C = Cell, L = Link, N = Neighbor, M = Midpoint\n" .. 
			   "#Cell_Index|Link_Index|Cell_Zpos|CellXpos|Neighbor_Index|Neighbor_Zpos|Neighbor_Xpos|Midpoint_Zpos|Midpoint_Xpos|CellNeighbor_Distance|Cell_Distance|Neighbor_Distance\n"

	for i, i_point in ipairs(lib_mg_continental.points) do

		--local tt1 = os.clock()
		temp_cells = temp_cells .. "#C_Idx|L_Idx|C_Z|C_X|N_Idx|N_Z|N_X|M_Z|M_X|CN_Dist|C_Dist|N_Dist\n"

		for k,  k_point in ipairs(lib_mg_continental.points) do
	
			local neighbor_add = false

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

				lib_mg_continental.cells[i] = {}
				lib_mg_continental.cells[i].c_i = i
				lib_mg_continental.cells[i].l_i = i .. "-" .. k
				lib_mg_continental.cells[i].c_z = i_point.z
				lib_mg_continental.cells[i].c_x = i_point.x
				lib_mg_continental.cells[i].n_i = k
				lib_mg_continental.cells[i].n_z = k_point.z
				lib_mg_continental.cells[i].n_x = k_point.x
				lib_mg_continental.cells[i].m_z = m_point_z
				lib_mg_continental.cells[i].m_x = m_point_x
				lib_mg_continental.cells[i].cn_d = cn_dist
				lib_mg_continental.cells[i].cm_d = cm_dist
				lib_mg_continental.cells[i].nm_d = nm_dist

				temp_cells = temp_cells .. i .. "|" .. i .. "-" .. k .. "|" .. i_point.z .. "|" .. i_point.x .. 
					"|" .. k .. "|" .. k_point.z .. "|" .. k_point.x ..
					"|" .. m_point_z .. "|" .. m_point_x .. "|" .. cn_dist .. 
					"|" .. cm_dist .. "|" .. nm_dist .. "\n"
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
	local chugent = math.ceil((os.clock() - t0) * 1000)
	minetest.log("[lib_mg_continental] Voronoi Cell Data Total Time " .. chugent .. " seconds")

end


function lib_mg_continental.get_points(cells, size)

	if not cells or not size then
		return
	end

	-- Start time of voronoi generation.
	local t0 = os.clock()
	minetest.log("[lib_mg_continental] Voronoi Cell Random Points generation start")

	local temp_points = "#Cell_Idx|Cell_Z|Cell_X|Parent_Idx|Tier\n" ..
			    "#C_Idx|C_Z|C_X|P_Idx|Tier\n"

	--Prevents points from too near edges, ideally creating more evenly sized cells.
	--Minumum: 50
	local size_offset = size * 0.1
	local size_half = size * 0.5

	for i_c = 1, cells do
		local t_pt = {x = (math.random(1 + size_offset, size - size_offset) - size_half), z = (math.random(1 + size_offset, size - size_offset) - size_half)}
		lib_mg_continental.points[i_c] = {}
		lib_mg_continental.points[i_c].z = t_pt.z
		lib_mg_continental.points[i_c].x = t_pt.x
		lib_mg_continental.points[i_c].master = 0
		lib_mg_continental.points[i_c].parent = 0
		lib_mg_continental.points[i_c].tier = 1
		temp_points = temp_points .. i_c .. "|" .. t_pt.z .. "|" .. t_pt.x .. "|" .. "0" .. "|" .. "1" .. "\n"
	end
	lib_mg_continental.save_csv(temp_points, "lib_mg_continental_data_points.txt")
	--minetest.log("[lib_mg_continental] Voronoi Cell Point List:\n" .. temp_points .. "")

	-- Random Points generation finished. Check the timer to know the elapsed time.
	local t1 = os.clock()
	minetest.log("[lib_mg_continental] Voronoi Cell Random Points generation time " .. (t1-t0) .. " ms")

end

function lib_mg_continental.get_points2(cells_x, cells_y, cells_z, size)

	if not cells_x or not size then
		return
	end

	-- Start time of voronoi generation.
	local t0 = os.clock()
	minetest.log("[lib_mg_continental] Voronoi Cell Random Points generation start")

	local temp_points = "#Cell_Idx|Cell_Z|Cell_X|Parent_Idx|Tier\n" ..
			    "#C_Idx|C_Z|C_X|P_Idx|Tier\n"

	--Prevents points from too near edges, ideally creating more evenly sized cells.
	--Minumum: 50

	--local cells_sqrt = cells_x^0.5
	--local cells_grid_size, cells_grid_rmdr = modf(cells_sqrt / 1)
	--local cells_sq = cells_grid_size^2
	--local cells_grid_diff = cells - cells_sq

	local map_grid_size = size / 4

	local size_offset = size * 0.1
	local size_half = size * 0.5
	--local cell_grid_stride = size_offset

	local t_points = {}
	local v_idx = 1
	local c_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
	local c_pt_z = math.random(1 + size_offset, size - size_offset) - size_half

	for i_c = 1, cells_x do

		for pt, pts in pairs(t_points) do
			if abs(c_pt_x - pts.x) <= map_grid_size then
				c_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
			end
			if abs(c_pt_z - pts.z) <= map_grid_size then
				c_pt_z = math.random(1 + size_offset, size - size_offset) - size_half
			end
			--if lib_mg_continental.get_distance_euclid({x = c_pt_x, z = c_pt_z}, {x = pts.x, z = pts.z}) <= map_grid_size then
			--	c_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
			--	c_pt_z = math.random(1 + size_offset, size - size_offset) - size_half
			--end
		end

		lib_mg_continental.points[v_idx] = {}
		lib_mg_continental.points[v_idx].z = c_pt_z
		lib_mg_continental.points[v_idx].x = c_pt_x
		lib_mg_continental.points[v_idx].master = 0
		lib_mg_continental.points[v_idx].parent = 0
		lib_mg_continental.points[v_idx].tier = 1
		t_points[v_idx] = {x = c_pt_x, z = c_pt_z}
		temp_points = temp_points .. v_idx .. "|" .. c_pt_z .. "|" .. c_pt_x .. "|" .. "0" .. "|" .. "1" .. "\n"

		local c_parent = v_idx
		v_idx = v_idx + 1

		for i_t = 1, cells_y do

			local t_pt_x = math.random(c_pt_x - size_offset, c_pt_x + size_offset)
			local t_pt_z = math.random(c_pt_z - size_offset, c_pt_z + size_offset)

			lib_mg_continental.points[v_idx] = {}
			lib_mg_continental.points[v_idx].z = t_pt_z
			lib_mg_continental.points[v_idx].x = t_pt_x
			lib_mg_continental.points[v_idx].master = 0
			lib_mg_continental.points[v_idx].parent = c_parent
			lib_mg_continental.points[v_idx].tier = 2
			temp_points = temp_points .. v_idx .. "|" .. t_pt_z .. "|" .. t_pt_x .. "|" .. c_parent .. "|" .. "2" .. "\n"

			local t_parent = v_idx
			v_idx = v_idx + 1

			for i_p = 1, cells_z do

				local p_pt_x = math.random(t_pt_x - (size_offset * 0.25), t_pt_x + (size_offset * 0.25))
				local p_pt_z = math.random(t_pt_z - (size_offset * 0.25), t_pt_z + (size_offset * 0.25))

				lib_mg_continental.points[v_idx] = {}
				lib_mg_continental.points[v_idx].z = p_pt_z
				lib_mg_continental.pointss[v_idx].x = p_pt_x
				lib_mg_continental.points[v_idx].master = c_parent
				lib_mg_continental.points[v_idx].parent = t_parent
				lib_mg_continental.points[v_idx].tier = 3
				temp_points = temp_points .. v_idx .. "|" .. p_pt_z .. "|" .. p_pt_x .. "|" .. t_parent .. "|" .. "3" .. "\n"

				v_idx = v_idx + 1

			end
			temp_points = temp_points .. "#" .. "\n"
		end
	end

	lib_mg_continental.save_csv(temp_points, "lib_mg_continental_data_points.txt")
	--minetest.log("[lib_mg_continental] Voronoi Cell Point List:\n" .. temp_points .. "")

	-- Random Points generation finished. Check the timer to know the elapsed time.
	local t1 = os.clock()
	minetest.log("[lib_mg_continental] Voronoi Cell Random Points generation time " .. (t1-t0) .. " ms")

end

function lib_mg_continental.make_voronoi_recursive(cells_x, cells_y, cells_z, size)

	if not cells_x or not cells_y or not cells_z or not size then
		return
	end

	-- Start time of voronoi generation.
	local t0 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Generation Start")

	local temp_points = "#Cell_Idx|Cell_Z|Cell_X|Master_Idx|Parent_Idx|Tier\n" ..
			    "#C_Idx|C_Z|C_X|M_Idx|P_Idx|Tier\n"

	local map_grid_size = size / 4

	--Prevents points from too near edges, ideally creating more evenly sized cells.
	local size_offset = size * 0.1
	local size_half = size * 0.5

	--local cells_sqrt = cells_x^0.5
	--local cells_grid_size, cells_grid_rmdr = modf(cells_sqrt / 1)
	--local cells_sq = cells_grid_size^2
	--local cells_grid_diff = cells - cells_sq
	--local cell_grid_stride = size_offset

	local t_points = {}
	local v_idx = 1

	local c_parent = 0
	local t_parent = 0

	for i_c = 1, cells_x do

		local c_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
		local c_pt_z = math.random(1 + size_offset, size - size_offset) - size_half

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
		lib_mg_continental.points[v_idx].z = c_pt_z
		lib_mg_continental.points[v_idx].x = c_pt_x
		lib_mg_continental.points[v_idx].master = c_parent
		lib_mg_continental.points[v_idx].parent = t_parent
		lib_mg_continental.points[v_idx].tier = 1
		t_points[v_idx] = {x = c_pt_x, z = c_pt_z}
		temp_points = temp_points .. v_idx .. "|" .. c_pt_z .. "|" .. c_pt_x .. "|" .. c_parent .. "|" .. t_parent .. "|" .. "1" .. "\n"

		v_idx = v_idx + 1

	end
	temp_points = temp_points .. "#" .. "\n"
	local t1 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Tier 1 Generation Time: " .. (t1-t0) .. " ms")


	--#(cells_x * (cells_y - 1))
	for i_t = 1, (cells_x * cells_y) do

		local t_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
		local t_pt_z = math.random(1 + size_offset, size - size_offset) - size_half
		c_parent = lib_mg_continental.get_closest_cell({x = t_pt_x, z = t_pt_z}, "e", 1)
		t_parent = c_parent

		lib_mg_continental.points[v_idx] = {}
		lib_mg_continental.points[v_idx].z = t_pt_z
		lib_mg_continental.points[v_idx].x = t_pt_x
		lib_mg_continental.points[v_idx].master = c_parent
		lib_mg_continental.points[v_idx].parent = t_parent
		lib_mg_continental.points[v_idx].tier = 2
		temp_points = temp_points .. v_idx .. "|" .. t_pt_z .. "|" .. t_pt_x .. "|" .. c_parent .. "|" .. t_parent .. "|" .. "2" .. "\n"

		v_idx = v_idx + 1
	end
	temp_points = temp_points .. "#" .. "\n"
	local t2 = os.clock()
	minetest.log("[lib_mg_continental] Recursive Voronoi Cell Random Points Tier 2 Generation Time: " .. (t2-t1) .. " ms")


	--#((cells_x * cells_y * cells_z) - (cells_x * cells_y))
	for i_p = 1, (cells_x * cells_y * cells_z) do

		local p_pt_x = math.random(1 + size_offset, size - size_offset) - size_half
		local p_pt_z = math.random(1 + size_offset, size - size_offset) - size_half
		c_parent = lib_mg_continental.get_closest_cell({x = p_pt_x, z = p_pt_z}, "e", 1)
		t_parent = lib_mg_continental.get_closest_cell({x = p_pt_x, z = p_pt_z}, "e", 2)


		lib_mg_continental.points[v_idx] = {}
		lib_mg_continental.points[v_idx].z = p_pt_z
		lib_mg_continental.points[v_idx].x = p_pt_x
		lib_mg_continental.points[v_idx].master = c_parent
		lib_mg_continental.points[v_idx].parent = t_parent
		lib_mg_continental.points[v_idx].tier = 3
		temp_points = temp_points .. v_idx .. "|" .. p_pt_z .. "|" .. p_pt_x .. "|" .. c_parent .. "|" .. t_parent .. "|" .. "3" .. "\n"

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

	local t_points = lib_mg_continental.load_csv("|", "lib_mg_continental_data_points.txt")
	if (t_points == nil) then

		minetest.log("[lib_mg_continental] Voronoi Cell Points file not found.  Using randomly generated points.")
		print("[lib_mg_continental] Voronoi Cell Points file not found.  Using randomly generated points.")

		if voronoi_type == "single" then
			lib_mg_continental.get_points(voronoi_cells, map_size)
		else
			--lib_mg_continental.get_points2(voronoi_recursion_1, voronoi_recursion_2, voronoi_recursion_3, map_size)
			lib_mg_continental.make_voronoi_recursive(voronoi_recursion_1, voronoi_recursion_2, voronoi_recursion_3, map_size)
		end

	else

		for i_p, p_point in ipairs(t_points) do
	
			local idx, p_z, p_x, p_master, p_parent, p_tier = unpack(p_point)
	
			lib_mg_continental.points[tonumber(idx)] = {}
			if voronoi_scaled then

				lib_mg_continental.points[tonumber(idx)].z = (tonumber(p_z) * 0.1)
				lib_mg_continental.points[tonumber(idx)].x = (tonumber(p_x) * 0.1)

			else

				lib_mg_continental.points[tonumber(idx)].z = tonumber(p_z)
				lib_mg_continental.points[tonumber(idx)].x = tonumber(p_x)

			end
			lib_mg_continental.points[tonumber(idx)].master = tonumber(p_master)
			lib_mg_continental.points[tonumber(idx)].parent = tonumber(p_parent)
			lib_mg_continental.points[tonumber(idx)].tier = tonumber(p_tier)
	
		end
		minetest.log("[lib_mg_continental] Voronoi Cell Points loaded from file.")

	end
end
function lib_mg_continental.load_cells()

	local t_cells = lib_mg_continental.load_csv("|", "lib_mg_continental_data_cells.txt")
	if (t_cells == nil) then

		minetest.log("[lib_mg_continental] Voronoi Cell Data file not found.  Generating data instead.")
		print("[lib_mg_continental] Voronoi Cell Data file not found.  Generating data instead.")
		minetest.log("This is processing intensive, and may take a while, but only needs to run once to generate the data.  Please be patient.")
		print("This is processing intensive, and may take a while, but only needs to run once to generate the data.  Please be patient.")

		lib_mg_continental.get_cell_data()

	else

		for i_c, c_point in ipairs(t_cells) do
	
			local idx, c_idx, l_idx, c_posz, c_posx, n_idx, n_posz, n_posx, m_posz, m_posx, cn_dist, cm_dist, nm_dist = unpack(c_point)
	
			lib_mg_continental.cells[tonumber(idx)] = {}
			lib_mg_continental.cells[tonumber(idx)].c_i = tonumber(c_idx)
			lib_mg_continental.cells[tonumber(idx)].l_i = tonumber(l_idx)
			if voronoi_scaled then

				lib_mg_continental.cells[tonumber(idx)].c_z = (tonumber(c_posz) * 0.1)
				lib_mg_continental.cells[tonumber(idx)].c_x = (tonumber(c_posx) * 0.1)
				lib_mg_continental.cells[tonumber(idx)].n_i = tonumber(n_idx)
				lib_mg_continental.cells[tonumber(idx)].n_z = (tonumber(n_posz) * 0.1)
				lib_mg_continental.cells[tonumber(idx)].n_x = (tonumber(n_posx) * 0.1)
				lib_mg_continental.cells[tonumber(idx)].m_z = (tonumber(m_posz) * 0.1)
				lib_mg_continental.cells[tonumber(idx)].m_x = (tonumber(m_posx) * 0.1)
				lib_mg_continental.cells[tonumber(idx)].cn_d = (tonumber(cn_dist) * 0.1)
				lib_mg_continental.cells[tonumber(idx)].cm_d = (tonumber(cm_dist) * 0.1)
				lib_mg_continental.cells[tonumber(idx)].nm_d = (tonumber(nm_dist) * 0.1)

			else

				lib_mg_continental.cells[tonumber(idx)].c_z = tonumber(c_posz)
				lib_mg_continental.cells[tonumber(idx)].c_x = tonumber(c_posx)
				lib_mg_continental.cells[tonumber(idx)].n_i = tonumber(n_idx)
				lib_mg_continental.cells[tonumber(idx)].n_z = tonumber(n_posz)
				lib_mg_continental.cells[tonumber(idx)].n_x = tonumber(n_posx)
				lib_mg_continental.cells[tonumber(idx)].m_z = tonumber(m_posz)
				lib_mg_continental.cells[tonumber(idx)].m_x = tonumber(m_posx)
				lib_mg_continental.cells[tonumber(idx)].cn_d = tonumber(cn_dist)
				lib_mg_continental.cells[tonumber(idx)].cm_d = tonumber(cm_dist)
				lib_mg_continental.cells[tonumber(idx)].nm_d = tonumber(nm_dist)

			end
		end
		minetest.log("[lib_mg_continental] Voronoi Cell Data loaded from file.")

	end
end

minetest.log("[lib_mg_continental ] Voronoi Cell Data Processing ...")
lib_mg_continental.load_points()
lib_mg_continental.load_cells()
lib_mg_continental.edgemap = {}
minetest.log("[lib_mg_continental] Voronoi Cell Data Completed.")
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
	
	nobj_terrain = nobj_terrain or minetest.get_perlin_map(np_terrain, csize)
	--nbase_terrain = nobj_terrain:get2dMap_flat({x=minp.x, y=minp.z})
	isln_terrain=nobj_terrain:get_2d_map({x=minp.x,y=minp.z})

	--nobj_terrain_alt = nobj_terrain_alt or minetest.get_perlin_map(np_terrain_alt, csize)
	--isln_terrain_alt = nobj_terrain_alt:get_2d_map({x=minp.x,y=minp.z})
	--nobj_terrain_base = nobj_terrain_base or minetest.get_perlin_map(np_terrain_base, csize)
	--isln_terrain_base = nobj_terrain_base:get_2d_map({x=minp.x,y=minp.z})

	--nobj_terrain_height = nobj_terrain_height or minetest.get_perlin_map(np_terrain_height, csize)
	--isln_terrain_height = nobj_terrain_height:get_2d_map({x=minp.x,y=minp.z})
	--nobj_terrain_persist = nobj_terrain_persist or minetest.get_perlin_map(np_terrain_persist, csize)
	--isln_terrain_persist = nobj_terrain_persist:get_2d_map({x=minp.x,y=minp.z})

	---- cliffs
	nobj_cliffs = nobj_cliffs or minetest.get_perlin_map(np_cliffs, permapdims3d)
	isln_cliffs = nobj_cliffs:get_2d_map({x=minp.x,y=minp.z})

	--nobj_heatmap = nobj_heatmap or minetest.get_perlin_map(np_heat, csize)
	nobj_heatmap = nobj_heatmap or minetest.get_perlin_map(np_heat, chulens)
	--nbase_heatmap = nobj_heatmap:get_2d_map({x=minp.x, y=minp.z})
	nbase_heatmap = nobj_heatmap:get2dMap_flat({x=minp.x, y=minp.z})

	--nobj_heatblend = nobj_heatblend or minetest.get_perlin_map(np_heat_blend, csize)
	nobj_heatblend = nobj_heatblend or minetest.get_perlin_map(np_heat_blend, chulens)
	--nbase_heatblend = nobj_heatblend:get_2d_map({x=minp.x, y=minp.z})
	nbase_heatblend = nobj_heatblend:get2dMap_flat({x=minp.x, y=minp.z})

	--nobj_humiditymap = nobj_humiditymap or minetest.get_perlin_map(np_humid, csize)
	nobj_humiditymap = nobj_humiditymap or minetest.get_perlin_map(np_humid, chulens)
	--nbase_humiditymap = nobj_humiditymap:get_2d_map({x=minp.x, y=minp.z})
	nbase_humiditymap = nobj_humiditymap:get2dMap_flat({x=minp.x, y=minp.z})

	--nobj_humidityblend = nobj_humidityblend or minetest.get_perlin_map(np_humid_blend, csize)
	nobj_humidityblend = nobj_humidityblend or minetest.get_perlin_map(np_humid_blend, chulens)
	--nbase_humidityblend = nobj_humidityblend:get_2d_map({x=minp.x, y=minp.z})
	nbase_humidityblend = nobj_humidityblend:get2dMap_flat({x=minp.x, y=minp.z})

	-- Mapgen preparation is now finished. Check the timer to know the elapsed time.
	local t1 = os.clock()

	local write = false
	
	local center_of_chunk = { 
		x = maxp.x - lib_mg_continental.half_map_chunk_size, 
		y = maxp.y - lib_mg_continental.half_map_chunk_size, 
		z = maxp.z - lib_mg_continental.half_map_chunk_size
	} 

	local c_x = center_of_chunk.x
	local c_y = center_of_chunk.y

	--local ncell_idx, ncell_dist, ncell_edist, ncell_edge = lib_mg_continental.get_closest_cell({x = c_x, z = c_y}, "e", 3)
	--local ncell_rdist = (ncell_dist + ncell_edist) * 0.5

	--local n_data = lib_mg_continental.get_cell_neighbors(ncell_idx)
	--local v_data = lib_mg_continental.get_cell_vertices(ncell_idx)

	--minetest.log("[lib_mg_continental_mg_continental] Neighbors:\n" .. dump(n_data))
	--minetest.log("[lib_mg_continental_mg_continental] Vertices:\n" .. dump(v_data))
	--print("[lib_mg_continental_mg_continental] Neighbors:\n" .. dump(n_data))
	--print("[lib_mg_continental_mg_continental] Vertices:\n" .. dump(v_data))

	--local t_n_dist = 0
	--for n_idx, n_temp in ipairs(n_data) do
	--	t_n_dist = t_n_dist + n_temp.n_dist
	--end
	--local avg_n_dist = t_n_dist / #n_data

	--local ncell_Z = lib_mg_continental.points[ncell_idx].z
	--local ncell_X = lib_mg_continental.points[ncell_idx].x
	--local ncell_master = lib_mg_continental.points[ncell_idx].master
	--local ncell_parent = lib_mg_continental.points[ncell_idx].parent
	--local ncell_Tier = lib_mg_continental.points[ncell_idx].tier
	--local ncell_neighbors = lib_mg_continental.mg_data.base_cells[ncell_idx]

	--local ntectonic_idx, ntectonic_dist, ntectonic_edist = lib_mg_continental.get_closest_cell({x = c_x, y = c_y})
	--local ntectonic_rdist = ((ntectonic_dist + ntectonic_edist) * 0.5)		--ridges
	--local ntect_rdist, ntect_rdist_r = math.modf(ntectonic_rdist * 0.1)

	--local chunk_slope, chunk_rise, chunk_run = lib_mg_continental.get_slope({x = c_x, y = c_y}, {x = v_points[ncell_idx].x, y = v_points[ncell_idx].z})
	--local chunk_inverse_c, chunk_inverse_d = lib_mg_continental.get_line_inverse({x = c_x, y = c_y}, {x = v_points[ncell_idx].x, y = v_points[ncell_idx].z})

	--ncell_continental = (base_max * 0.5) - (lib_mg_continental.get_terrain_height_shelf(ncell_edist) * -0.1)
	--ncell_mountain = (base_min * 0.5) + ((lib_mg_continental.get_terrain_height_shelf(ncell_rdist) * 0.1) - 2)

	local points = lib_mg_continental.points
	local cells = lib_mg_continental.cells

	--local neighbors = {}
	--local midpoints = {}
	--local parent = {}
	--local master = {}

	local v_cscale
	local v_mscale

	if voronoi_scaled == true then
	--defaults
		--v_cscale = 0.1
		--v_mscale = 0.25


		--v_cscale = 0.0625
		--v_mscale = 0.1875

		v_cscale = 0.05
		v_mscale = 0.125

	else

		--v_cscale = 0.1
		--v_mscale = 0.25

		--v_cscale = 0.025
		--v_mscale = 0.0625

		v_cscale = 0.015
		v_mscale = 0.05

		--v_cscale = 0.0125
		--v_mscale = 0.03125

	end

--2D HEIGHTMAP GENERATION
	local index2d = 0
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do

			index2d = (z - minp.z) * csize.x + (x - minp.x) + 1

			local theight
			--local vterrain
			--local mterrain
			--local pterrain
			--local cterrain

			--local c_idx, c_cdist, c_edist, c_mdist, c_edge
			--local p_idx, p_cdist, p_edist, p_edge
			--local m_idx, m_cdist, m_edist, m_edge
			--local c_rdist, p_rdist, m_rdist
			--local n_shelf

			--local mcontinental
			--local mmountain
			--local pcontinental
			--local pmountain
			--local ccontinental
			--local cmountain

			--local nterrain = isln_terrain[z-minp.z+1][x-minp.x+1]
			local nterrain = isln_terrain[z-minp.z+1][x-minp.x+1] + (convex and isln_terrain[z-minp.z+1][x-minp.x+1] or 0)
			local ncliff = isln_cliffs[z-minp.z+1][x-minp.x+1]

			local c_idx, c_cdist, c_edist, c_mdist, c_edge = lib_mg_continental.get_closest_cell({x = x, z = z}, "e", 3)
			local c_rdist = (c_cdist + c_edist) * 0.5
--[[
			local n_data = lib_mg_continental.get_cell_neighbors(c_idx)
			local v_data = lib_mg_continental.get_cell_vertices(c_idx)

			--minetest.log("[lib_mg_continental_mg_custom_biomes] Neighbors:\n" .. dump(n_data))
			--minetest.log("[lib_mg_continental_mg_custom_biomes] Vertices:\n" .. dump(v_data))
			--print("[lib_mg_continental_mg_custom_biomes] Neighbors:\n" .. dump(n_data))
			--print("[lib_mg_continental_mg_custom_biomes] Vertices:\n" .. dump(v_data))

			local t_n_dist = 0
			for n_idx, n_temp in ipairs(n_data) do
				t_n_dist = t_n_dist + n_temp.n_dist
			end
			local avg_n_dist = t_n_dist / #n_data
--]]
			--local p_idx = points[c_idx].parent
			--local m_idx = points[c_idx].master

			--local p_cdist = lib_mg_continental.get_distance_chebyshev({x = x, y = z}, {x = cells[p_idx].c_x, y = cells[p_idx].c_z})
			--local p_edist = lib_mg_continental.get_distance_euclid({x = x, y = z}, {x = cells[p_idx].c_x, y = cells[p_idx].c_z})
			--local p_mdist = lib_mg_continental.get_distance_manhattan({x = x, y = z}, {x = cells[p_idx].c_x, y = cells[p_idx].c_z})

			local p_idx, p_cdist, p_edist, p_mdist, p_edge = lib_mg_continental.get_closest_cell({x = x, z = z}, "e", 2)
			local p_rdist = ((p_cdist + p_edist) * 0.5)		--ridges

			--local m_cdist = lib_mg_continental.get_distance_chebyshev({x = x, y = z}, {x = cells[m_idx].c_x, y = cells[m_idx].c_z})
			--local m_edist = lib_mg_continental.get_distance_euclid({x = x, y = z}, {x = cells[m_idx].c_x, y = cells[m_idx].c_z})
			--local m_mdist = lib_mg_continental.get_distance_manhattan({x = x, y = z}, {x = cells[m_idx].c_x, y = cells[m_idx].c_z})

			local m_idx, m_cdist, m_edist, m_mdist, m_edge = lib_mg_continental.get_closest_cell({x = x, z = z}, "e", 1)
			local m_rdist = (m_cdist + m_edist) * 0.5

			local n_shelf = c_rdist * 0.1

			if lib_mg_continental.mode == "full" then


				local mcontinental = lib_mg_continental.get_terrain_height_shelf(m_edist) * v_cscale
				local mmountain = lib_mg_continental.get_terrain_height_shelf(m_rdist) * v_mscale

				local pcontinental = mcontinental + lib_mg_continental.get_terrain_height_shelf(p_edist) * v_cscale
				local pmountain = mmountain + lib_mg_continental.get_terrain_height_shelf(p_rdist) * v_mscale

				local ccontinental = pcontinental + lib_mg_continental.get_terrain_height_shelf(c_cdist) * v_cscale
				local cmountain = pmountain + lib_mg_continental.get_terrain_height_shelf(c_rdist) * v_mscale

				--local t_cont = (base_max * 0.5) - lib_mg_continental.get_terrain_height_shelf(ccontinental)
				local t_cont = base_max - lib_mg_continental.get_terrain_height_shelf(ccontinental)
				--local t_mount = (base_min * 0.5) + lib_mg_continental.get_terrain_height_shelf(cmountain)
				local t_mount = base_min + lib_mg_continental.get_terrain_height_shelf(cmountain)

				--local vterrain = (t_mount - t_cont) - (base_max * 2) - (base_min * 2)
				local vterrain = (t_mount - t_cont)

				theight = vterrain
				--theight = base_min + vterrain
				--theight = nterrain + vterrain
				--theight = lib_mg_continental.get_terrain_height_hills_adjustable_shelf(nterrain,vterrain,ncliff,(n_shelf + (n_shelf / mg_golden_ratio))) - 2
				--theight = lib_mg_continental.get_terrain_height_hills_adjustable_shelf(nterrain + vterrain,vterrain,ncliff,(n_shelf + (n_shelf / mg_golden_ratio))) - 2

			elseif lib_mg_continental.mode == "lite" then


				mcontinental = (lib_mg_continental.get_terrain_height_shelf(m_edist) * (v_scale * -1))
				mmountain = ((lib_mg_continental.get_terrain_height_shelf(m_rdist) * v_scale) - 2)

				pcontinental = (lib_mg_continental.get_terrain_height_shelf(p_edist) * (v_scale * -1))
				pmountain = ((lib_mg_continental.get_terrain_height_shelf(p_rdist) * v_scale) - 2)

				ccontinental = (lib_mg_continental.get_terrain_height_shelf(c_edist) * (v_scale * -1))
				cmountain = ((lib_mg_continental.get_terrain_height_shelf(c_rdist) * (v_scale * -1)) - 2)

				local t_cont = (base_max * 0.01) - lib_mg_continental.get_terrain_height_shelf(mcontinental + pcontinental + ccontinental)
				local t_mount = (base_min * 0.01) + lib_mg_continental.get_terrain_height_shelf(mmountain + pmountain + cmountain)

				theight = lib_mg_continental.get_terrain_height_hills_adjustable_shelf(nterrain + (math.max(t_cont,t_mount)*0.5),(math.max(t_cont,t_mount)*0.1),ncliff,(n_shelf + (n_shelf / mg_golden_ratio))) - 2

			elseif lib_mg_continental.mode == "dev" then

				mcontinental = (lib_mg_continental.get_terrain_height_shelf(m_edist) * (v_scale * -1))
				mmountain = ((lib_mg_continental.get_terrain_height_shelf(m_rdist) * v_scale) - 2)

				pcontinental = (lib_mg_continental.get_terrain_height_shelf(p_edist) * (v_scale * -1))
				pmountain = ((lib_mg_continental.get_terrain_height_shelf(p_rdist) * v_scale) - 2)

				ccontinental = (lib_mg_continental.get_terrain_height_shelf(c_edist) * (v_scale * -1))
				cmountain = ((lib_mg_continental.get_terrain_height_shelf(c_rdist) * (v_scale * -1)) - 2)

				local t_cont = (base_max * 0.01) - lib_mg_continental.get_terrain_height_shelf(mcontinental + pcontinental + ccontinental)
				local t_mount = (base_min * 0.01) + lib_mg_continental.get_terrain_height_shelf(mmountain + pmountain + cmountain)

				--theight = math.max(t_cont,t_mount)

				--theight = lib_mg_continental.get_terrain_height_hills_adjustable_shelf(nterrain + (math.max(t_cont,t_mount)*0.5),(math.max(t_cont,t_mount)*0.1),ncliff,(n_shelf + (n_shelf / mg_golden_ratio))) - 2

				theight = lib_mg_continental.get_terrain_height_hills_adjustable_shelf((math.max(t_cont,t_mount)*0.5),(math.max(t_cont,t_mount)*0.1),ncliff,(n_shelf + (n_shelf / mg_golden_ratio))) - 2

			else
				theight = nterrain
			end

			lib_mg_continental.heightmap[index2d] = theight
			--lib_mg_continental.edgemap[index2d] = c_edge

		end
	end

--2D HEIGHTMAP RENDER
	local index2d = 0
	for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			for x = minp.x, maxp.x do
			 
				index2d = (z - minp.z) * csize.x + (x - minp.x) + 1   
				local ivm = a:index(x, y, z)

				local theight = lib_mg_continental.heightmap[index2d]
				local tedge = lib_mg_continental.edgemap[index2d]

				local fill_depth = 4
				local top_depth = 1

--BUILD BIOMES.
				if y <= theight + 1 then
					if lib_mg_continental.mode == "full" then
--[[
						local t_heat, t_humid, t_altitude, t_name
		
						--local nheat = nbase_heatmap[z-minp.z+1][x-minp.x+1] + nbase_heatblend[z-minp.z+1][x-minp.x+1]
						local nheat = nbase_heatmap[index2d] + nbase_heatblend[index2d]
						--local nhumid = nbase_humiditymap[z-minp.z+1][x-minp.x+1] + nbase_humidityblend[z-minp.z+1][x-minp.x+1]
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
				
						if y >= lib_materials.ocean_depth and y < lib_materials.beach_depth then
							t_altitude = "ocean"
						elseif y >= lib_materials.beach_depth and y < lib_materials.maxheight_beach then
							t_altitude = "beach"
						elseif y >= lib_materials.maxheight_beach and y < lib_materials.maxheight_coastal then
							t_altitude = "coastal"
						elseif y >= lib_materials.maxheight_coastal and y < lib_materials.maxheight_lowland then
							t_altitude = "lowland"
						elseif y >= lib_materials.maxheight_lowland and y < lib_materials.maxheight_shelf then
							t_altitude = "shelf"
						elseif y >= lib_materials.maxheight_shelf and y < lib_materials.maxheight_highland then
							t_altitude = "highland"
						elseif y >= lib_materials.maxheight_highland and y < lib_materials.maxheight_mountain then
							t_altitude = "mountain"
						elseif y >= lib_materials.maxheight_mountain and y < lib_materials.maxheight_strato then
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

					elseif lib_mg_continental.mode == "lite" then

						local nheat = nbase_heatmap[index2d] + nbase_heatblend[index2d]
						local nhumid = nbase_humiditymap[index2d] + nbase_humidityblend[index2d]

						if nheat <= 25 then
							if nhumid <= 25 then
								c_top = c_dirtperma
								c_stone = c_stone
								--c_water = c_water
							elseif nhumid >= 75 then
								c_top = c_snow
								c_stone = c_stone
								--c_water = c_water
							else
								c_top = c_coniferous
								c_stone = c_desertstone
								--c_water = c_water
							end
						elseif nheat >= 75 then
							if nhumid <= 25 then
								c_top = c_desertsand
								c_stone = c_desertsandstone
								--c_water = c_water
							elseif nhumid >= 75 then
								c_top = c_rainforest
								c_stone = c_desertstone
								--c_water = c_water
							else
								c_top = c_dirtjunglegrass
								c_stone = c_stone
								--c_water = c_water
							end
						else
							if nhumid <= 25 then
								c_top = c_sand
								c_stone = c_sandstone
								--c_water = c_water
							elseif nhumid >= 75 then
								c_top = c_dirtgrass
								c_stone = c_stone
								--c_water = c_water
							else
								c_top = c_dirtdrygrass
								c_stone = c_desertstone
								--c_water = c_water
							end
						end
						--if theight <= 2 then
							--c_top = c_sand
						--end

					else
--]]
						if theight <= 0 then
							c_top = c_sand
						else
							c_top = c_dirtgreengrass
						end
					end
				end
--NODE PLACEMENT FROM HEIGHTMAP
				if tedge then
					c_dirt = c_stone
					--if lib_mg_continental.mode == "dev" then
					--	if y <= 0 then
							--fill_depth = 2
							--top_depth = 1
					--		c_top = c_sand
						--else
						--	fill_depth = 4
						--	top_depth = 4
						--	c_dirt = c_river
						--	c_top = c_air
							--c_top = c_dirtgreengrass
					--		c_top = c_stone
					--	end
					--end
				end
	
				if y < (theight - (fill_depth + top_depth)) then
					data[ivm] = c_stone
					write = true
				elseif y >= (theight - (fill_depth + top_depth)) and y < (theight - top_depth) then					--math.ceil(nobj_terrain[index2d])
					data[ivm] = c_dirt
					write = true
				elseif y >= (theight - top_depth) and y <= theight then					--math.ceil(nobj_terrain[index2d])
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

