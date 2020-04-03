



lib_mg_continental.mg_custom_data = {}

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
	local size = 60000
	local size_offset = size * 0.1
	local size_half = size * 0.5

	local t_map_cell = {}
	
	if cells > 0 then
		local temp_points = "#Index|Pos.Z|Pos.X\n"
		v_points = {}
		for i_c = 1, cells do
			local t_pt = {x = (math.random(1 + size_offset, size - size_offset) - size_half), z = (math.random(1 + size_offset, size - size_offset) - size_half)}
			v_points[i_c] = t_pt
			temp_points = temp_points .. i_c .. "|" .. t_pt.z .. "|" .. t_pt.x .. "\n"
		end
		lib_mg_continental.save_csv(temp_points, "lib_mg_continental_data_points.txt")
		minetest.log("[lib_mg_continental_voronoi] Voronoi Cell Point List:\n" .. temp_points .. "")
	elseif cells == 0 then
		v_points = {}
		for i, point in ipairs(mg_custom_data.base_points) do
			local idx, p_z, p_x = unpack(point)
			local t_pt = {x = tonumber(p_x), z = tonumber(p_z)}
			v_points[tonumber(idx)] = t_pt
		end
		minetest.log("[lib_mg_continental_voronoi] Voronoi Cell Point List loaded from file.")
	else
		
	end

	-- Random Points generation finished. Check the timer to know the elapsed time.
	local t1 = os.clock()
	minetest.log("[lib_mg_continental_voronoi] Random Points generation time " .. (t1-t0) .. " ms")

end

function lib_mg_continental.get_cell_data(cells, size)

	local t0 = os.clock()
	minetest.log("[lib_mg_continental_voronoi] Cell Data (Cells, Neighbors, Midpoints) generation start")

	local temp_cells = "#Index|LinkIdx|Pos.Z|Pos.X|ClosestIndex|ClosestPosZ|ClosestPosX\n"
	local temp_neighbors = "#CellIndex|LinkIdx|CellPosZ|CellPosX|ClosestNeighborIndex|ClosestNeighborPosZ|ClosestNeighborPosX|ClosestNeighborDist|ClosestNeighborEDist|ClosestNeighborMDist|ClosestNeighborADist|NeighborMidPosZ|NeighborMidPosX\n"
	local temp_midpoints = "#LinkIdx|Pos.Z|Pos.X|DistBetweenCells|Cell1Idx|Cell1Dist|Cell2Idx|Cell2Dist|\n"

	for i, pos in pairs(v_points) do

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
			if i ~= k then
				local neighbor_add = false
				e_dist = lib_mg_continental.get_euclid_distance({x=pt.x,y=pt.z}, {x=pos.x,y=pos.z})
				--t_dist = get_euclidean2_distance({x=pt.x,y=pt.z}, {x=pos.x,y=pos.z})
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
				temp_midpoints = temp_midpoints .. i .. "-" .. k .. "|" .. m_point_z .. "|" .. m_point_x .. "|" .. get_distance({x=pt.x,y=pt.z}, {x=pos.x,y=pos.z}) .. "|" .. i .. "|" .. get_distance({x=m_point_x,y=m_point_z}, {x=pos.x,y=pos.z}) .. "|" .. k .. "|" .. get_distance({x=pt.x,y=pt.z}, {x=m_point_x,y=m_point_z}) .. "\n"

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

				local edge_add = false

				e_dist = lib_mg_continental.get_euclid_distance({x=i_x,y=i_z}, {x=pos.x,y=pos.z})
				--this_dist = get_euclidean2_distance({{x=i_x,y=i_z}, {x=pos.x,y=pos.z})
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

				local edge_add = false

				e_dist = lib_mg_continental.get_euclid_distance({x=i_x,y=i_z}, {x=pos.x,y=pos.z})
				--this_dist = get_euclidean2_distance({{x=i_x,y=i_z}, {x=pos.x,y=pos.z})
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
lib_mg_continental.mg_custom_data.base_points = lib_mg_continental.load_csv("|", "lib_mg_continental_data_points.txt")
lib_mg_continental.mg_custom_data.base_cells = lib_mg_continental.load_csv("|", "lib_mg_continental_data_cells.txt")
lib_mg_continental.mg_custom_data.base_cellmap = lib_mg_continental.load("lib_mg_continental_data_cellmap.txt")
lib_mg_continental.mg_custom_data.base_midpoints = lib_mg_continental.load_csv("|", "lib_mg_continental_data_midpoints.txt")
lib_mg_continental.mg_custom_data.base_tectonicmap = lib_mg_continental.load("lib_mg_continental_data_tectonicmap.txt")
lib_mg_continental.mg_custom_data.base_edgemap = lib_mg_continental.load("lib_mg_continental_data_edgemap.txt")
--mg_custom_data.base_edgemap = lib_mg_continental.load_csv("|", "lib_mg_continental_data_edges.txt")

if not (lib_mg_continental.mg_custom_data.base_cellmap) then
	if (lib_mg_continental.mg_custom_data.base_midpoints == nil) then
		if (lib_mg_continental.mg_custom_data.base_points == nil) then
			lib_mg_continental.mg_custom_data.base_points = lib_mg_continental.get_points(voronoi_cells, map_scale)
			lib_mg_continental.mg_custom_data.base_cellmap, lib_mg_continental.mg_custom_data.base_midpoints, lib_mg_continental.mg_custom_data.base_neighbors = lib_mg_continental.get_cell_data(voronoi_cells, map_scale)
			--mg_custom_data.base_cellmap, mg_custom_data.base_midpoints, mg_custom_data.base_neighbors = make_voronoi(voronoi_cells, map_scale)
			lib_mg_continental.save(lib_mg_continental.mg_custom_data.base_cellmap, "lib_mg_continental_data_cellmap.txt")
		else
			lib_mg_continental.mg_custom_data.base_cellmap, lib_mg_continental.mg_custom_data.base_midpoints, lib_mg_continental.mg_custom_data.base_neighbors = lib_mg_continental.get_cell_data(0, map_scale)
			--mg_custom_data.base_cellmap, mg_custom_data.base_midpoints, mg_custom_data.base_neighbors = make_voronoi(0, map_scale)
			lib_mg_continental.save(lib_mg_continental.mg_custom_data.base_cellmap, "lib_mg_continental_data_cellmap.txt")
		end
	end
end
if not (lib_mg_continental.mg_custom_data.base_tectonicmap) or not (lib_mg_continental.mg_custom_data.base_edgemap) then
	lib_mg_continental.mg_custom_data.base_tectonicmap, lib_mg_continental.mg_custom_data.base_edgemap = lib_mg_continental.get_maps
	--mg_custom_data.base_tectonicmap, mg_custom_data.base_edgemap = make_voronoi_maps(map_scale)
	lib_mg_continental.save(lib_mg_continental.mg_custom_data.base_tectonicmap, "lib_mg_continental_data_tectonicmap.txt")
	lib_mg_continental.save(lib_mg_continental.mg_custom_data.base_edgemap, "lib_mg_continental_data_edgemap.txt")
end
minetest.log("[lib_mg_continental_voronoi] Custom Data Load / Gen End")



