

local function lerp(noise_a, noise_b, n_mod)
	return noise_a * (1 - n_mod) + noise_b * n_mod
end

local function steps(noise, h)
	local w = math.abs(noise)				--n_base
	local k = math.floor(h / w)
	local f = (h - k * w) / w
	local s = math.min(2 * f, 1.0)
	return (k + s) * w
end

local function bias(noise, bias)
	return (noise / ((((1.0 / bias) - 2.0) * (1.0 - noise)) + 1.0))
end

local function gain(noise, gain)
	if noise < 0.5 then
		return bias(noise * 2.0, gain) / 2.0
	else
		return bias(noise * 2.0 - 1.0, 1.0 - gain) / 2.0 + 0.5
	end
end








local function get_terrain_height(theight,hheight,cheight)
		-- parabolic gradient
	if theight > 0 and theight < shelf_thresh then
		theight = theight * (theight*theight/(shelf_thresh*shelf_thresh)*0.5 + 0.5)
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

local function get_terrain_height_cliffs(theight,cheight)
		-- cliffs
	if theight > 1 and theight < cliffs_thresh then 
		local clifh = math.max(math.min(cheight,1),0) 
		if clifh > 0 then
			clifh = -1*(clifh-1)*(clifh-1) + 1
			theight = theight + (cliffs_thresh-theight) * clifh * ((theight<2) and theight-1 or 1)
		end
	end
	return theight
end

local function get_terrain_height_hills(theight,hheight)
		-- hills
	if theight > hills_thresh then
		theight = theight + math.max((theight-hills_thresh) * hheight,0)
	end
	return theight
end




local function get_terrain_height_adjustable_all(theight,hheight,cheight,shlf_thresh,hlls_thresh)
		-- parabolic gradient
	if theight > 0 and theight < shlf_thresh then
		theight = theight * (theight*theight/(shlf_thresh*shlf_thresh)*0.5 + 0.5)
	end	
		-- hills
	if theight > hlls_thresh then
		theight = theight + math.max((theight-hlls_thresh) * hheight,0)
		-- cliffs
	elseif theight > 1 and theight < hlls_thresh then 
		local clifh = math.max(math.min(cheight,1),0) 
		if clifh > 0 then
			clifh = -1*(clifh-1)*(clifh-1) + 1
			theight = theight + (hlls_thresh-theight) * clifh * ((theight<2) and theight-1 or 1)
		end
	end
	return theight
end

local function get_terrain_height_adjustable_cliffs(theight,cheight,clff_thresh)
		-- cliffs
	if theight > 1 and theight < clff_thresh then 
		local clifh = math.max(math.min(cheight,1),0) 
		if clifh > 0 then
			clifh = -1*(clifh-1)*(clifh-1) + 1
			theight = theight + (clff_thresh-theight) * clifh * ((theight<2) and theight-1 or 1)
		end
	end
	return theight
end

local function get_terrain_height_adjustable_hills(theight,hheight,hlls_thresh)
		-- hills
	if theight > hlls_thresh then
		theight = theight + math.max((theight-hlls_thresh) * hheight,0)
		--theight = theight + math.max((theight-hlls_thresh) + hheight,0)
	end
	return theight
end



local function get_terrain_height_shelf_adjustable_hills(theight,hheight,cheight,hlls_thresh)
		-- parabolic gradient
	if theight > 0 and theight < shelf_thresh then
		theight = theight * (theight*theight/(shelf_thresh*shelf_thresh)*0.5 + 0.5)
	end	
		-- hills
	if theight > hlls_thresh then
		theight = theight + math.max((theight-hlls_thresh) * hheight,0)
		-- cliffs
	elseif theight > 1 and theight < hlls_thresh then 
		local clifh = math.max(math.min(cheight,1),0) 
		if clifh > 0 then
			clifh = -1*(clifh-1)*(clifh-1) + 1
			theight = theight + (hlls_thresh-theight) * clifh * ((theight<2) and theight-1 or 1)
		end
	end
	return theight
end

local function get_terrain_height_cliffs_hills(theight,hheight,cheight)
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






local function make_map(base, direction, size)

	if not base or not size or not direction then
		return
	end

	-- Start time of 2d map generation.
	local t0 = os.clock()
	minetest.log("[lib_mapgen_mg_custom_biomes] 2d map generation start")
	
	local temp_map = {}

	for i_z = (1-(size/2)), (size-(size/2)) do
		temp_map[i_z] = {}
		for i_x = (1-(size/2)), (size-(size/2)) do
			--local x_rand = math.random(1, 10)
			local tectonic_height = mg_custom_data.base_tectonicmap[i_z][i_x].closest_dist
			local base_height = 0

			if direction == 0 then
				base_height = tectonic_height
			elseif direction == 1 then
				base_height = tectonic_height
			elseif direction == 2 then
				base_height = 1 / tectonic_height
			elseif direction == 3 then
				base_height = tectonic_height / 100
			elseif direction == 4 then
				base_height = tectonic_height * (1 / map_scale)
			elseif direction == 5 then
				base_height = base + (base * (1 / tectonic_height))
			elseif direction == 6 then
				base_height = (tectonic_height / base) / base
			elseif direction == 7 then
				base_height = base + ((tectonic_height / base) / base)
			else
				base_height = base * (base*base/(tectonic_height*tectonic_height)*0.5 + 0.5)
			end

			temp_map[i_z][i_x] = base_height

		end
	end

	local t1 = os.clock()
	minetest.log("[lib_mapgen_mg_custom_biomes] 2d map generation time " .. (t1-t0) .. " ms")

	return temp_map

end




