

minetest.set_mapgen_setting('mg_name','singlenode',true)
minetest.set_mapgen_setting('flags','nolight',true)
--minetest.set_mapgen_params({mgname="singlenode"})

--local storage = minetest.get_mod_storage()

local P = lib_mg_continental.P
local C = lib_mg_continental.C


	local c_air			= C["c_air"]
	local c_ignore			= C["c_ignore"]

	local c_stone			= C["c_stone"]
	local c_brick			= C["c_brick"]
	local c_block			= C["c_block"]
	local c_cobble			= C["c_cobble"]
	local c_mossy			= C["c_mossy"]
	local c_gravel			= C["c_gravel"]

	local c_desertsandstone		= C["c_desertsandstone"]
	local c_desertstone		= C["c_desertstone"]
	local c_desertstoneblock	= C["c_desertstoneblock"]
	local c_desertstonebrick	= C["c_desertstonebrick"]
	local c_sandstone		= C["c_sandstone"]
	local c_obsidian		= C["c_obsidian"]

	local c_sand			= C["c_sand"]
	local c_desertsand		= C["c_desertsand"]

	local c_dirt			= C["c_dirt"]
	local c_dirtgrass		= C["c_dirtgrass"]
	local c_dirtdrygrass		= C["c_dirtdrygrass"]
	local c_dirtbrowngrass		= C["c_dirtbrowngrass"]
	local c_dirtgreengrass		= C["c_dirtgreengrass"]
	local c_dirtjunglegrass		= C["c_dirtjunglegrass"]
	local c_dirtperma		= C["c_dirtperma"]
	local c_top			= C["c_top"]
	local c_coniferous		= C["c_coniferous"]
	local c_rainforest		= C["c_rainforest"]

	local c_snow			= C["c_snow"]

	local c_water			= C["c_water"]
	local c_river			= C["c_river"]
	local c_muddy			= C["c_muddy"]
	local c_swamp			= C["c_swamp"]

	local c_lava			= C["c_lava"]

	local c_tree			= C["c_tree"]

	local np_terrain		= P["np_terrain"]
	local np_cliffs			= P["np_cliffs"]
	local np_heat			= P["np_heat"]
	local np_heat_blend		= P["np_heat_blend"]
	local np_humid			= P["np_humid"]
	local np_humid_blend		= P["np_humid_blend"]


	--local abs   = math.abs
	local max   = math.max
	local min   = math.min
	--local sqrt  = math.sqrt
	--local floor = math.floor
	--local modf = math.modf
	--local random = math.random

	local mult = lib_mg_continental.mg_world_scale
	local b_mult = lib_mg_continental.mg_biome_scale
	local dist_metric = lib_mg_continental.mg_distance_metric
	local base_max = lib_mg_continental.mg_base_max
	local base_min = lib_mg_continental.mg_base_min
	local base_rng = lib_mg_continental.mg_base_rng


	local v_cscale = 0.05
	local v_pscale = 0.1
	local v_mscale = 0.125
	local v_cmscale = 0.1
	local v_pmscale = 0.2
	local v_mmscale = 0.25
	local v_csscale = 0.2
	local v_psscale = 0.4
	local v_msscale = 0.5



	local nobj_terrain = nil
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


	local mapgen_times = {
		liquid_lighting = {},
		loop2d = {},
		loop3d = {},
		make_chunk = {},
		noisemaps = {},
		preparation = {},
		setdata = {},
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
		--local overlen = sidelen + 5
		--local chulens = {x = overlen, y = overlen, z = 1}
		--local minpos  = {x = x0 - 3, y = z0 - 3}
		--
	
		local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
		data = vm:get_data()
		local a = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
		local csize = vector.add(vector.subtract(maxp, minp), 1)
	
		nobj_terrain = nobj_terrain or minetest.get_perlin_map(np_terrain, csize)
		isln_terrain = nobj_terrain:get_2d_map({x=minp.x,y=minp.z})
	
		nobj_cliffs = nobj_cliffs or minetest.get_perlin_map(np_cliffs, permapdims3d)
		isln_cliffs = nobj_cliffs:get_2d_map({x=minp.x,y=minp.z})
	
		nobj_heatmap = nobj_heatmap or minetest.get_perlin_map(np_heat, permapdims3d)
		nbase_heatmap = nobj_heatmap:get2dMap_flat({x=minp.x,y=minp.z})
		nobj_heatblend = nobj_heatblend or minetest.get_perlin_map(np_heat_blend, permapdims3d)
		nbase_heatblend = nobj_heatblend:get2dMap_flat({x=minp.x,y=minp.z})
		nobj_humiditymap = nobj_humiditymap or minetest.get_perlin_map(np_humid, permapdims3d)
		nbase_humiditymap = nobj_humiditymap:get2dMap_flat({x=minp.x,y=minp.z})
		nobj_humidityblend = nobj_humidityblend or minetest.get_perlin_map(np_humid_blend, permapdims3d)
		nbase_humidityblend = nobj_humidityblend:get2dMap_flat({x=minp.x,y=minp.z})
	
	
		-- Mapgen preparation is now finished. Check the timer to know the elapsed time.
		local t1 = os.clock()
	
		local write = false
		
		local center_of_chunk = { 
			x = maxp.x - lib_mg_continental.half_map_chunk_size, 
			y = maxp.y - lib_mg_continental.half_map_chunk_size, 
			z = maxp.z - lib_mg_continental.half_map_chunk_size
		}
	
		local b_idx, b_dist, b_rise, b_run, b_edge = lib_mg_continental.get_nearest_cell({x = center_of_chunk.x, z = center_of_chunk.z}, dist_metric, 3)
		local b_neighbors = lib_mg_continental.get_cell_neighbors(b_idx)
	
		--minetest.log("NEIGHBORS: " .. dump(b_neighbors))
		--print("NEIGHBORS: " .. dump(b_neighbors))
	
	
	--2D HEIGHTMAP GENERATION
		local index2d = 0
	
		local t_point = lib_mg_continental.points
	
		--local water_table = {}
		local edge_tier = {}
	
		for z = minp.z, maxp.z do
			for x = minp.x, maxp.x do
	
				index2d = (z - minp.z) * csize.x + (x - minp.x) + 1
	
				--local t_edge = ""
				local t_edge = {}
				local cedge = 0
				local pedge = 0
				local medge = 0
				local tedge = 0

				local t_y = 1
				local velevation
				local nelevation

				if lib_mg_continental.mg_type == "voronoi" then
					local c_idx, c_dist, c_rise, c_run, c_edge = lib_mg_continental.get_nearest_cell({x = x, z = z}, dist_metric, 3)
					local p_idx, p_dist, p_rise, p_run, p_edge = lib_mg_continental.get_nearest_cell({x = x, z = z}, dist_metric, 2)
					local m_idx, m_dist, m_rise, m_run, m_edge = lib_mg_continental.get_nearest_cell({x = x, z = z}, dist_metric, 1)

					if (c_edge ~= "") then
						t_edge[c_idx] = c_edge
						--t_edge = c_edge
						cedge = 1
					end
					if (p_edge ~= "") then
						t_edge[p_idx] = p_edge
						--t_edge = p_edge
						pedge = 2
					end
					if (m_edge ~= "") then
						t_edge[m_idx] = m_edge
						--t_edge = m_edge
						medge = 4
					end
					tedge = cedge + pedge + medge

					local mcontinental = (m_dist * v_cscale)
					local pcontinental = (p_dist * v_pscale)
					local ccontinental = (c_dist * v_mscale)
					local vcontinental = (mcontinental + pcontinental + ccontinental)

					local vterrain = (base_rng - vcontinental)
					local vheight = ((base_max - vcontinental) * 0.01)

					velevation = lib_mg_continental.get_terrain_height_hills(vterrain,vheight)
					--velevation = vterrain

					t_y = lib_mg_continental.get_terrain_height_cliffs((velevation),ncliff)
					--t_y = vterrain

				end

				if lib_mg_continental.mg_type == "noise" then 
					local nterrain = isln_terrain[z-minp.z+1][x-minp.x+1]
					local nheight = nterrain * 0.01
					local ncliff = isln_cliffs[z-minp.z+1][x-minp.x+1]

					nelevation = lib_mg_continental.get_terrain_height_hills(nterrain,nheight)

					t_y = lib_mg_continental.get_terrain_height(nelevation,nheight,ncliff)
					--t_y = lib_mg_continental.get_terrain_height_cliffs((nelevation),ncliff)
					--t_y = nelevation
				end
	
				if lib_mg_continental.mg_type == "all" then
					local c_idx, c_dist, c_rise, c_run, c_edge = lib_mg_continental.get_nearest_cell({x = x, z = z}, dist_metric, 3)
					local p_idx, p_dist, p_rise, p_run, p_edge = lib_mg_continental.get_nearest_cell({x = x, z = z}, dist_metric, 2)
					local m_idx, m_dist, m_rise, m_run, m_edge = lib_mg_continental.get_nearest_cell({x = x, z = z}, dist_metric, 1)

					if (c_edge ~= "") then
						t_edge[c_idx] = c_edge
						--t_edge = c_edge
						cedge = 1
					end
					if (p_edge ~= "") then
						t_edge[p_idx] = p_edge
						--t_edge = p_edge
						pedge = 2
					end
					if (m_edge ~= "") then
						t_edge[m_idx] = m_edge
						--t_edge = m_edge
						medge = 4
					end
					tedge = cedge + pedge + medge

					local mcontinental = (m_dist * v_cscale)
					local pcontinental = (p_dist * v_pscale)
					local ccontinental = (c_dist * v_mscale)
					local vcontinental = (mcontinental + pcontinental + ccontinental)

					local vterrain = (base_rng - vcontinental)
					local vheight = ((base_max - vcontinental) * 0.01)

					local nterrain = isln_terrain[z-minp.z+1][x-minp.x+1]
					local nheight = nterrain * 0.01
					local ncliff = isln_cliffs[z-minp.z+1][x-minp.x+1]

					nelevation = lib_mg_continental.get_terrain_height(nterrain,nheight,ncliff)
					--nelevation = lib_mg_continental.get_terrain_height_hills(nterrain,nheight)
					velevation = lib_mg_continental.get_terrain_height_hills(vterrain,vheight)

					t_y = lib_mg_continental.get_terrain_height_cliffs((velevation + nelevation),ncliff)
					--t_y = (velevation + nelevation)
					--t_y = vterrain + nelevation
				end

				if lib_mg_continental.mg_type == "flat" then
					t_y = 5
				end

				--local t_wt = (base_rng - (base_min * 0.5)) - mcontinental
				--water_table[index2d] = t_wt

				lib_mg_continental.heightmap[index2d] = t_y
				--lib_mg_continental.heightmap[index2d] = t_y + (300 * mult)
				lib_mg_continental.edgemap[index2d] = t_edge
				edge_tier[index2d] = tedge
			end
		end
	
		local t2 = os.clock()
	
	--
	--2D HEIGHTMAP RENDER
		local index2d = 0
		for z = minp.z, maxp.z do
			for y = minp.y, maxp.y do
				for x = minp.x, maxp.x do
				 
					index2d = (z - minp.z) * csize.x + (x - minp.x) + 1   
					local ivm = a:index(x, y, z)
	
					local theight = lib_mg_continental.heightmap[index2d]
					local t_edge = lib_mg_continental.edgemap[index2d]
					local tedge = edge_tier[index2d]
					--local twatertable = water_table[index2d]
	
					local fill_depth = 4
					local top_depth = 1
	
					local t_air = c_air
					local t_ignore = c_ignore
					local t_top = c_dirtgrass
					local t_dirt = c_dirt
					local t_stone = c_stone
					local t_water = c_water
					local t_water_top = c_water
					local t_river = c_river
	
	--BUILD BIOMES.
	--
	
					if y <= theight + 1 then
		
						local nheat = nbase_heatmap[index2d] + nbase_heatblend[index2d]
						local nhumid = nbase_humiditymap[index2d] + nbase_humidityblend[index2d]
	
						local t_name = lib_mg_continental.get_biome_name(nheat,nhumid,y)
	
						local b_name, b_cid, b_top, b_top_d, b_fill, b_fill_d, b_stone, b_water_top, b_water_top_d, b_water, b_river, b_riverbed, b_riverbed_d, b_caveliquid, b_dungeon, b_dungeonalt, b_dungeonstair, b_dust, b_ymin, b_ymax, b_heat, b_humid = unpack(lib_mg_continental.biome_info[t_name]:split("|", false))
	
						t_stone = b_stone
						t_dirt = b_fill
						fill_depth = tonumber(b_fill_d) or 6
						t_top = b_top
						top_depth = tonumber(b_top_d) or 1
						t_water_top = b_water_top
						t_river = b_river
		
						lib_mg_continental.biomemap[index2d] = t_name
	
					end
	
					--if t_edge  ~= "" then
					--	c_top = c_obsidian
					--end
					--if t_edge[1] ~= "" then
					if t_edge[1] then
						if tedge == 1 then
							t_top = c_stone
						elseif tedge == 2 then
							t_top = c_desertstone
						elseif tedge == 3 then
							t_top = c_sandstone
						elseif tedge == 4 then
							t_top = c_desertsandstone
						elseif tedge == 5 then
							t_top = c_block
						elseif tedge == 6 then
							t_top = c_brick
						elseif tedge == 7 then
							t_top = c_obsidian
						end
					end
	
					--if y > 0 then
					--	if twatertable > theight then
					--		c_top = c_river
					--	end
					--end
	
	
	--NODE PLACEMENT FROM HEIGHTMAP
	--
					if y < (theight - (fill_depth + top_depth)) then
						data[ivm] = t_stone
						write = true
					elseif y >= (theight - (fill_depth + top_depth)) and y < (theight - top_depth) then
						data[ivm] = t_dirt
						write = true
					elseif y >= (theight - top_depth) and y <= theight then
						data[ivm] = t_top
						write = true
					elseif y > theight and y <= 1 then
						data[ivm] = t_water
						write = true
					else
						data[ivm] = t_air
						write = true
					end
	
	
				end
			end
		end
		
		local t3 = os.clock()
	
		if write then
			vm:set_data(data)
		end
	
		local t4 = os.clock()
		
		if write then
	
			minetest.generate_ores(vm,minp,maxp)
			minetest.generate_decorations(vm,minp,maxp)
				
			vm:set_lighting({day = 0, night = 0})
			vm:calc_lighting()
			vm:update_liquids()
		end
	
		local t5 = os.clock()
	
		if write then
			vm:write_to_map()
		end
	
		local t6 = os.clock()
	
		-- Print generation time of this mapchunk.
		local chugent = math.ceil((os.clock() - t0) * 1000)
		print ("[lib_mg_continental_mg_continental] Mapchunk generation time " .. chugent .. " ms")
	
		table.insert(mapgen_times.noisemaps, 0)
		table.insert(mapgen_times.preparation, t1 - t0)
		table.insert(mapgen_times.loop2d, t2 - t1)
		table.insert(mapgen_times.loop3d, t3 - t2)
		table.insert(mapgen_times.setdata, t4 - t3)
		table.insert(mapgen_times.liquid_lighting, t5 - t4)
		table.insert(mapgen_times.writing, t6 - t5)
		table.insert(mapgen_times.make_chunk, t6 - t0)
	
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

		lib_mg_continental.save_neighbors()
		--lib_mg_continental.save(lib_mg_continental.neighbors, "lib_mg_continental_data_cell_neighbors.txt")

		if #mapgen_times.make_chunk == 0 then
			return
		end
	
		local average, standard_dev
		minetest.log("lib_mg_continental_mg_continental lua Mapgen Times:")
	
		average = mean(mapgen_times.liquid_lighting)
		minetest.log("  liquid_lighting: - - - - - - - - - - - -  "..average)
	
		average = mean(mapgen_times.loop2d)
		minetest.log("  loops: - - - - - - - - - - - - - - - - -  "..average)
	
		average = mean(mapgen_times.loop3d)
		minetest.log("  loops: - - - - - - - - - - - - - - - - -  "..average)
	
		average = mean(mapgen_times.make_chunk)
		minetest.log("  makeChunk: - - - - - - - - - - - - - - -  "..average)
	
		average = mean(mapgen_times.noisemaps)
		minetest.log("  noisemaps: - - - - - - - - - - - - - - -  "..average)
	
		average = mean(mapgen_times.preparation)
		minetest.log("  preparation: - - - - - - - - - - - - - -  "..average)
	
		average = mean(mapgen_times.setdata)
		minetest.log("  writing: - - - - - - - - - - - - - - - -  "..average)
	
		average = mean(mapgen_times.writing)
		minetest.log("  writing: - - - - - - - - - - - - - - - -  "..average)
	end)


