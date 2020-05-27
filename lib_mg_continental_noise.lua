

minetest.set_mapgen_setting('mg_name','singlenode',true)
minetest.set_mapgen_setting('flags','nolight',true)
--minetest.set_mapgen_params({mgname="singlenode"})

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
local voronoi_cells = 2197
local voronoi_recursion_1 = 23
local voronoi_recursion_2 = 17
local voronoi_recursion_3 = 13

local voronoi_scaled = true

--loads default data set from mod path.  If false, or not found, will attempt to load data from world path.  If data not found, data is generated.
local voronoi_mod_defaults = false

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
local mult = 4.8				--lib_materials.mapgen_scale_factor or 8
local c_mult = 4.8				--lib_materials.mapgen_scale_factor or 8

local mg_golden_ratio = ((1 + (5^0.5)) * 0.5)


local np_terrain = {
	offset = -4,
	scale = map_noise_scale*mult,
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

--	seed = 567891,
local np_var = {
	offset = 0,						
	scale = 6*mult,
	spread = {x = 64*mult, y =64*mult, z = 64*mult},
	seed = 567891,
	octaves = 4,
	persist = 0.4,
	lacunarity = 1.89,
	--flags = "eased"
}

--	spread = {x = 32, y =32, z = 32},
--	seed = 2345,
local np_hills = {
	offset = 2.5,					-- off/scale ~ 2:3
	scale = -3.5,
	spread = {x = 64*mult, y =64*mult, z = 64*mult},
	seed = 5934,
	octaves = 3,
	persist = 0.40,
	lacunarity = 2.0,
	flags = "absvalue"
}


--	seed = 78901,
local np_cliffs = {
	offset = 0,					
	scale = 0.72,
	spread = {x = 180*c_mult, y = 180*c_mult, z = 180*c_mult},
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
--local nbase_terrain = nil
local isln_terrain = nil

local nobj_var = nil
local isln_var = nil

local nobj_hills = nil
local isln_hills = nil

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

	-- base variation
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
	

--2D HEIGHTMAP GENERATION
	local index2d = 0
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do

			index2d = (z - minp.z) * csize.x + (x - minp.x) + 1
		
			--local nterrain = isln_terrain[z-minp.z+1][x-minp.x+1] + (convex and isln_terrain[z-minp.z+1][x-minp.x+1] or 0)
			local nterrain = isln_terrain[z-minp.z+1][x-minp.x+1] + (convex and isln_var[z-minp.z+1][x-minp.x+1] or 0)
			--local nterrain = isln_terrain[z-minp.z+1][x-minp.x+1] + (isln_var[z-minp.z+1][x-minp.x+1] or 0)

			--local hterrain = isln_terrain[z-minp.z+1][x-minp.x+1]
			local hheight = isln_hills[z-minp.z+1][x-minp.x+1]

			--local ncliff = isln_cliffs[z-minp.z+1][x-minp.x+1]
			local cheight = isln_cliffs[z-minp.z+1][x-minp.x+1]

			--local n_shelf = c_rdist * 0.1
			local n_shelf = easing_factor
		
			--lib_mg_continental.heightmap[index2d] = lib_mg_continental.get_terrain_height_hills_adjustable_shelf(nterrain,hterrain,ncliff,(n_shelf + (n_shelf / mg_golden_ratio))) - 2
			lib_mg_continental.heightmap[index2d] = lib_mg_continental.get_terrain_height(nterrain,hheight,cheight)

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

				local fill_depth = 4
				local top_depth = 1

--BUILD BIOMES.
				if y <= theight + 1 then
--					if lib_mg_continental.mode == "full" then
--
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
--[[
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
--
						if theight <= 1 then
							c_top = c_sand
						else
							c_top = c_dirtgreengrass
						end
					end
--]]
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

