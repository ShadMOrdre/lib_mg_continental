
--local hills_offset = lib_mg_continental.hills_offset
--local hills_thresh = lib_mg_continental.hills_thresh
--local shelf_thresh = lib_mg_continental.shelf_thresh
--local cliffs_thresh = lib_mg_continental.cliffs_thresh

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

