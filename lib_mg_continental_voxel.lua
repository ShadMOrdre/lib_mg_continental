

minetest.set_mapgen_setting('mg_name','singlenode',true)
minetest.set_mapgen_setting('flags','nolight',true)
--minetest.set_mapgen_params({mgname="singlenode"})

--local storage = minetest.get_mod_storage()

local mg_map_view = false


local c_desertsand	= minetest.get_content_id("default:desert_sand")		--minetest.get_content_id("lib_materials:sand_desert")
local c_desertsandstone	= minetest.get_content_id("default:desert_sandstone")		--minetest.get_content_id("lib_materials:stone_sandstone_desert")
local c_desertstone	= minetest.get_content_id("default:desert_stone")		--minetest.get_content_id("lib_materials:stone_desert")
local c_sand		= minetest.get_content_id("default:sand")			--minetest.get_content_id("lib_materials:sand")
local c_sandstone	= minetest.get_content_id("default:sandstone")			--minetest.get_content_id("lib_materials:stone_sandstone")
local c_stone		= minetest.get_content_id("default:stone")			--minetest.get_content_id("lib_materials:stone")
local c_brick		= minetest.get_content_id("default:stonebrick")			--minetest.get_content_id("lib_materials:stone_brick")
local c_block		= minetest.get_content_id("default:stone_block")		--minetest.get_content_id("lib_materials:stone_block")
local c_desertstoneblock= minetest.get_content_id("default:desert_stone_block")		--minetest.get_content_id("lib_materials:stone_desert_block")
local c_desertstonebrick= minetest.get_content_id("default:desert_stonebrick")		--minetest.get_content_id("lib_materials:stone_desert_brick")
local c_obsidian	= minetest.get_content_id("default:obsidian")			--minetest.get_content_id("lib_materials:stone_obsidian")
local c_dirt		= minetest.get_content_id("default:dirt")			--minetest.get_content_id("lib_materials:dirt")
local c_dirtgrass	= minetest.get_content_id("default:dirt_with_grass")		--minetest.get_content_id("lib_materials:dirt_with_grass")
local c_dirtdrygrass	= minetest.get_content_id("default:dirt_with_dry_grass")	--minetest.get_content_id("lib_materials:dirt_with_grass_dry")
local c_top		= minetest.get_content_id("default:dirt_with_grass")		--minetest.get_content_id("lib_materials:dirt_with_grass")
local c_coniferous	= minetest.get_content_id("default:coniferous_litter")		--minetest.get_content_id("lib_materials:litter_coniferous")
local c_rainforest	= minetest.get_content_id("default:rainforest_litter")		--minetest.get_content_id("lib_materials:litter_rainforest")
local c_snow		= minetest.get_content_id("default:snow")			--minetest.get_content_id("lib_materials:dirt_with_snow")
local c_water		= minetest.get_content_id("default:water_source")		--minetest.get_content_id("lib_materials:liquid_water_source")
local c_river		= minetest.get_content_id("default:river_water_source")		--minetest.get_content_id("lib_materials:liquid_water_river_source")
local c_tree		= minetest.get_content_id("default:tree")			--minetest.get_content_id("lib_ecology:tree_default_trunk")
local c_air		= minetest.get_content_id("air")
local c_ignore		= minetest.get_content_id("ignore")

local fill_depth = 4
local top_depth = 1

local map_world_size
if mg_map_view == false then
	map_world_size = 10000
else
	map_world_size = 1000
end
local map_base_scale = 100
local map_size_scale = 10
--local map_scale = map_base_scale * map_size_scale
local map_scale = map_base_scale * map_size_scale
local map_noise_scale_multiplier = 3
local map_tectonic_scale = map_world_size / map_scale
local map_noise_scale = map_tectonic_scale * map_noise_scale_multiplier

				--31	--29	--43	--17	--330	--83
local voronoi_cells = 125
local heightmap_base = 5
local noisemap_base = 7
local cliffmap_base = 7
		
local abs   = math.abs
local max   = math.max
local sqrt  = math.sqrt
local floor = math.floor

local convex = false
local mult = 8			--lib_materials.mapgen_scale_factor or 8

local mg_golden_ratio = ((1 + (5^0.5)) * 0.5)

--
local np_terrain = {
	offset = -4,
	scale = map_noise_scale,
	seed = 5934,
	spread = {x = map_world_size/map_size_scale, y = map_world_size/map_size_scale, z = map_world_size/map_size_scale},
	octaves = 5,
	persist = 0.6,
	lacunarity = 2.11,
	--flags = "defaults"
}
local np_cliffs = {
	offset = 0,					
	scale = 0.72,
	spread = {x = 180*mult, y = 180*mult, z = 180*mult},
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

local v_points = {
	{x=-350,z=-350},
	{x=-35,z=-350},
	{x=-135,z=-135},
	{x=-35,z=-35},
	{x=-350,z=350},
	{x=-350,z=35},
	{x=-135,z=135},
	{x=-35,z=35},
	{x=350,z=-350},
	{x=35,z=350},
	{x=135,z=-135},
	{x=35,z=-35},
	{x=350,z=350},
	{x=350,z=-35},
	{x=135,z=135},
}

local nobj_terrain = nil
--local nbase_terrain = nil
local isln_terrain = nil

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

lib_mg_continental.mg_data = {}

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
	return ((a.x+b.x)/2), ((a.y+b.y)/2)					--returns the midpoint between two points
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
	--return {}
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
	--return {}
	return nil
end

-- Create a table of biome ids, so I can use the biomemap.
if not lib_mg_continental.biome_ids then

	--local get_cid = minetest.get_content_id
	lib_mg_continental.biome_info = {}

	for name, desc in pairs(minetest.registered_biomes) do
--[[
		local b_cid = minetest.get_biome_id(name)

		local b_top = minetest.get_content_id(desc.node_top)
		local b_top_depth = desc.depth_top or ""
		local b_filler = minetest.get_content_id(desc.node_filler)
		local b_filler_depth = desc.depth_filler or ""
		local b_stone = minetest.get_content_id(desc.node_stone)
		local b_water_top = minetest.get_content_id(desc.node_water_top)
		local b_water_top_depth = desc.depth_water_top or ""
		local b_water = minetest.get_content_id(desc.node_water)
		local b_river = minetest.get_content_id(desc.node_river_water)
		local b_riverbed = minetest.get_content_id(desc.node_riverbed)
		local b_riverbed_depth = desc.depth_riverbed or ""
		local b_cave_liquid = minetest.get_content_id(desc.node_cave_liquid)
		local b_dungeon = minetest.get_content_id(desc.node_dungeon)
		local b_dungeon_alt = minetest.get_content_id(desc.node_dungeon_alt)
		local b_dungeon_stair = minetest.get_content_id(desc.node_dungeon_stair)
		local b_node_dust = minetest.get_content_id(desc.node_dust)
		local b_miny = desc.y_min or ""
		local b_maxy = desc.y_max or ""
		local b_heat = desc.heat_point or ""
		local b_humid = desc.humidity_point or ""

		lib_mg_continental.biome_info[desc.name] = name .. "|" .. b_cid .. "|" .. b_top .. "|" .. b_top_depth .. "|" .. b_filler .. "|" .. b_filler_depth .. "|" .. b_stone .. "|" .. b_water_top
				.. "|" .. b_water_top_depth .. "|" .. b_water .. "|" .. b_river .. "|" .. b_riverbed .. "|" .. b_riverbed_depth .. "|" .. b_cave_liquid .. "|" .. b_dungeon
				.. "|" .. b_dungeon_alt .. "|" .. b_dungeon_stair .. "|" .. b_node_dust .. "|" .. b_miny .. "|" .. b_maxy .. "|" .. b_heat .. "|" .. b_humid .. "\n"
--]]
		if desc then

			local b_cid = minetest.get_biome_id(name)

			--minetest.log("lib_mg_continental: BIOME:" .. name .. ";")
			--print("lib_mg_continental: BIOME:" .. name .. "")
			--minetest.log("lib_mg_continental: STONE:" .. desc.node_stone .. ";")
			--print("lib_mg_continental: STONE:" .. desc.node_stone .. "")

			local b_top, b_top_depth, b_filler, b_filler_depth, b_stone, b_water_top, b_water_top_depth, b_water, b_river, b_riverbed, b_riverbed_depth
			local b_cave_liquid, b_dungeon, b_dungeon_alt, b_dungeon_stair, b_node_dust, b_miny, b_maxy, b_heat, b_humid

			local r_biome = name .. "|" .. b_cid .. "|"

			if desc.node_top then
				b_top = minetest.get_content_id(desc.node_top)
			else
				b_top = minetest.get_content_id("default:dirt_with_grass")
			end
			r_biome = r_biome .. b_top .. "|"

			if desc.depth_top then
				b_top_depth = desc.depth_top or ""
			else
				b_top_depth = "1"
			end
			r_biome = r_biome .. b_top_depth .. "|"

			if desc.node_filler then
				b_filler = minetest.get_content_id(desc.node_filler)
			else
				b_filler = minetest.get_content_id("default:dirt")
			end
			r_biome = r_biome .. b_filler .. "|"

			if desc.depth_filler then
				b_filler_depth = desc.depth_filler
			else
				b_filler_depth = "4"
			end
			r_biome = r_biome .. b_filler_depth .. "|"

			if desc.node_stone then
				b_stone = minetest.get_content_id(desc.node_stone)
			else
				b_stone = minetest.get_content_id("default:stone")
			end
			r_biome = r_biome .. b_stone .. "|"

			if desc.node_water_top then
				b_water_top = minetest.get_content_id(desc.node_water_top)
			else
				b_water_top = minetest.get_content_id("default:water_source")
			end
			r_biome = r_biome .. b_water_top .. "|"

			if desc.depth_water_top then
				b_water_top_depth = desc.depth_water_top
			else
				b_water_top_depth = "1"
			end
			r_biome = r_biome .. b_water_top_depth .. "|"

			if desc.node_water then
				b_water = minetest.get_content_id(desc.node_water)
			else
				b_water = minetest.get_content_id("default:water_source")
			end
			r_biome = r_biome .. b_water .. "|"

			if desc.node_river_water then
				b_river = minetest.get_content_id(desc.node_river_water)
			else
				b_river = minetest.get_content_id("default:river_water_source")
			end
			r_biome = r_biome .. b_river .. "|"

			if desc.node_riverbed then
				b_riverbed = minetest.get_content_id(desc.node_riverbed)
			else
				b_riverbed = minetest.get_content_id("default:gravel")
			end
			r_biome = r_biome .. b_riverbed .. "|"

			if desc.depth_riverbed then
				b_riverbed_depth = desc.depth_riverbed or ""
			else
				b_riverbed_depth = "2"
			end
			r_biome = r_biome .. b_riverbed_depth .. "|"

			if desc.node_cave_liquid then
				b_cave_liquid = minetest.get_content_id(desc.node_cave_liquid)
			else
				b_cave_liquid = minetest.get_content_id("default:lava_source")
			end
			r_biome = r_biome .. b_cave_liquid .. "|"

			if desc.node_dungeon then
				b_dungeon = minetest.get_content_id(desc.node_dungeon)
			else
				b_dungeon = minetest.get_content_id("default:mossycobble")
			end
			r_biome = r_biome .. b_dungeon .. "|"

			if desc.node_dungeon_alt then
				b_dungeon_alt = minetest.get_content_id(desc.node_dungeon_alt)
			else
				b_dungeon_alt = minetest.get_content_id("default:stonebrick")
			end
			r_biome = r_biome .. b_dungeon_alt .. "|"

			if desc.node_dungeon_stair then
				b_dungeon_stair = minetest.get_content_id(desc.node_dungeon_stair)
			else
				b_dungeon_stair = minetest.get_content_id("stairs:stair_cobble")
			end
			r_biome = r_biome .. b_dungeon_stair .. "|"

			if desc.node_dust then
				b_node_dust = minetest.get_content_id(desc.node_dust)
			else
				b_node_dust = minetest.get_content_id("default:snow")
			end
			r_biome = r_biome .. b_node_dust .. "|"

			if desc.y_min then
				b_miny = desc.y_min or ""
			else
				b_miny = "-31000"
			end
			r_biome = r_biome .. b_miny .. "|"

			if desc.y_max then
				b_maxy = desc.y_max or ""
			else
				b_maxy = "31000"
			end
			r_biome = r_biome .. b_maxy .. "|"

			if desc.heat_point then
				b_heat = desc.heat_point or ""
			else
				b_heat = "50"
			end
			r_biome = r_biome .. b_heat .. "|"

			if desc.humidity_point then
				b_humid = desc.humidity_point
			else
				b_humid = "50"
			end
			r_biome = r_biome .. b_humid .. "|"
	
			--lib_mg_continental.biome_info[desc.name] = name .. "|" .. b_cid .. "|" .. b_top .. "|" .. b_top_depth .. "|" .. b_filler .. "|" .. b_filler_depth .. "|" .. b_stone .. "|" .. b_water_top
			--		.. "|" .. b_water_top_depth .. "|" .. b_water .. "|" .. b_river .. "|" .. b_riverbed .. "|" .. b_riverbed_depth .. "|" .. b_cave_liquid .. "|" .. b_dungeon
			--		.. "|" .. b_dungeon_alt .. "|" .. b_dungeon_stair .. "|" .. b_node_dust .. "|" .. b_miny .. "|" .. b_maxy .. "|" .. b_heat .. "|" .. b_humid .. "\n"

			lib_mg_continental.biome_info[desc.name] = r_biome

		end
--

	end
end


--local function make_voronoi(cells, size)
function lib_mg_continental.get_points(cells, size)

	if not cells or not size then
		return
	end

	-- Start time of voronoi generation.
	local t0 = os.clock()
	minetest.log("[lib_mg_continental_voronoi] Random Points generation start")

	--Prevents points from too near edges, ideally creating more evenly sized cells.
	--Minumum: 50
	local size_offset = size * 0.1
	local size_half = size * 0.5

	if cells > 0 then
		local temp_points = "#Index|Pos.Z|Pos.X|Parent|Tier\n"
		v_points = {}
		for i_c = 1, cells do
			local t_pt = {x = (math.random(1 + size_offset, size - size_offset) - size_half), z = (math.random(1 + size_offset, size - size_offset) - size_half)}
			v_points[i_c] = t_pt
			--v_points[i_c] = {}
			--v_points[i_c].pos = t_pt
			--v_points[i_c].parent = 0
			--v_points[i_c].tier = 1
			temp_points = temp_points .. i_c .. "|" .. t_pt.z .. "|" .. t_pt.x .. "|" .. "0" .. "|" .. "1" .. "\n"
		end
		--for i_c2 = 1, 25 do
		--	local t_pt = {x = (math.random(1 + size_offset, size - size_offset) - size_half), z = (math.random(1 + size_offset, size - size_offset) - size_half)}
		--				
		--end
		lib_mg_continental.save_csv(temp_points, "lib_mg_continental_data_points.txt")
		minetest.log("[lib_mg_continental_voronoi] Voronoi Cell Point List:\n" .. temp_points .. "")
	elseif cells == 0 then
		v_points = {}
		for i, point in ipairs(lib_mg_continental.mg_data.base_points) do
			--local idx, p_z, p_x, p_parent, p_tier = unpack(point)
			local idx, p_z, p_x = unpack(point)
			local t_pt = {x = tonumber(p_x), z = tonumber(p_z)}
			v_points[tonumber(idx)] = t_pt
			--v_points[tonumber(idx)] = {}
			--v_points[tonumber(idx)].pos = t_pt
			--v_points[tonumber(idx)].parent = p_parent
			--v_points[tonumber(idx)].tier = p_tier
		end
		minetest.log("[lib_mg_continental_voronoi] Voronoi Cell Point List loaded from file.")
	else
		
	end

	-- Random Points generation finished. Check the timer to know the elapsed time.
	local t1 = os.clock()
	minetest.log("[lib_mg_continental_voronoi] Random Points generation time " .. (t1-t0) .. " ms")

	return v_points

end

function lib_mg_continental.get_cell_data(cells, size)

	local t0 = os.clock()
	minetest.log("[lib_mg_continental_voronoi] Cell Data (Cells, Neighbors, Midpoints) generation start")

	local t_map_cell = {}
	
	local temp_cells = "#Index|LinkIdx|Pos.Z|Pos.X|ClosestIndex|ClosestPosZ|ClosestPosX\n"
	local temp_neighbors = "#CellIndex|LinkIdx|CellPosZ|CellPosX|ClosestNeighborIndex|ClosestNeighborPosZ|ClosestNeighborPosX|ClosestNeighborDist|ClosestNeighborEDist|ClosestNeighborMDist|ClosestNeighborADist|NeighborMidPosZ|NeighborMidPosX\n"
	local temp_midpoints = "#LinkIdx|Pos.Z|Pos.X|DistBetweenCells|Cell1Idx|Cell1Dist|Cell2Idx|Cell2Dist|\n"

	for i, pos in pairs(v_points) do

		--local pos = pnts1.pos

		local closest_neighbor_idx = 0
		local closest_neighbor_pos_x = 0
		local closest_neighbor_pos_z = 0
		local closest_dist = 0			--chebyshev
		local closest_edist = 0			--euclidean
		local closest_adist = 0			--average
		local closest_mdist = 0			--manhattan
		local e_dist
		local m_dist
		local a_dist
		local s_dist
		local t_dist
		--local t_point_x, t_point_z

		for k, pt in pairs(v_points) do

			--local pt = pnts2.pos

			if i ~= k then
				local neighbor_add = false
				e_dist = lib_mg_continental.get_euclid_distance({x=pt.x,y=pt.z}, {x=pos.x,y=pos.z})
				--t_dist = lib_mg_continental.get_euclidean2_distance({x=pt.x,y=pt.z}, {x=pos.x,y=pos.z})
				t_dist = lib_mg_continental.get_distance({x=pt.x,y=pt.z}, {x=pos.x,y=pos.z})
				m_dist = lib_mg_continental.get_manhattan_distance({x=pt.x,y=pt.z}, {x=pos.x,y=pos.z})
				a_dist = lib_mg_continental.get_avg_distance({x=pt.x,y=pt.z}, {x=pos.x,y=pos.z})
				if s_dist then
					if s_dist > t_dist then
						s_dist = t_dist
						closest_neighbor_idx = k
						closest_neighbor_pos_x = pt.x
						closest_neighbor_pos_z = pt.z
						closest_dist = t_dist
						closest_edist = e_dist
						closest_mdist = m_dist
						closest_adist = a_dist
						neighbor_add = true
					elseif s_dist == t_dist then
						s_dist = t_dist
						closest_neighbor_idx = 0
						closest_neighbor_pos_x = pt.x
						closest_neighbor_pos_z = pt.z
						closest_dist = t_dist
					end
				else
					s_dist = t_dist
					closest_neighbor_idx = k
					closest_neighbor_pos_x = pt.x
					closest_neighbor_pos_z = pt.z
			
				end

				local m_point_x, m_point_z = lib_mg_continental.get_midpoint({x=pt.x,y=pt.z}, {x=pos.x,y=pos.z})
				temp_midpoints = temp_midpoints .. i .. "-" .. k .. "|" .. m_point_z .. "|" .. m_point_x .. "|" .. lib_mg_continental.get_distance({x=pt.x,y=pt.z}, {x=pos.x,y=pos.z}) .. "|" .. i .. "|" .. lib_mg_continental.get_distance({x=m_point_x,y=m_point_z}, {x=pos.x,y=pos.z}) .. "|" .. k .. "|" .. lib_mg_continental.get_distance({x=pt.x,y=pt.z}, {x=m_point_x,y=m_point_z}) .. "\n"

				if neighbor_add == true then
					local t_point_x, t_point_z = lib_mg_continental.get_midpoint({x=pt.x,y=pt.z}, {x=pos.x,y=pos.z})
					temp_neighbors = temp_neighbors .. i .. "|" .. i .. "-" .. closest_neighbor_idx .. "|" .. pos.z .. "|" .. pos.x .. "|" .. closest_neighbor_idx .. "|" .. closest_neighbor_pos_z .. "|" .. closest_neighbor_pos_x .. "|" .. s_dist .. "|" .. e_dist .. "|" .. m_dist .. "|" .. a_dist .. "|" .. t_point_z .. "|" .. t_point_x .. "\n"
				end
			
			end

		end

		t_map_cell[i] = {
			link_idx = i .. "-" .. closest_neighbor_idx,
			z = pos.z,
			x = pos.x,
			closest_idx = closest_neighbor_idx,
			closestposz = closest_neighbor_pos_z,
			closestposx = closest_neighbor_pos_x,
		}
		temp_cells = temp_cells .. i .. "|" .. i .. "-" .. closest_neighbor_idx .. "|" .. pos.z .. "|" .. pos.x .. "|" .. closest_neighbor_idx .. "|" .. closest_neighbor_pos_z .. "|" .. closest_neighbor_pos_x .. "\n"

	end

	-- Random cell generation finished. Check the timer to know the elapsed time.
	local t1 = os.clock()
	minetest.log("[lib_mg_continental_voronoi] Cell Data (Cells, Neighbors, Midpoints) generation time " .. (t1-t0) .. " ms")

	lib_mg_continental.save_csv(temp_cells, "lib_mg_continental_data_cells.txt")
	lib_mg_continental.save_csv(temp_neighbors, "lib_mg_continental_data_neighbors.txt")
	lib_mg_continental.save_csv(temp_midpoints, "lib_mg_continental_data_midpoints.txt")

	-- Random cell generation finished. Check the timer to know the elapsed time.
	local t2 = os.clock()
	minetest.log("[lib_mg_continental_voronoi] Cell Data save time " .. (t2-t1) .. " ms")

	-- Print generation time of this mapchunk.
	local chugent = math.ceil((os.clock() - t0) * 1000)
	minetest.log("[lib_mg_continental_voronoi] Voronoi Data generation time " .. chugent .. " ms")

	--return t_map_cell
	return t_map_cell, temp_midpoints, temp_neighbors						--, temp_points

end

--local function make_edge_map(size)
function lib_mg_continental.get_edge_map(size)

	-- Start time of voronoi generation.
	local t0 = os.clock()
	minetest.log("[lib_mg_continental_voronoi] Edge Map generation start")

	local t_map_edge = {}

	local temp_edges = "#ID|Index|Pos.Z|Pos.X|Cell1 Index|Cell1 Distance|Cell1 EDistance|Cell1 MDistance|Cell1 ADistance|Cell Index|Cell2 Distance|Cell2 EDistance|Cell2 MDistance|Cell2 ADistance\n"

	local idx = 1
	for i_z = (1-(size/2)), (size-(size/2)) do
		t_map_edge[i_z] = {}
		for i_x = (1-(size/2)), (size-(size/2)) do
			local closest_cell_idx = 0
			local closest_cell_dist
			local closest_cell_edist = 0
			local closest_cell_mdist = 0
			local closest_cell_adist = 0
			local last_closest_idx = 0
			local last_dist
			local this_dist
			local last_edist
			local last_mdist
			local last_adist
			local e_dist
			local m_dist
			local a_dist

			for i, pos in pairs(v_points) do

				--local pos = pnt.pos

				local edge_add = false

				e_dist = lib_mg_continental.get_euclid_distance({x=i_x,y=i_z}, {x=pos.x,y=pos.z})
				--this_dist = lib_mg_continental.get_euclidean2_distance({{x=i_x,y=i_z}, {x=pos.x,y=pos.z})
				this_dist = lib_mg_continental.get_distance({x=i_x,y=i_z}, {x=pos.x,y=pos.z})
				m_dist = lib_mg_continental.get_manhattan_distance({x=i_x,y=i_z}, {x=pos.x,y=pos.z})
				a_dist = lib_mg_continental.get_avg_distance({x=i_x,y=i_z}, {x=pos.x,y=pos.z})

				if last_dist then
					if last_dist > this_dist then

						closest_cell_idx = i
						closest_cell_dist = this_dist
						closest_cell_edist = e_dist
						last_dist = this_dist
						last_edist = e_dist
						last_mdist = m_dist
						last_adist = a_dist
						last_closest_idx = i

					elseif last_dist == this_dist then

						closest_cell_idx = 0
						edge_add = true
					end
				else
					closest_cell_idx = i
					closest_cell_dist = this_dist
					closest_cell_edist = e_dist
					last_dist = this_dist
					last_edist = e_dist
					last_mdist = m_dist
					last_adist = a_dist
					last_closest_idx = i
				end

				if edge_add == true then
					t_map_edge[i_z][i_x] = {
						index = idx,
						cells_index = "" .. i .. "-" .. last_closest_idx .. "",
						cell1_index = i,
						cell1_distance = this_dist,
						cell1_edistance = e_dist,
						cell1_mdistance = m_dist,
						cell1_adistance = a_dist,
						cell2_index = last_closest_idx,
						cell2_distance = last_dist,
						cell2_edistance = last_edist,
						cell2_mdistance = last_mdist,
						cell2_adistance = last_adist,
					}
					temp_edges = temp_edges .. i_z .. "|" .. i_x .. "|" .. idx .. "|" .. i .. "-" .. last_closest_idx .. "|" .. i .. "|" .. this_dist .. "|" .. e_dist .. "|" .. m_dist .. "|" .. a_dist .. "|" .. last_closest_idx .. "|" .. last_dist .. "|" .. last_edist .. "|" .. last_mdist .. "|" .. last_adist .. "\n"
				end
			end

			idx = idx + 1
		end

	end

	local t1 = os.clock()
	minetest.log("[lib_mg_continental_voronoi] Edge Map generation time " .. (t1-t0) .. " ms")

	lib_mg_continental.save_csv(temp_edges, "lib_mg_continental_data_edges.txt")

	local t2 = os.clock()
	minetest.log("[lib_mg_continental_voronoi] Edge Map save time " .. (t2-t1) .. " ms")

	-- Print generation time of this mapchunk.
	local chugent = math.ceil((os.clock() - t0) * 1000)
	minetest.log("[lib_mg_continental_voronoi] Edge Map Total generation time " .. chugent .. " ms")

	return t_map_edge

end

--local function make_voronoi_maps(size)
function lib_mg_continental.get_maps(size)

	-- Start time of voronoi generation.
	local t0 = os.clock()
	minetest.log("[lib_mg_continental_voronoi] Voronoi and Edges Maps generation start")

	local t_map_voronoi = {}
	local t_map_edge = {}

	local temp_voronoi = "#Index|Pos.Z|Pos.X|ClosestIndex|ClosestDistance\n"
	local temp_edges = "#ID|Index|Pos.Z|Pos.X|Cell1 Index|Cell1 Distance|Cell1 EDistance|Cell1 MDistance|Cell1 ADistance|Cell Index|Cell2 Distance|Cell2 EDistance|Cell2 MDistance|Cell2 ADistance\n"

	local idx = 1
	for i_z = (1-(size/2)), (size-(size/2)) do
		t_map_voronoi[i_z] = {}
		t_map_edge[i_z] = {}
		for i_x = (1-(size/2)), (size-(size/2)) do
			local closest_cell_idx = 0
			local closest_cell_dist
			local closest_cell_edist = 0
			local closest_cell_mdist = 0
			local closest_cell_adist = 0
			local last_closest_idx = 0
			local last_dist
			local this_dist
			local last_edist
			local last_mdist
			local last_adist
			local e_dist
			local m_dist
			local a_dist

			for i, pos in pairs(v_points) do

				--local pos = pnt.pos

				local edge_add = false

				e_dist = lib_mg_continental.get_euclid_distance({x=i_x,y=i_z}, {x=pos.x,y=pos.z})
				--this_dist = lib_mg_continental.get_euclidean2_distance({{x=i_x,y=i_z}, {x=pos.x,y=pos.z})
				this_dist = lib_mg_continental.get_distance({x=i_x,y=i_z}, {x=pos.x,y=pos.z})
				m_dist = lib_mg_continental.get_manhattan_distance({x=i_x,y=i_z}, {x=pos.x,y=pos.z})
				a_dist = lib_mg_continental.get_avg_distance({x=i_x,y=i_z}, {x=pos.x,y=pos.z})

				if last_dist then
					if last_dist > this_dist then

						closest_cell_idx = i
						closest_cell_dist = this_dist
						closest_cell_edist = e_dist
						last_dist = this_dist
						last_edist = e_dist
						last_mdist = m_dist
						last_adist = a_dist
						last_closest_idx = i

					elseif last_dist == this_dist then

						closest_cell_idx = 0
						edge_add = true
					end
				else
					closest_cell_idx = i
					closest_cell_dist = this_dist
					closest_cell_edist = e_dist
					last_dist = this_dist
					last_edist = e_dist
					last_mdist = m_dist
					last_adist = a_dist
					last_closest_idx = i
				end

				if edge_add == true then
					t_map_edge[i_z][i_x] = {
						index = "" .. i .. "-" .. last_closest_idx .. "",
						z = i_z,
						x = i_x,
						cell1_index = i,
						cell1_distance = this_dist,
						cell1_edistance = e_dist,
						cell1_mdistance = m_dist,
						cell1_adistance = a_dist,
						cell2_index = last_closest_idx,
						cell2_distance = last_dist,
						cell2_edistance = last_edist,
						cell2_mdistance = last_mdist,
						cell2_adistance = last_adist,
					}
					temp_edges = temp_edges .. idx .. "|" .. i .. "-" .. last_closest_idx .. "|" .. i_z .. "|" .. i_x .. "|" .. i .. "|" .. this_dist .. "|" .. e_dist .. "|" .. m_dist .. "|" .. a_dist .. "|" .. last_closest_idx .. "|" .. last_dist .. "|" .. last_edist .. "|" .. last_mdist .. "|" .. last_adist .. "\n"
				end
			end

			t_map_voronoi[i_z][i_x] = {
				closest_idx = closest_cell_idx,
				closest_dist = closest_cell_dist,
				closest_edist = closest_cell_edist,
				closest_mdist = closest_cell_mdist,
				closest_adist = closest_cell_adist,
			}
			--temp_voronoi = temp_voronoi .. i_z .. "|" .. i_x .. "|" .. closest_cell_idx .. "|" .. closest_cell_dist .. "\n"
			idx = idx + 1
		end

	end

	local t1 = os.clock()
	minetest.log("[lib_mg_continental_voronoi] Voronoi and Edges Maps generation time " .. (t1-t0) .. " ms")

	--lib_mg_continental.save_csv(temp_voronoi, "lib_mg_continental_data_voronoi.txt")
	lib_mg_continental.save_csv(temp_edges, "lib_mg_continental_data_edges.txt")

	local t2 = os.clock()
	minetest.log("[lib_mg_continental_voronoi] Voronoi and Edges Maps save time " .. (t2-t1) .. " ms")

	-- Print generation time of this mapchunk.
	local chugent = math.ceil((os.clock() - t0) * 1000)
	minetest.log("[lib_mg_continental_voronoi] Voronoi and Edges Maps Total generation time " .. chugent .. " ms")

	return t_map_voronoi, t_map_edge
	--return t_map_voronoi, temp_edges

end

minetest.log("[lib_mg_continental_mg_dev_voronoi] Custom Data Load / Gen Start")
lib_mg_continental.mg_data.base_points = lib_mg_continental.load_csv("|", "lib_mg_continental_data_points.txt")
lib_mg_continental.mg_data.base_cells = lib_mg_continental.load_csv("|", "lib_mg_continental_data_cells.txt")
lib_mg_continental.mg_data.base_cellmap = lib_mg_continental.load("lib_mg_continental_data_cellmap.txt")
lib_mg_continental.mg_data.base_midpoints = lib_mg_continental.load_csv("|", "lib_mg_continental_data_midpoints.txt")
lib_mg_continental.mg_data.base_tectonicmap = lib_mg_continental.load("lib_mg_continental_data_tectonicmap.txt")
lib_mg_continental.mg_data.base_edgemap = lib_mg_continental.load("lib_mg_continental_data_edgemap.txt")
--lib_mg_continental.mg_data.base_edgemap = lib_mg_continental.load_csv("|", "lib_mg_continental_data_edges.txt")

if not (lib_mg_continental.mg_data.base_cellmap) then
	if (lib_mg_continental.mg_data.base_midpoints == nil) then
		if (lib_mg_continental.mg_data.base_points == nil) then
			lib_mg_continental.mg_data.base_points = lib_mg_continental.get_points(voronoi_cells, map_scale)
			lib_mg_continental.mg_data.base_cellmap, lib_mg_continental.mg_data.base_midpoints, lib_mg_continental.mg_data.base_neighbors = lib_mg_continental.get_cell_data(voronoi_cells, map_scale)
			--lib_mg_continental.mg_data.base_cellmap, lib_mg_continental.mg_data.base_midpoints, lib_mg_continental.mg_data.base_neighbors = make_voronoi(voronoi_cells, map_scale)
			lib_mg_continental.save(lib_mg_continental.mg_data.base_cellmap, "lib_mg_continental_data_cellmap.txt")
		else
			lib_mg_continental.mg_data.base_points = lib_mg_continental.get_points(0, map_scale)
			lib_mg_continental.mg_data.base_cellmap, lib_mg_continental.mg_data.base_midpoints, lib_mg_continental.mg_data.base_neighbors = lib_mg_continental.get_cell_data(0, map_scale)
			--lib_mg_continental.mg_data.base_cellmap, lib_mg_continental.mg_data.base_midpoints, lib_mg_continental.mg_data.base_neighbors = make_voronoi(0, map_scale)
			lib_mg_continental.save(lib_mg_continental.mg_data.base_cellmap, "lib_mg_continental_data_cellmap.txt")
		end
	end
end
if not (lib_mg_continental.mg_data.base_tectonicmap) or not (lib_mg_continental.mg_data.base_edgemap) then
	lib_mg_continental.mg_data.base_tectonicmap, lib_mg_continental.mg_data.base_edgemap = lib_mg_continental.get_maps(map_scale)
	--lib_mg_continental.mg_data.base_tectonicmap, lib_mg_continental.mg_data.base_edgemap = make_voronoi_maps(map_scale)
	lib_mg_continental.save(lib_mg_continental.mg_data.base_tectonicmap, "lib_mg_continental_data_tectonicmap.txt")
	lib_mg_continental.save(lib_mg_continental.mg_data.base_edgemap, "lib_mg_continental_data_edgemap.txt")
end
minetest.log("[lib_mg_continental_voronoi] Custom Data Load / Gen End")

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
		x=maxp.x-lib_mg_continental.half_map_chunk_size, 
		y=maxp.y-lib_mg_continental.half_map_chunk_size, 
		z=maxp.z-lib_mg_continental.half_map_chunk_size
	} 

-- 2D Generation loop.
	local index2d = 0
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do

			index2d = (z - minp.z) * csize.x + (x - minp.x) + 1

--2D HEIGHTMAP GENERATION

			local s_z, s_z_r = math.modf(z / map_tectonic_scale)
			local s_x, s_x_r = math.modf(x / map_tectonic_scale)

			if s_z_r >= 5 then
				s_z = s_z + 1
			end
			if s_x_r >= 5 then
				s_x = s_x + 1
			end

			local t_tect_map = lib_mg_continental.mg_data.base_tectonicmap[s_z][s_x]
			local ntectonic_idx = t_tect_map.closest_idx
			local ntectonic_dist = t_tect_map.closest_dist
			local ntectonic_edist = t_tect_map.closest_edist
			--local ntectonic_mist = t_tect_map.closest_mdist
			--local ntectonic_aist = t_tect_map.closest_adist

--[[
			if ntectonic_idx <= 0 then

				local t_edge_map = lib_mg_continental.mg_data.base_edgemap[s_z][s_x]
				local cell1_idx = t_edge_map.cell1_index
				local cell2_idx = t_edge_map.cell2_index
	
				local cellmap1 = lib_mg_continental.mg_data.base_cellmap[cell1_idx]
				local cell1_pos_x = cellmap1.x * map_tectonic_scale
				local cell1_pos_z = cellmap1.z * map_tectonic_scale
				local cellmap2 = lib_mg_continental.mg_data.base_cellmap[cell2_idx]
				local cell2_pos_x = cellmap2.x * map_tectonic_scale
				local cell2_pos_z = cellmap2.z * map_tectonic_scale

				local cell1_dist = lib_mg_continental.get_distance({x=x,y=z}, {x=cell1_pos_x,y=cell1_pos_z})
				local cell1_edist = lib_mg_continental.get_euclid_distance({x=x,y=z}, {x=cell1_pos_x,y=cell1_pos_z})
				local cell2_dist = lib_mg_continental.get_distance({x=x,y=z}, {x=cell2_pos_x,y=cell2_pos_z})
				local cell2_edist = lib_mg_continental.get_euclid_distance({x=x,y=z}, {x=cell2_pos_x,y=cell2_pos_z})

				if cell1_dist == cell2_dist then
					--ntectonic_idx = 0
					--ntectonic_dist = cell1_dist
					--ntectonic_edist = cell1_edist
				elseif cell1_dist > cell2_dist then
					--ntectonic_idx = cell2_idx
					ntectonic_dist = cell2_dist
					ntectonic_edist = cell2_edist
				else
					--ntectonic_idx = cell1_idx
					ntectonic_dist = cell1_dist
					ntectonic_edist = cell1_edist
				end
			end
--]]

			local theight

			local ntectonic_rdist = (ntectonic_dist + ntectonic_edist) * 0.5		--ridges

			local ntect_dist, ntect_dist_r = math.modf(ntectonic_dist * 0.1)
			local ntect_edist, ntect_edist_r = math.modf(ntectonic_edist * 0.1)
			--local ntect_mdist, ntect_mdist_r = math.modf(ntectonic_mdist * 0.1)
			--local ntect_adist, ntect_adist_r = math.modf(ntectonic_adist * 0.1)
			local ntect_rdist, ntect_rdist_r = math.modf(ntectonic_rdist * 0.1)

			local nterrain = isln_terrain[z-minp.z+1][x-minp.x+1]
			local cheight = isln_cliffs[z-minp.z+1][x-minp.x+1]

			local ncontinental = lib_mg_continental.get_terrain_height_shelf(ntectonic_edist) * -0.1
			local nmountain = (lib_mg_continental.get_terrain_height_shelf(ntectonic_rdist) * 0.1) - 2

			if mg_map_view == false then
				theight = lib_mg_continental.get_terrain_height_hills_adjustable_shelf(nterrain + (math.max(ncontinental,nmountain)*0.5),(math.max(ncontinental,nmountain)*0.1),cheight,(ntect_rdist + (ntect_rdist / mg_golden_ratio))) - 2
			else
				theight = lib_mg_continental.get_terrain_height_hills_adjustable_shelf(nterrain + (nmountain * 0.1),(nmountain * 0.1),cheight,(ntect_rdist + (ntect_rdist / mg_golden_ratio)) * 0.1) + 3
			end
	
			lib_mg_continental.heightmap[index2d] = theight - 1

		end
	end

--2D HEIGHTMAP GENERATION
	local index2d = 0
	--local idx = 1
	for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			for x = minp.x, maxp.x do
			 
				index2d = (z - minp.z) * csize.x + (x - minp.x) + 1   
				local ivm = a:index(x, y, z)

				local theight = lib_mg_continental.heightmap[index2d]

				if y <= theight + 1 then
--[[
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
--
					local b_name, b_cid, b_top, b_top_d, b_fill, b_fill_d, b_stone, b_water_top, b_water_top_d, b_water, b_river, b_riverbed, b_riverbed_d
					local b_caveliquid, b_dungeon, b_dungeonalt, b_dungeonstair, b_dust, b_ymin, b_ymax, b_heat, b_humid
			
					if t_name == "" then
						t_name = minetest.get_biome_name(minetest.get_biome_data({x,y,z}).biome)
					end
	
					local fill_depth = 1
					local top_depth = 1
	
					if t_name and t_name ~= "" then
	
						b_name, b_cid, b_top, b_top_d, b_fill, b_fill_d, b_stone, b_water_top, b_water_top_d, b_water, b_river, b_riverbed, b_riverbed_d, b_caveliquid, b_dungeon, b_dungeonalt, b_dungeonstair, b_dust, b_ymin, b_ymax, b_heat, b_humid = unpack(lib_mg_continental.biome_info[t_name]:split("|", false))
	
						c_stone = b_stone
						c_dirt = b_fill
						fill_depth = tonumber(b_fill_d) or 6
						c_top = b_top
						top_depth = tonumber(b_top_d) or 1
	
					end

					lib_mg_continental.biomemap[index2d] = b_cid
--]]
				end

--NODE PLACEMENT FROM HEIGHTMAP

				local nheat = nbase_heatmap[index2d] + nbase_heatblend[index2d]
				local nhumid = nbase_humiditymap[index2d] + nbase_humidityblend[index2d]

				if nhumid <= 50 then
					if nheat <= 25 then
						c_top = c_desertsand
						c_stone = c_desertsandstone
						--c_water = c_muddy
					elseif nheat >= 75 then
						c_top = c_dirtdrygrass
						c_stone = c_desertstone
						--c_water = c_river
					else
						c_top = c_dirtgrass
						c_stone = c_sandstone
						--c_water = c_water
					end
				else
					if nheat <= 25 then
						c_top = c_desertsand
						c_stone = c_desertsandstone
						--c_water = c_muddy
					elseif nheat >= 75 then
						c_top = c_dirtdrygrass
						c_stone = c_sandstone
						--c_water = c_swamp
					else
						c_top = c_dirtgrass
						c_stone = c_stone
						--c_water = c_water
					end
				end
				

				local fill_depth = 4
				local top_depth = 1
	
				if y < (theight - (fill_depth + top_depth)) then
					data[ivm] = c_stone
					write = true
				elseif y >= (theight - (fill_depth + top_depth)) and y < (theight - top_depth) then					--math.ceil(nobj_terrain[index2d])
					data[ivm] = c_dirt
					write = true
				elseif y >= (theight - top_depth) and y <= theight then					--math.ceil(nobj_terrain[index2d])
					if theight <= 2 then
						data[ivm] = c_sand
					else
						data[ivm] = c_top
					end
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
	print ("[lib_mg_continental_mg_custom_biomes] Mapchunk generation time " .. chugent .. " ms")

	table.insert(mapgen_times.noisemaps, 0)
	table.insert(mapgen_times.preparation, t1 - t0)
	table.insert(mapgen_times.loops, t2 - t1)
	table.insert(mapgen_times.writing, t3 - t2 + t5 - t4)
	table.insert(mapgen_times.liquid_lighting, t4 - t3)
	table.insert(mapgen_times.make_chunk, t5 - t0)

	-- Deal with memory issues. This, of course, is supposed to be automatic.
	local mem = math.floor(collectgarbage("count")/1024)
	if mem > 1000 then
		print("lib_mg_continental_mg_custom_biomes is manually collecting garbage as memory use has exceeded 500K.")
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
	minetest.log("lib_mg_continental_mg_custom_biomes lua Mapgen Times:")

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

	local ntect_idx = lib_mg_continental.mg_data.base_tectonicmap[0][0].closest_idx
	local ntect_dist = lib_mg_continental.mg_data.base_tectonicmap[0][0].closest_dist

	if ntect_dist == 0 then
		ntect_dist = 1
	end
	height = ntect_dist / th[1][1]

	minetest.set_timeofday(0.30)

	return true
end)
--]]


