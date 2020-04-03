

minetest.set_mapgen_setting('mg_name','singlenode',true)
minetest.set_mapgen_setting('flags','nolight',true)
--minetest.set_mapgen_params({mgname="singlenode"})

--local storage = minetest.get_mod_storage()

local mg_map_view = false

local c_desertsandstone	= minetest.get_content_id("lib_materials:stone_sandstone_desert")
local c_sandstone	= minetest.get_content_id("lib_materials:stone_sandstone")
local c_desertstone	= minetest.get_content_id("lib_materials:stone_desert")
local c_stone		= minetest.get_content_id("lib_materials:stone")
local c_desertsand	= minetest.get_content_id("lib_materials:sand_desert")
local c_sand		= minetest.get_content_id("lib_materials:sand")
local c_brick		= minetest.get_content_id("lib_materials:stone_brick")
local c_block		= minetest.get_content_id("lib_materials:stone_block")
local c_desertstoneblock= minetest.get_content_id("lib_materials:stone_desert_block")
local c_desertstonebrick= minetest.get_content_id("lib_materials:stone_desert_brick")
local c_obsidian	= minetest.get_content_id("lib_materials:stone_obsidian")
local c_dirt		= minetest.get_content_id("lib_materials:dirt")
local c_dirtgrass	= minetest.get_content_id("lib_materials:dirt_with_grass")
local c_dirtdrygrass	= minetest.get_content_id("lib_materials:dirt_with_grass_dry")
local c_top		= minetest.get_content_id("lib_materials:dirt_with_litter_coniferous")
local c_snow		= minetest.get_content_id("lib_materials:dirt_with_snow")
local c_water		= minetest.get_content_id("lib_materials:liquid_water_source")
local c_tree		= minetest.get_content_id("lib_ecology:tree_default_trunk")
local c_air		= minetest.get_content_id("air")
local c_ignore		= minetest.get_content_id("ignore")

local fill_depth = 4
local top_depth = 1

local map_world_size
if mg_map_view == false then
	map_world_size = 20000
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
local voronoi_cells = 31
local heightmap_base = 5
local noisemap_base = 7
local cliffmap_base = 7
		
local abs   = math.abs
local max   = math.max
local sqrt  = math.sqrt
local floor = math.floor

local convex = false
local mult = lib_materials.mapgen_scale_factor or 4

local mg_golden_ratio = ((1 + (5^0.5)) * 0.5)

lib_mg_continental.half_map_chunk_size = 40

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
	spread = {x = 180*mult, y =180*mult, z = 180*mult},
	seed = 78901,
	octaves = 2,
	persist = 0.4,
	lacunarity = 2.11,
--	flags = "absvalue"
}
--[[
local np_terrain = {
	offset = -4,
	scale = 50,
	seed = 5934,
	spread = {x = 2400, y = 2400, z = 2400},
	octaves = 5,
	persist = 0.2,
	lacunarity = 2.11,
	--flags = "defaults"
}
local np_cliffs = {
	offset = -4,					
	scale = 0.72,
	spread = {x = 180*mult, y =180*mult, z = 180*mult},
	seed = 78901,
	octaves = 5,
	persist = 0.2,
	lacunarity = 2.11,
--	flags = "absvalue"
}
--]]
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

lib_mg_continental.heightmap = {}
lib_mg_continental.biomemap = {} 

lib_mg_continental.hills_offset = 64*mult
lib_mg_continental.hills_thresh = math.floor((np_terrain.scale)*0.5)
lib_mg_continental.shelf_thresh = math.floor((np_terrain.scale)*0.5) 
lib_mg_continental.cliffs_thresh = math.floor((np_terrain.scale)*0.5)

-- Create a table of biome ids, so I can use the biomemap.
if not lib_mg_continental.biome_ids then

	--local get_cid = minetest.get_content_id
	lib_mg_continental.biome_info = {}

	for name, desc in pairs(minetest.registered_biomes) do

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

	end
end

dofile(lib_mg_continental.path_mod.."/lib_mg_continental_functions_io.lua")
dofile(lib_mg_continental.path_mod.."/lib_mg_continental_functions_utils.lua")
dofile(lib_mg_continental.path_mod.."/lib_mg_continental_functions_voronoi.lua")


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
			local s_z, s_z_r
			local s_x, s_x_r

			local theight
			local ntectonic_idx
			local ntectonic_dist
			local ntectonic_edist
			--local ntectonic_mist
			--local ntectonic_aist

			if mg_map_view == false then
				s_z, s_z_r = math.modf(z / map_tectonic_scale)
				s_x, s_x_r = math.modf(x / map_tectonic_scale)
				if s_z_r >= 5 then
					s_z = s_z + 1
				end
				if s_x_r >= 5 then
					s_x = s_x + 1
				end
				ntectonic_idx = lib_mg_continental.mg_custom_data.base_tectonicmap[s_z][s_x].closest_idx
				ntectonic_dist = lib_mg_continental.mg_custom_data.base_tectonicmap[s_z][s_x].closest_dist
				ntectonic_edist = lib_mg_continental.mg_custom_data.base_tectonicmap[s_z][s_x].closest_edist
				--ntectonic_mdist = lib_mg_continental.mg_custom_data.base_tectonicmap[s_z][s_x].closest_mdist
				--ntectonic_adist = lib_mg_continental.mg_custom_data.base_tectonicmap[s_z][s_x].closest_adist
			else
				s_z = z
				s_x = x
				if ((z > -500) and (z < 500)) and ((x > -500) and (x < 500)) then
					ntectonic_idx = lib_mg_continental.mg_custom_data.base_tectonicmap[z][x].closest_idx
					ntectonic_dist = lib_mg_continental.mg_custom_data.base_tectonicmap[z][x].closest_dist
					ntectonic_edist = lib_mg_continental.mg_custom_data.base_tectonicmap[z][x].closest_edist
					--ntectonic_mdist = lib_mg_continental.mg_custom_data.base_tectonicmap[s_z][s_x].closest_mdist
					--ntectonic_adist = lib_mg_continental.mg_custom_data.base_tectonicmap[s_z][s_x].closest_adist
				else
					ntectonic_idx = -1234
					ntectonic_dist = -2
					ntectonic_edist = -2
				end
			end

--
			if mg_map_view == false then
				if ntectonic_idx <= 0 then
	
					local cell1_idx
					local cell1_pos_x
					local cell1_pos_z
					local cell2_idx
					local cell2_pos_x
					local cell2_pos_z
	
					cell1_idx = lib_mg_continental.mg_custom_data.base_edgemap[s_z][s_x].cell1_index
					cell2_idx = lib_mg_continental.mg_custom_data.base_edgemap[s_z][s_x].cell2_index
		
					cell1_pos_x = lib_mg_continental.mg_custom_data.base_cellmap[cell1_idx].x * map_tectonic_scale
					cell1_pos_z = lib_mg_continental.mg_custom_data.base_cellmap[cell1_idx].z * map_tectonic_scale
					cell2_pos_x = lib_mg_continental.mg_custom_data.base_cellmap[cell2_idx].x * map_tectonic_scale
					cell2_pos_z = lib_mg_continental.mg_custom_data.base_cellmap[cell2_idx].z * map_tectonic_scale
		
					local cell1_dist = lib_mg_continental.get_distance({x=x,y=z}, {x=cell1_pos_x,y=cell1_pos_z})
					local cell1_edist = lib_mg_continental.get_euclid_distance({x=x,y=z}, {x=cell1_pos_x,y=cell1_pos_z})
					local cell2_dist = lib_mg_continental.get_distance({x=x,y=z}, {x=cell2_pos_x,y=cell2_pos_z})
					local cell2_edist = lib_mg_continental.get_euclid_distance({x=x,y=z}, {x=cell2_pos_x,y=cell2_pos_z})
	
					if cell1_dist == cell2_dist then
						ntectonic_idx = 0
						--ntectonic_dist = cell1_dist
						--if cell1_edist > cell2_edist then
						--	ntectonic_edist = (cell1_edist - cell2_edist) * 0.5
						--elseif cell1_edist < cell2_edist then
						--	ntectonic_edist = (cell2_edist - cell1_edist) * 0.5
						--end
					elseif cell1_dist > cell2_dist then
						ntectonic_idx = cell2_idx
						--ntectonic_dist = cell2_dist
						--if cell1_edist > cell2_edist then
						--	ntectonic_edist = (cell1_edist - cell2_edist) * 0.5
						--elseif cell1_edist < cell2_edist then
						--	ntectonic_edist = (cell2_edist - cell1_edist) * 0.5
						--end
					else
						ntectonic_idx = cell1_idx
						--ntectonic_dist = cell1_dist
						--if cell1_edist > cell2_edist then
						--	ntectonic_edist = (cell1_edist - cell2_edist) * 0.5
						--elseif cell1_edist < cell2_edist then
						--	ntectonic_edist = (cell2_edist - cell1_edist) * 0.5
						--end
					end
				end
--
			end

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
	
			lib_mg_continental.heightmap[index2d] = theight

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
						fill_depth = b_fill_d or 6
						c_top = b_top
						top_depth = b_top_d or 1
	
					end
					lib_mg_continental.biomemap[index2d] = b_cid

--VORONOI MARKERS FROM TECTONICMAP
					local s_z, s_z_r
					local s_x, s_x_r
		
					local ntectonic_idx
					local ntectonic_dist
					--local ntectonic_eist
					--local ntectonic_mist
					--local ntectonic_aist
		
					if mg_map_view == false then
						s_z, s_z_r = math.modf(z / map_tectonic_scale)
						s_x, s_x_r = math.modf(x / map_tectonic_scale)
						if s_z_r >= 5 then
							s_z = s_z + 1
						end
						if s_x_r >= 5 then
							s_x = s_x + 1
						end
						ntectonic_idx = lib_mg_continental.mg_custom_data.base_tectonicmap[s_z][s_x].closest_idx
						ntectonic_dist = lib_mg_continental.mg_custom_data.base_tectonicmap[s_z][s_x].closest_dist
						--ntectonic_edist = mg_custom_data.base_tectonicmap[s_z][s_x].closest_edist
						--ntectonic_mdist = mg_custom_data.base_tectonicmap[s_z][s_x].closest_mdist
						--ntectonic_adist = mg_custom_data.base_tectonicmap[s_z][s_x].closest_adist
					else
						s_z = z
						s_x = x
						if ((z > -500) and (z < 500)) and ((x > -500) and (x < 500)) then
							ntectonic_idx = lib_mg_continental.mg_custom_data.base_tectonicmap[z][x].closest_idx
							ntectonic_dist = lib_mg_continental.mg_custom_data.base_tectonicmap[z][x].closest_dist
							ntectonic_edist = lib_mg_continental.mg_custom_data.base_tectonicmap[z][x].closest_edist
						else
							ntectonic_idx = -1234
							ntectonic_dist = -2
							ntectonic_edist = -2
						end
					end
	
					if ntectonic_dist == 0 then

						c_top = c_obsidian

					end

					if mg_map_view == false then
						if ntectonic_idx <= 0 then
			
							local cell1_idx
							local cell1_pos_x
							local cell1_pos_z
							local cell2_idx
							local cell2_pos_x
							local cell2_pos_z
			
							cell1_idx = lib_mg_continental.mg_custom_data.base_edgemap[s_z][s_x].cell1_index
							cell2_idx = lib_mg_continental.mg_custom_data.base_edgemap[s_z][s_x].cell2_index
				
							cell1_pos_x = lib_mg_continental.mg_custom_data.base_cellmap[cell1_idx].x * map_tectonic_scale
							cell1_pos_z = lib_mg_continental.mg_custom_data.base_cellmap[cell1_idx].z * map_tectonic_scale
							cell2_pos_x = lib_mg_continental.mg_custom_data.base_cellmap[cell2_idx].x * map_tectonic_scale
							cell2_pos_z = lib_mg_continental.mg_custom_data.base_cellmap[cell2_idx].z * map_tectonic_scale
				
							local cell1_dist = lib_mg_continental.get_distance({x=x,y=z}, {x=cell1_pos_x,y=cell1_pos_z})
							local cell1_edist = lib_mg_continental.get_euclid_distance({x=x,y=z}, {x=cell1_pos_x,y=cell1_pos_z})
							local cell2_dist = lib_mg_continental.get_distance({x=x,y=z}, {x=cell2_pos_x,y=cell2_pos_z})
							local cell2_edist = lib_mg_continental.get_euclid_distance({x=x,y=z}, {x=cell2_pos_x,y=cell2_pos_z})
			
							if cell1_dist == cell2_dist then
								ntectonic_idx = 0
								ntectonic_dist = cell1_dist
								ntectonic_edist = cell1_edist
								c_top = c_obsidian
							elseif cell1_dist > cell2_dist then
								ntectonic_idx = cell2_idx
								ntectonic_dist = cell2_dist
								ntectonic_edist = cell2_edist
							else
								ntectonic_idx = cell1_idx
								ntectonic_dist = cell1_dist
								ntectonic_edist = cell1_edist
							end
						end
					end
				end

--NODE PLACEMENT FROM HEIGHTMAP
	
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
	print ("[lib_mg_continental] Mapchunk generation time " .. chugent .. " ms")

	table.insert(mapgen_times.noisemaps, 0)
	table.insert(mapgen_times.preparation, t1 - t0)
	table.insert(mapgen_times.loops, t2 - t1)
	table.insert(mapgen_times.writing, t3 - t2 + t5 - t4)
	table.insert(mapgen_times.liquid_lighting, t4 - t3)
	table.insert(mapgen_times.make_chunk, t5 - t0)

	-- Deal with memory issues. This, of course, is supposed to be automatic.
	local mem = math.floor(collectgarbage("count")/1024)
	if mem > 1000 then
		print("lib_mg_continental is manually collecting garbage as memory use has exceeded 500K.")
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
	minetest.log("lib_mg_continental lua Mapgen Times:")

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

minetest.register_on_newplayer(function(obj)

	local nobj_terrain = minetest.get_perlin_map(np_terrain, {x=1,y=1,z=0})	
	local th=nobj_terrain:get_2d_map({x=1,y=1})
	local height = 0

	local ntect_idx = lib_mg_continental.mg_custom_data.base_tectonicmap[0][0].closest_idx
	local ntect_dist = lib_mg_continental.mg_custom_data.base_tectonicmap[0][0].closest_dist

	if ntect_dist == 0 then
		ntect_dist = 1
	end
	height = ntect_dist / th[1][1]

	minetest.set_timeofday(0.30)

	return true
end)



