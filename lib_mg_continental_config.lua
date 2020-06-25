


--##
--##	CONSTANTS and SETTINGS
--##

	--##	Available choices are "flat", "all", "noise", "voronoi",
	lib_mg_continental.mg_type = "voronoi"

	lib_mg_continental.mg_voronoi_defaults = false

	lib_mg_continental.mg_distance_metric = "em"

	lib_mg_continental.mg_world_scale = 0.1

	lib_mg_continental.mg_biome_scale = lib_mg_continental.mg_world_scale

	lib_mg_continental.mg_noise_spread = 2400
	lib_mg_continental.mg_noise_scale = (lib_mg_continental.mg_noise_spread * 0.1) * 0.25
	lib_mg_continental.mg_noise_octaves = 8
	lib_mg_continental.mg_noise_persist = 0.5

	lib_mg_continental.mg_base_height = (lib_mg_continental.mg_noise_spread * 0.1) * lib_mg_continental.mg_world_scale

	lib_mg_continental.mg_map_size = 60000


--##	Terrain Noise and Map Scale defaults.
--##		scale		1	0.1	0.01
--##		octaves		8	7	5
--##		persist		0.5	0.5	0.5
--##
	
	if lib_mg_continental.mg_world_scale < 1 then
		if lib_mg_continental.mg_world_scale >= 0.1 then
			lib_mg_continental.mg_noise_octaves = 5
			lib_mg_continental.mg_noise_persist = 0.5
		else
			lib_mg_continental.mg_noise_octaves = 5
			lib_mg_continental.mg_noise_persist = 0.5
		end
	end	
	
--##		--729	--358	--31	--29	--43	--17	--330	--83
--##
--##		729 = 9^3	358 = 7^2 + 15		693 = 9*11*7		15^3 = 3375
--##		1331 = 11^3	2431 = 13*17*11		4913 = 17^3		13^3 = 2197
--##

	lib_mg_continental.voronoi_type = "recursive"     --"single" or "recursive"
	lib_mg_continental.voronoi_cells = 2197
	lib_mg_continental.voronoi_recursion_1 = 17
	lib_mg_continental.voronoi_recursion_2 = 17
	lib_mg_continental.voronoi_recursion_3 = 17



--##
--##	
--##

	lib_mg_continental.points = {}
	lib_mg_continental.neighbors = {}
	
	lib_mg_continental.heightmap = {}
	lib_mg_continental.biomemap = {} 
	lib_mg_continental.edgemap = {}





--##
--##	CONENT_IDs
--##

	lib_mg_continental.C = {}
	
	lib_mg_continental.C["c_air"]			= minetest.get_content_id("air")
	lib_mg_continental.C["c_ignore"]		= minetest.get_content_id("ignore")
	
	lib_mg_continental.C["c_stone"]			= minetest.get_content_id("lib_materials:stone")
	lib_mg_continental.C["c_brick"]			= minetest.get_content_id("lib_materials:stone_brick")
	lib_mg_continental.C["c_block"]			= minetest.get_content_id("lib_materials:stone_block")
	lib_mg_continental.C["c_cobble"]		= minetest.get_content_id("lib_materials:stone_cobble")
	lib_mg_continental.C["c_mossy"]			= minetest.get_content_id("lib_materials:stone_cobble_mossy")
	lib_mg_continental.C["c_gravel"]		= minetest.get_content_id("lib_materials:stone_gravel")

	lib_mg_continental.C["c_desertsandstone"]	= minetest.get_content_id("lib_materials:stone_sandstone_desert")
	lib_mg_continental.C["c_desertstone"]		= minetest.get_content_id("lib_materials:stone_desert")
	lib_mg_continental.C["c_desertstoneblock"]	= minetest.get_content_id("lib_materials:stone_desert_block")
	lib_mg_continental.C["c_desertstonebrick"]	= minetest.get_content_id("lib_materials:stone_desert_brick")
	lib_mg_continental.C["c_sandstone"]		= minetest.get_content_id("lib_materials:stone_sandstone")
	lib_mg_continental.C["c_obsidian"]		= minetest.get_content_id("lib_materials:stone_obsidian")
	
	lib_mg_continental.C["c_sand"]			= minetest.get_content_id("lib_materials:sand")
	lib_mg_continental.C["c_desertsand"]		= minetest.get_content_id("lib_materials:sand_desert")

	lib_mg_continental.C["c_dirt"]			= minetest.get_content_id("lib_materials:dirt")
	lib_mg_continental.C["c_dirtgrass"]		= minetest.get_content_id("lib_materials:dirt_with_grass")
	lib_mg_continental.C["c_dirtdrygrass"]		= minetest.get_content_id("lib_materials:dirt_with_grass_dry")
	lib_mg_continental.C["c_dirtbrowngrass"]	= minetest.get_content_id("lib_materials:dirt_with_grass_brown")
	lib_mg_continental.C["c_dirtgreengrass"]	= minetest.get_content_id("lib_materials:dirt_with_grass_green")
	lib_mg_continental.C["c_dirtjunglegrass"]	= minetest.get_content_id("lib_materials:dirt_with_grass_jungle_01")
	lib_mg_continental.C["c_dirtperma"]		= minetest.get_content_id("lib_materials:dirt_permafrost")
	lib_mg_continental.C["c_top"]			= minetest.get_content_id("lib_materials:dirt_with_grass_green")
	lib_mg_continental.C["c_coniferous"]		= minetest.get_content_id("lib_materials:litter_coniferous")
	lib_mg_continental.C["c_rainforest"]		= minetest.get_content_id("lib_materials:litter_rainforest")
	
	lib_mg_continental.C["c_snow"]			= minetest.get_content_id("lib_materials:dirt_with_snow")
	
	lib_mg_continental.C["c_water"]			= minetest.get_content_id("lib_materials:liquid_water_source")
	lib_mg_continental.C["c_river"]			= minetest.get_content_id("lib_materials:liquid_water_river_source")
	lib_mg_continental.C["c_muddy"]			= minetest.get_content_id("lib_materials:liquid_water_river_muddy_source")
	lib_mg_continental.C["c_swamp"]			= minetest.get_content_id("lib_materials:liquid_water_swamp_source")
	
	lib_mg_continental.C["c_lava"]			= minetest.get_content_id("lib_materials:liquid_lava_source")
	
	
	lib_mg_continental.C["c_tree"]			= minetest.get_content_id("lib_ecology:tree_default_trunk")


--##
--##	NOISES
--##

	lib_mg_continental.P = {}
	
	
	lib_mg_continental.P["np_terrain"] = {
		offset = 0,
		scale = lib_mg_continental.mg_noise_scale * lib_mg_continental.mg_world_scale,
		seed = 5934,
		spread = {x = (lib_mg_continental.mg_noise_spread * lib_mg_continental.mg_world_scale), y = (lib_mg_continental.mg_noise_spread * lib_mg_continental.mg_world_scale), z = (lib_mg_continental.mg_noise_spread * lib_mg_continental.mg_world_scale)},
		octaves = lib_mg_continental.mg_noise_octaves,
		persist = lib_mg_continental.mg_noise_persist,
		lacunarity = 2.19,
		--flags = "defaults"
	}
	lib_mg_continental.P["np_cliffs"] = {
		offset = 0,					
		scale = 0.72,
		spread = {x = 180, y = 180, z = 180},
		seed = 78901,
		octaves = 2,
		persist = 0.4,
		lacunarity = 2.11,
	--	flags = "absvalue"
	}
	lib_mg_continental.P["np_heat"] = {
		flags = "defaults",
		lacunarity = 2,
		offset = 50,
		scale = 50,
		spread = {x = (1000 * lib_mg_continental.mg_world_scale), y = (1000 * lib_mg_continental.mg_world_scale), z = (1000 * lib_mg_continental.mg_world_scale)},
		seed = 5349,
		octaves = 3,
		persist = 0.5,
	}
	lib_mg_continental.P["np_heat_blend"] = {
		flags = "defaults",
		lacunarity = 2,
		offset = 0,
		scale = 1.5,
		spread = {x = 8, y = 8, z = 8},
		seed = 13,
		octaves = 2,
		persist = 1,
	}
	lib_mg_continental.P["np_humid"] = {
		flags = "defaults",
		lacunarity = 2,
		offset = 50,
		scale = 50,
		spread = {x = (1000 * lib_mg_continental.mg_world_scale), y = (1000 * lib_mg_continental.mg_world_scale), z = (1000 * lib_mg_continental.mg_world_scale)},
		seed = 842,
		octaves = 3,
		persist = 0.5,
	}
	lib_mg_continental.P["np_humid_blend"] = {
		flags = "defaults",
		lacunarity = 2,
		offset = 0,
		scale = 1.5,
		spread = {x = 8, y = 8, z = 8},
		seed = 90003,
		octaves = 2,
		persist = 1,
	}
	















