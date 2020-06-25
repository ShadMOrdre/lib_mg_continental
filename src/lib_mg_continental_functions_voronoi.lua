	

local mult = lib_mg_continental.mg_world_scale
local dist_metric = lib_mg_continental.mg_distance_metric
local map_size = lib_mg_continental.mg_map_size
local voronoi_recursion_1 = lib_mg_continental.voronoi_recursion_1
local voronoi_recursion_2 = lib_mg_continental.voronoi_recursion_2
local voronoi_recursion_3 = lib_mg_continental.voronoi_recursion_3
local base_min = lib_mg_continental.mg_base_min
local base_max = lib_mg_continental.mg_base_max
local base_rng = lib_mg_continental.mg_base_rng
local easing_factor = lib_mg_continental.mg_easing_factor
local base_height = lib_mg_continental.mg_base_height
	
--##
--##	GET NEAREST CELL
--##

	function lib_mg_continental.get_nearest_cell_v(pos, dist_type, tier)
	
		if not pos then
			return
		end
	
		local d_type
		if not dist_type then
			d_type = dist_metric
		else
			d_type = dist_type
		end
		if not tier then
			tier = 3
		end

		local t_cell_dist = {}
	
		local closest_cell_idx = 0
		local closest_cell_dist = 0
		local last_closest_idx2 = 0
		local last_dist2
		local last_closest_idx = 0
		local last_dist
		local this_dist
		local t_x
		local t_z
		local edge = {}
		--local edge = ""
	
		for i_p, i_point in ipairs(lib_mg_continental.points) do
	
			if i_point.tier == tier then
	
				t_x = pos.x-i_point.x
				t_z = pos.z-i_point.z
	
				this_dist = lib_mg_continental.get_dist(t_x, t_z, d_type)

				if last_dist then
					if last_dist > this_dist then
						closest_cell_idx = i_p
						closest_cell_dist = this_dist
						last_closest_idx = i_p
						last_dist = this_dist
					elseif last_dist == this_dist then
						closest_cell_idx = last_closest_idx
						closest_cell_dist = this_dist
						edge[i] = last_closest_idx
						--edge = tostring("" .. i_p .. "-" .. last_closest_idx .. "")
					end
				else
					closest_cell_idx = i_p
					closest_cell_dist = this_dist
					last_closest_idx = i_p
					last_dist = this_dist
					--last_closest_idx2 = i_p
					--last_dist2 = this_dist
				end
			end
		end
	
		return closest_cell_idx, closest_cell_dist, t_z, t_x, edge
	
	end
	
	function lib_mg_continental.get_nearest_cell(pos, dist_type, tier)
	
		if not pos then
			return
		end
	
		local d_type
		if not dist_type then
			d_type = dist_metric
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
		local t_x
		local t_z
		--local edge = {}
		local edge = ""
	
		for i, point in ipairs(lib_mg_continental.points) do
	
			if point.tier == tier then
	
				t_x = pos.x-point.x
				t_z = pos.z-point.z
	
				this_dist = lib_mg_continental.get_dist(t_x, t_z, d_type)
		
				if last_dist then
					if last_dist > this_dist then
						closest_cell_idx = i
						closest_cell_dist = this_dist
						last_dist = this_dist
						last_closest_idx = i
					elseif last_dist == this_dist then
						closest_cell_idx = last_closest_idx
						closest_cell_dist = this_dist
						--edge[i] = last_closest_idx
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
	
		return closest_cell_idx, closest_cell_dist, t_z, t_x, edge
	
	end
	
	function lib_mg_continental.get_nearest_cell_3d_alt(pos, dist_type, tier)
	
		if not pos then
			return
		end
	
		local d_type
		if not dist_type then
			d_type = dist_metric
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
	
	
--##
--##	GET NEAREST MIDPOINT
--##

	function lib_mg_continental.get_nearest_midpoint(pos, cell_neighbors)
	
		if not pos then
			return
		end
	
		local d_type = dist_metric
	
		local c_midpoint
		local m_dist
		local this_dist
		local c_z
		local c_x
		local last_dist
	
		for i, i_neighbor in pairs(cell_neighbors) do
	
			t_x = pos.x-i_neighbor.m_x
			t_z = pos.z-i_neighbor.m_z
	
			this_dist = lib_mg_continental.get_dist(t_x, t_z, d_type)
	
			if last_dist then
				if last_dist >= this_dist then
					last_dist = this_dist
					c_midpoint = i
					c_z =  i_neighbor.m_z
					c_x = i_neighbor.m_x
				end
			else
					last_dist = this_dist
			end
		end
	
		return c_midpoint, c_z, c_x
	
	end


--##
--##	GET CELL NEIGHBORS
--##

	function lib_mg_continental.get_cell_neighbors(cell_idx)
	
	
		--local temp_neighbors = "#Cell_Index|Neighbor_Index|Midpoint_Zpos|Midpoint_Xpos|CellMidpoint_ZDistance|CellMidpoint_XDistance\n"
	
		local curr_cell = lib_mg_continental.points[cell_idx]
		local t_neighbors = {}
	
		if lib_mg_continental.neighbors[cell_idx] then

			t_neighbors = lib_mg_continental.neighbors[cell_idx]

		else

			lib_mg_continental.neighbors[cell_idx] = {}

			for i, i_point in ipairs(lib_mg_continental.points) do
	
				--local m_idx = "" .. cell_idx .. "-" .. i .. ""
	
				if i_point.tier == curr_cell.tier then
		
					local t_mid_x, t_mid_z
					local t_mid_cell
					local neighbor_add = false
		
					if i ~= cell_idx then
			
						--temp_neighbors = temp_neighbors .. "#C_Idx|N_Idx|M_Z|M_X|CM_ZD|CM_XD\n"
			
						t_mid_x, t_mid_z = lib_mg_continental.get_midpoint({x = i_point.x, z = i_point.z}, {x = curr_cell.x, z = curr_cell.z})
		
						t_mid_cell = lib_mg_continental.get_nearest_cell({x = t_mid_x, z = t_mid_z}, dist_metric, curr_cell.tier)
		
						if (t_mid_cell == i) or (t_mid_cell == cell_idx) then
							neighbor_add = true
						end
		
					end
		
					if neighbor_add == true then
		
						--m_idx = "" .. cell_idx .. "-" .. i .. ""
		
						lib_mg_continental.neighbors[cell_idx][i] = {}
						lib_mg_continental.neighbors[cell_idx][i].m_z = t_mid_z
						lib_mg_continental.neighbors[cell_idx][i].m_x = t_mid_x
						lib_mg_continental.neighbors[cell_idx][i].cm_zd = curr_cell.z - t_mid_z
						lib_mg_continental.neighbors[cell_idx][i].cm_xd = curr_cell.x - t_mid_x

						t_neighbors = lib_mg_continental.neighbors[cell_idx]

						--t_neighbors[cell_idx] = {}
						--t_neighbors[cell_idx].[i] = {}
						--t_neighbors[cell_idx].[i].m_z = t_mid_z
						--t_neighbors[cell_idx].[i].m_x = t_mid_x
						--t_neighbors[cell_idx].[i].cm_zd = curr_cell.z - t_mid_z
						--t_neighbors[cell_idx].[i].cm_xd = curr_cell.x - t_mid_x

						--t_neighbors[m_idx] = {}
						--t_neighbors[m_idx].c_i = cell_idx
						--t_neighbors[m_idx].n_i = i
						--t_neighbors[m_idx].m_z = t_mid_z
						--t_neighbors[m_idx].m_x = t_mid_x
						--t_neighbors[i].cm_zd = curr_cell.z - t_mid_z
						--t_neighbors[i].cm_xd = curr_cell.x - t_mid_x
		
						--temp_neighbors = temp_neighbors .. cell_idx .. "|" .. i .. "|" .. t_mid_z .. "|" .. t_mid_x
						--	 .. "|" .. (curr_cell.z - t_mid_z) .. "|" .. (curr_cell.x - t_mid_x)
					end
				end
		
				--temp_neighbors = temp_neighbors .. "#" .. "\n"
			end
		end
	
		--lib_mg_continental.save_csv(temp_neighbors, "lib_mg_continental_data_neighbors.txt")
	
		return t_neighbors
	
	end

	function lib_mg_continental.get_all_neighbors()

		for i_p, i_point in ipairs(lib_mg_continental.points) do

			lib_mg_continental.get_cell_neighbors(i_p)

		end

	end
	
	
	
--##
--##	GET FURTHEST CELL
--##

	function lib_mg_continental.get_farthest_cell(pos, dist_type, tier)
	
		if not pos then
			return
		end
	
		local d_type
		if not dist_type then
			d_type = dist_metric
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
				end
		
				if last_dist then
					if last_dist < this_dist then
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





--##
--##	GENERATE VORONOI POINTS (2D)
--##

	function lib_mg_continental.make_voronoi_recursive_lite(cells_x, cells_y, cells_z, size, dist_type)
	
		if not cells_x or not cells_y or not cells_z or not size then
			return
		end
	
		local d_type
		if dist_type and (dist_type ~= "") then
			d_type = dist_type
		else
			d_type = dist_metric
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
			lib_mg_continental.points[v_idx].z = m_pt_z * mult
			lib_mg_continental.points[v_idx].x = m_pt_x * mult
	
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
			lib_mg_continental.points[v_idx].z = p_pt_z * mult
			lib_mg_continental.points[v_idx].x = p_pt_x * mult
	
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
			lib_mg_continental.points[v_idx].z = c_pt_z * mult
			lib_mg_continental.points[v_idx].x = c_pt_x * mult
	
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
	
--##
--##	GENERATE VORONOI POINTS (3D)
--##

	function lib_mg_continental.make_voronoi_recursive_3d_lite(cells_x, cells_y, cells_z, size, dist_type)
	
		if not cells_x or not cells_y or not cells_z or not size then
			return
		end
	
		local d_type
		if dist_type and (dist_type ~= "") then
			d_type = dist_type
		else
			d_type = dist_metric
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
	
--##
--##	LOAD VORONOI POINTS (2D)
--##

	function lib_mg_continental.load_points_lite()
	
		local t_points
		--local t_scale = mult
	
		if lib_mg_continental.mg_voronoi_defaults == true then
			t_points = lib_mg_continental.load_defaults_csv("|", "lib_mg_continental_data_points.txt")
		end
	
		if (t_points == nil) then
			t_points = lib_mg_continental.load_csv("|", "lib_mg_continental_data_points.txt")
		end
	
		if (t_points == nil) then
	
			minetest.log("[lib_mg_continental] Voronoi Cell Points file not found.  Using randomly generated points.")
			print("[lib_mg_continental] Voronoi Cell Points file not found.  Using randomly generated points.")
	
			--if lib_mg_continental.voronoi_type == "single" then
			--	lib_mg_continental.get_points(voronoi_cells, map_size)
			--else
				--lib_mg_continental.get_points2(voronoi_recursion_1, voronoi_recursion_2, voronoi_recursion_3, map_size)
				lib_mg_continental.make_voronoi_recursive_lite(voronoi_recursion_1, voronoi_recursion_2, voronoi_recursion_3, map_size, dist_metric)
			--end
	
		else
	
			for i_p, p_point in ipairs(t_points) do
		
				local idx, p_z, p_x, p_tier = unpack(p_point)
	
				lib_mg_continental.points[tonumber(idx)] = {}
		
				lib_mg_continental.points[tonumber(idx)].z = (tonumber(p_z) * mult)
				lib_mg_continental.points[tonumber(idx)].x = (tonumber(p_x) * mult)

				lib_mg_continental.points[tonumber(idx)].tier = tonumber(p_tier)
		
			end
	
			minetest.log("[lib_mg_continental] Voronoi Cell Points loaded from file.")
	
		end
	end
	
--##
--##	LOAD VORONOI POINTS (3D)
--##

	function lib_mg_continental.load_points_3d_lite()
	
		local t_points
		--local t_scale = mg_scale_factor
	
		if lib_mg_continental.mg_voronoi_defaults == true then
			t_points = lib_mg_continental.load_defaults_csv("|", "lib_mg_continental_data_points.txt")
		end
	
		if (t_points == nil) then
			t_points = lib_mg_continental.load_csv("|", "lib_mg_continental_data_points.txt")
		end
	
		if (t_points == nil) then
	
			minetest.log("[lib_mg_continental] Voronoi Cell Points file not found.  Using randomly generated points.")
			print("[lib_mg_continental] Voronoi Cell Points file not found.  Using randomly generated points.")
	
			--if lib_mg_continental.voronoi_type == "single" then
			--	lib_mg_continental.get_points(voronoi_cells, map_size)
			--else
				--lib_mg_continental.get_points2(voronoi_recursion_1, voronoi_recursion_2, voronoi_recursion_3, map_size)
				lib_mg_continental.make_voronoi_recursive_3d_lite(voronoi_recursion_1, voronoi_recursion_2, voronoi_recursion_3, map_size, dist_metric)
			--end
	
		else
	
			for i_p, p_point in ipairs(t_points) do
		
				local idx, p_z, p_y, p_x, p_tier = unpack(p_point)
	
				lib_mg_continental.points[tonumber(idx)] = {}
		
				lib_mg_continental.points[tonumber(idx)].z = (tonumber(p_z) * mult)
				lib_mg_continental.points[tonumber(idx)].y = (tonumber(p_y) * mult)
				lib_mg_continental.points[tonumber(idx)].x = (tonumber(p_x) * mult)

				lib_mg_continental.points[tonumber(idx)].tier = tonumber(p_tier)
		
			end
	
			minetest.log("[lib_mg_continental] Voronoi Cell Points loaded from file.")
	
		end
	end
	
--##
--##	LOAD CELL NEIGHBORS (2D)
--##

	function lib_mg_continental.load_neighbors()
	
		local t_neighbors
	
		if lib_mg_continental.mg_voronoi_defaults == true then
			t_neighbors = lib_mg_continental.load_defaults_csv("|", "lib_mg_continental_data_neighbors.txt")
		end
	
		if (t_neighbors == nil) then
			t_neighbors = lib_mg_continental.load_csv("|", "lib_mg_continental_data_neighbors.txt")
		end
	
		if (t_neighbors == nil) then
	
			--minetest.log("[lib_mg_continental] Voronoi Cell Points file not found.  Using randomly generated points.")
			--print("[lib_mg_continental] Voronoi Cell Points file not found.  Using randomly generated points.")
	
			if lib_mg_continental.voronoi_type == "single" then
				lib_mg_continental.get_all_neighbors()
			--else
				--lib_mg_continental.get_points2(voronoi_recursion_1, voronoi_recursion_2, voronoi_recursion_3, map_size)
			--	lib_mg_continental.make_voronoi_recursive_lite(voronoi_recursion_1, voronoi_recursion_2, voronoi_recursion_3, map_size, dist_metric)
			end
	
		else
	
			for i_p, p_neighbors in ipairs(t_neighbors) do
		
				local c_i, n_i, m_z, m_x, cm_zd, cm_xd = unpack(p_neighbors)
	
				if not (lib_mg_continental.neighbors[tonumber(c_i)]) then
					lib_mg_continental.neighbors[tonumber(c_i)] = {}
				end

				lib_mg_continental.neighbors[tonumber(c_i)][tonumber(n_i)] = {}
				lib_mg_continental.neighbors[tonumber(c_i)][tonumber(n_i)].m_z = tonumber(m_z)
				lib_mg_continental.neighbors[tonumber(c_i)][tonumber(n_i)].m_x = tonumber(m_x)
				lib_mg_continental.neighbors[tonumber(c_i)][tonumber(n_i)].cm_zd = tonumber(cm_zd)
				lib_mg_continental.neighbors[tonumber(c_i)][tonumber(n_i)].cm_xd = tonumber(cm_xd)
		
			end
	
			minetest.log("[lib_mg_continental] Voronoi Cell Neighbors loaded from file.")
	
		end
	end

	function lib_mg_continental.save_neighbors()

		local temp_neighbors = "#Cell_Index|Neighbor_Index|Midpoint_Zpos|Midpoint_Xpos|CellMidpoint_ZDistance|CellMidpoint_XDistance\n"
		
		--minetest.log("NEIGHBORS: " .. dump(lib_mg_continental.neighbors))
		--print("NEIGHBORS: " .. dump(lib_mg_continental.neighbors))

		for i_c, i_cell in pairs(lib_mg_continental.neighbors) do

			temp_neighbors = temp_neighbors .. "#C_I|N_I|M_Z|M_X|CM_ZD|CM_XD\n"

			--minetest.log("i_cell: " .. dump(i_cell))
			--print("i_cell: " .. dump(i_cell))
	
			for i_n, i_neighbor in pairs(i_cell) do

				temp_neighbors = temp_neighbors .. i_c .. "|" .. i_n .. "|" .. i_neighbor.m_z .. "|" .. i_neighbor.m_x .. "|" .. i_neighbor.cm_zd .. "|" .. i_neighbor.cm_xd .. "\n"

			end

			temp_neighbors = temp_neighbors .. "#" .. "\n"

		end

		lib_mg_continental.save_csv(temp_neighbors, "lib_mg_continental_data_neighbors.txt")
	
	end


	
--##
--##	LOAD VORONOI DATA (2D)
--##

	minetest.log("[lib_mg_continental ] Voronoi Data Processing ...")

	lib_mg_continental.load_points_lite()
	--lib_mg_continental.load_points_3d_lite()

	--lib_mg_continental.neighbors = lib_mg_continental.load("lib_mg_continental_data_cell_neighbors.txt")
	--if not (lib_mg_continental.neighbors) then
	--	lib_mg_continental.neighbors = {}
	--end
	lib_mg_continental.load_neighbors()

	minetest.log("[lib_mg_continental] Voronoi Data Processing Completed.")

	minetest.log("[lib_mg_continental] Base Max:" .. base_max .. ";  Base Min:" .. base_min .. ";  Base Range:" .. base_rng .. ";  Ease Factor:" .. easing_factor .. ";")
	print("[lib_mg_continental] Base Max:" .. base_max .. ";  Base Min:" .. base_min .. ";  Base Range:" .. base_rng .. ";  Ease Factor:" .. easing_factor .. ";")

	minetest.log("[lib_mg_continental] Base Height:" .. base_height)
	print("[lib_mg_continental] Base Height:" .. base_height)















