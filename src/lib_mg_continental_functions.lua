

--##
--##	CONSTANTS, LOCALIZED FUNCTIONS
--##

	local abs   = math.abs
	local max   = math.max
	local min   = math.min
	--local sqrt  = math.sqrt
	local floor = math.floor
	--local modf = math.modf
	--local random = math.random
	
	
	local mg_golden_ratio = ((1 + (5^0.5)) * 0.5)				-- is 1.61803398875
	local euler_mascheroni_const = 0.5772156649
	local euler_number = 2.7182818284
	
	--##		local mg_golden_ratio = ((1 + (5^0.5)) * 0.5)				-- is 1.61803398875
	--##		local mg_golden_ratio_double = mg_golden_ratio * 2			-- is 3.2360679775
	--##		local mg_golden_ratio_half = mg_golden_ratio * 0.5			-- is 0.809016994375
	--##		local mg_golden_ratio_tenth = mg_golden_ratio * 0.1			-- is 0.161803398875
	--##		local mg_golden_ratio_fivetenths = mg_golden_ratio * 0.05		-- is 0.0809016994375
	--##		
	--##		local euler_mascheroni_const = 0.5772156649
	--##		local euler_number = 2.7182818284
	--##		
	--##		euler_mascheroni_const = 0.5772156649-0153286060-6512090082-4024310421-5933593992
	--##		euler_number = 2.7182818284-5904523536-0287471352-6624977572-4709369995
	--##		
	--##		sqrt(2) = 1.41421356237
	--##		sqrt(3) = 1.73205080757
	--##		sqrt(5) = 2.2360679775
	--##		sqrt(6) = 2.44948974278
	--##		sqrt(7) = 2.64575131106
	--##		sqrt(8) = 2.82842712475
	--##		sqrt(10) = 3.16227766017
	--##		sqrt(11) = 3.31662479036
	--##		sqrt(12) = 3.46410161514
	--##		sqrt(13) = 3.60555127546
	--##		sqrt(14) = 3.74165738677
	--##		sqrt(15) = 3.87298334621
	--##		sqrt(17) = 4.12310562562
	--##		sqrt(18) = 4.24264068712
	--##		sqrt(19) = 4.35889894354
	--##		sqrt() = 
	--##		pi = 3.14159265359
	--##		
	--##		
	


--##
--##	LERP, BIAS, GAIN, STEP
--##

	function lib_mg_continental.lerp(noise_a, noise_b, n_mod)
		return noise_a * (1 - n_mod) + noise_b * n_mod
	end
	
	function lib_mg_continental.steps(noise, h)
		local w = abs(noise)				--n_base
		local k = floor(h / w)
		local f = (h - k * w) / w
		local s = min(2 * f, 1.0)
		return (k + s) * w
	end
	
	function lib_mg_continental.bias(noise, bias)
		return (noise / ((((1.0 / bias) - 2.0) * (1.0 - noise)) + 1.0))
	end
	
	function lib_mg_continental.gain(noise, gain)
		if noise < 0.5 then
			return bias(noise * 2.0, gain) / 2.0
		else
			return bias(noise * 2.0 - 1.0, 1.0 - gain) / 2.0 + 0.5
		end
	end


--##
--##	MIDPOINT, TRIANGULATION FUNCTIONS
--##

	function lib_mg_continental.get_midpoint(a,b)						--get_midpoint(a,b)
		return ((a.x+b.x) * 0.5), ((a.z+b.z) * 0.5)					--returns the midpoint between two points
	end
	
	function lib_mg_continental.get_triangulation_2d(a,b,c)					--get_2d_triangulation(a,b,c)
		return ((a.x+b.x+c.x)/3), ((a.z+b.z+c.z)/3)				--returns the triangulated point between three points (average pos)
	end
	
	function lib_mg_continental.get_triangulation_3d(a,b,c)					--get_3d_triangulation(a,b,c)
		return ((a.x+b.x+c.x)/3), ((a.y+b.y+c.y)/3), ((a.z+b.z+c.z)/3)		--returns the 3D triangulated point between three points (average pos)
	end


--##
--##	DIRECTION, SLOPE FUNCTIONS
--##

	function lib_mg_continental.get_direction_to_pos(a,b)
		local t_compass
		local t_dir = {x = 0, z = 0}
	
		if a.z < b.z then
			t_dir.z = 1
			t_compass = "N"
		elseif a.z > b.z then
			t_dir.z = -1
			t_compass = "S"
		else
			t_dir.z = 0
			t_compass = ""
		end
		if a.x < b.x then
			t_dir.x = 1
			t_compass = t_compass .. "E"
		elseif a.x > b.x then
			t_dir.x = -1
			t_compass = t_compass .. "W"
		else
			t_dir.x = 0
			t_compass = t_compass .. ""
		end
		return t_dir, t_compass
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




--##
--##	DISTANCE FUNCTIONS
--##

	function lib_mg_continental.get_dist(a,b,d_type)						--get_distance(a,b)
	
		local this_dist
		
		if d_type == "a" then
			this_dist = (abs(a) + abs(b)) * 0.5
		elseif d_type == "c" then
			this_dist = max(abs(a), abs(b))
		elseif d_type == "e" then
			this_dist = ((abs(a) * abs(a)) + (abs(b) * abs(b)))^0.5
		elseif d_type == "l" then
			this_dist = min(abs(a), abs(b))
		elseif d_type == "m" then
			this_dist = abs(a) + abs(b)
		elseif d_type == "x" then
			local d_a = (abs(a) + abs(b)) * 0.5
			local d_c = max(abs(a), abs(b))
			local d_e = ((abs(a) * abs(a)) + (abs(b) * abs(b)))^0.5
			local d_m = abs(a) + abs(b)
			this_dist = (d_a + d_c + d_e + d_m) * 0.25
		elseif d_type == "r" then
			local d_a = (abs(a) + abs(b)) * 0.5
			local d_c = max(abs(a), abs(b))
			local d_e = ((abs(a) * abs(a)) + (abs(b) * abs(b)))^0.5
			local d_m = abs(a) + abs(b)
			this_dist = d_a + d_c + d_e + d_m
		elseif d_type == "ac" then
			local d_a = (abs(a) + abs(b)) * 0.5
			local d_c = max(abs(a), abs(b))
			this_dist = (d_a + d_c) * 0.5
		elseif d_type == "ae" then
			local d_a = (abs(a) + abs(b)) * 0.5
			local d_e = ((abs(a) * abs(a)) + (abs(b) * abs(b)))^0.5
			this_dist = (d_a + d_e) * 0.5
		elseif d_type == "al" then
			local d_a = (abs(a) + abs(b)) * 0.5
			local d_l = min(abs(a), abs(b))
			this_dist = (d_a + d_l) * 0.5
		elseif d_type == "am" then
			local d_a = (abs(a) + abs(b)) * 0.5
			local d_m = abs(a) + abs(b)
			this_dist = (d_a + d_m) * 0.5
		elseif d_type == "ce" then
			local d_c = max(abs(a), abs(b))
			local d_e = ((abs(a) * abs(a)) + (abs(b) * abs(b)))^0.5
			this_dist = (d_c + d_e) * 0.5
		elseif d_type == "cl" then
			local d_c = max(abs(a), abs(b))
			local d_l = min(abs(a), abs(b))
			this_dist = (d_c + d_e) * 0.5
		elseif d_type == "cm" then
			local d_c = max(abs(a), abs(b))
			local d_m = abs(a) + abs(b)
			this_dist = (d_c + d_m) * 0.5
		elseif d_type == "em" then
			local d_e = ((abs(a) * abs(a)) + (abs(b) * abs(b)))^0.5
			local d_m = abs(a) + abs(b)
			this_dist = (d_e + d_m) * 0.5
		elseif d_type == "ace" then
			local d_a = (abs(a) + abs(b)) * 0.5
			local d_c = max(abs(a), abs(b))
			local d_e = ((abs(a) * abs(a)) + (abs(b) * abs(b)))^0.5
			this_dist = (d_a + d_c + d_e) * 0.35
		elseif d_type == "acm" then
			local d_a = (abs(a) + abs(b)) * 0.5
			local d_c = max(abs(a), abs(b))
			local d_m = abs(a) + abs(b)
			this_dist = (d_a + d_c + d_m) * 0.35
		elseif d_type == "aem" then
			local d_a = (abs(a) + abs(b)) * 0.5
			local d_e = ((abs(a) * abs(a)) + (abs(b) * abs(b)))^0.5
			local d_m = abs(a) + abs(b)
			this_dist = (d_a + d_e + d_m) * 0.35
		elseif d_type == "cem" then
			local d_c = max(abs(a), abs(b))
			local d_e = ((abs(a) * abs(a)) + (abs(b) * abs(b)))^0.5
			local d_m = abs(a) + abs(b)
			this_dist = (d_c + d_e + d_m) * 0.35
		else
			this_dist = 0
		end
	
		return this_dist
	
	end


--##
--##	2D DISTANCE FUNCTIONS
--##

	function lib_mg_continental.get_distance_average(a,b)						--get_avg_distance(a,b)
	    return ((abs(a.x-b.x) + abs(a.z-b.z)) * 0.5)					--returns the average distance between two points
	end
	
	function lib_mg_continental.get_distance_chebyshev(a,b)						--get_distance(a,b)
	    return (max(abs(a.x-b.x), abs(a.z-b.z)))					--returns the chebyshev distance between two points
	end
	
	function lib_mg_continental.get_distance_least(a,b)						--get_distance(a,b)
	    return (min(abs(a.x-b.x), abs(a.z-b.z)))					--returns the chebyshev distance between two points
	end
	
	function lib_mg_continental.get_distance_euclid(a,b)
		local dx = a.x - b.x
		local dz = a.z - b.z
		return (dx*dx+dz*dz)^0.5
	end
	
	function lib_mg_continental.get_distance_manhattan(a,b)					--get_manhattan_distance(a,b)
	    return (abs(a.x-b.x) + abs(a.z-b.z))					--returns the manhattan distance between two points
	end
	
	function lib_mg_continental.get_distance(a,b,d_type)						--get_distance(a,b)
	
		local this_dist
		
		if d_type == "a" then
			this_dist = ((abs(a.x-b.x) + abs(a.z-b.z)) * 0.5)
		elseif d_type == "c" then
			this_dist = (max(abs(a.x-b.x), abs(a.z-b.z)))
		elseif d_type == "e" then
			this_dist = (((abs(a.x-b.x) * abs(a.x-b.x)) + (abs(a.z-b.z) * abs(a.z-b.z)))^0.5)
		elseif d_type == "l" then
			this_dist = (min(abs(a.x-b.x), abs(a.z-b.z)))
		elseif d_type == "m" then
			this_dist = (abs(a.x-b.x) + abs(a.z-b.z))
		elseif d_type == "x" then
			local d_a = (abs(a.x-b.x) + abs(a.z-b.z)) * 0.5
			local d_c = max(abs(a.x-b.x), abs(a.z-b.z))
			local d_e = ((abs(a.x-b.x) * abs(a.x-b.x)) + (abs(a.z-b.z) * abs(a.z-b.z)))^0.5
			local d_m = abs(a.x-b.x) + abs(a.z-b.z)
			this_dist = (d_a + d_c + d_e + d_m) * 0.25
		elseif d_type == "r" then
			local d_a = (abs(a.x-b.x) + abs(a.z-b.z)) * 0.5
			local d_c = max(abs(a.x-b.x), abs(a.z-b.z))
			local d_e = ((abs(a.x-b.x) * abs(a.x-b.x)) + (abs(a.z-b.z) * abs(a.z-b.z)))^0.5
			local d_m = abs(a.x-b.x) + abs(a.z-b.z)
			this_dist = d_a + d_c + d_e + d_m
		elseif d_type == "ac" then
			local d_a = (abs(a.x-b.x) + abs(a.z-b.z)) * 0.5
			local d_c = max(abs(a.x-b.x), abs(a.z-b.z))
			this_dist = (d_a + d_c) * 0.5
		elseif d_type == "ae" then
			local d_a = (abs(a.x-b.x) + abs(a.z-b.z)) * 0.5
			local d_e = ((abs(a.x-b.x) * abs(a.x-b.x)) + (abs(a.z-b.z) * abs(a.z-b.z)))^0.5
			this_dist = (d_a + d_e) * 0.5
		elseif d_type == "am" then
			local d_a = (abs(a.x-b.x) + abs(a.z-b.z)) * 0.5
			local d_m = abs(a.x-b.x) + abs(a.z-b.z)
			this_dist = (d_a + d_m) * 0.5
		elseif d_type == "ce" then
			local d_c = max(abs(a.x-b.x), abs(a.z-b.z))
			local d_e = ((abs(a.x-b.x) * abs(a.x-b.x)) + (abs(a.z-b.z) * abs(a.z-b.z)))^0.5
			this_dist = (d_c + d_e) * 0.5
		elseif d_type == "cl" then
			local d_c = max(abs(a.x-b.x), abs(a.z-b.z))
			local d_l = min(abs(a.x-b.x), abs(a.z-b.z))
			this_dist = (d_c + d_e) * 0.5
		elseif d_type == "cm" then
			local d_c = max(abs(a.x-b.x), abs(a.z-b.z))
			local d_m = abs(a.x-b.x) + abs(a.z-b.z)
			this_dist = (d_c + d_m) * 0.5
		elseif d_type == "em" then
			local d_e = ((abs(a.x-b.x) * abs(a.x-b.x)) + (abs(a.z-b.z) * abs(a.z-b.z)))^0.5
			local d_m = abs(a.x-b.x) + abs(a.z-b.z)
			this_dist = (d_e + d_m) * 0.5
		elseif d_type == "ace" then
			local d_a = (abs(a.x-b.x) + abs(a.z-b.z)) * 0.5
			local d_c = max(abs(a.x-b.x), abs(a.z-b.z))
			local d_e = ((abs(a.x-b.x) * abs(a.x-b.x)) + (abs(a.z-b.z) * abs(a.z-b.z)))^0.5
			this_dist = (d_a + d_c + d_e) * 0.35
		elseif d_type == "acm" then
			local d_a = (abs(a.x-b.x) + abs(a.z-b.z)) * 0.5
			local d_c = max(abs(a.x-b.x), abs(a.z-b.z))
			local d_m = abs(a.x-b.x) + abs(a.z-b.z)
			this_dist = (d_a + d_c + d_m) * 0.35
		elseif d_type == "aem" then
			local d_a = (abs(a.x-b.x) + abs(a.z-b.z)) * 0.5
			local d_e = ((abs(a.x-b.x) * abs(a.x-b.x)) + (abs(a.z-b.z) * abs(a.z-b.z)))^0.5
			local d_m = abs(a.x-b.x) + abs(a.z-b.z)
			this_dist = (d_a + d_e + d_m) * 0.35
		elseif d_type == "cem" then
			local d_c = max(abs(a.x-b.x), abs(a.z-b.z))
			local d_e = ((abs(a.x-b.x) * abs(a.x-b.x)) + (abs(a.z-b.z) * abs(a.z-b.z)))^0.5
			local d_m = abs(a.x-b.x) + abs(a.z-b.z)
			this_dist = (d_c + d_e + d_m) * 0.35
		else
			this_dist = 0
		end
	
		return this_dist
	
	end



--##
--##	3D DISTANCE FUNCTIONS
--##

	function lib_mg_continental.get_distance_3d_average(a,b)						--get_avg_distance(a,b)
	    return ((abs(a.x-b.x) + abs(a.y-b.y) + abs(a.z-b.z)) / 3)					--returns the average distance between two points
	end
	
	function lib_mg_continental.get_distance_3d_chebyshev(a,b)						--get_distance(a,b)
	    return (max(abs(a.x-b.x), max(abs(a.y-b.y), abs(a.z-b.z))))					--returns the chebyshev distance between two points
	end
	
	function lib_mg_continental.get_distance_3d_least(a,b)						--get_distance(a,b)
	    return (min(abs(a.x-b.x), min(abs(a.y-b.y), abs(a.z-b.z))))					--returns the chebyshev distance between two points
	end
	
	function lib_mg_continental.get_distance_3d_euclid(a,b)
		local dx = a.x - b.x
		local dy = a.y - b.y
		local dz = a.z - b.z
		return (dx*dx+dy*dy+dz*dz)^0.5
	end
	
	function lib_mg_continental.get_distance_3d_manhattan(a,b)					--get_manhattan_distance(a,b)
	    return (abs(a.x-b.x) + abs(a.y-b.y) + abs(a.z-b.z))					--returns the manhattan distance between two points
	end
	
	function lib_mg_continental.get_distance_3d(a,b,d_type)						--get_distance(a,b)
	
		local this_dist
		
		if d_type == "a" then
			this_dist = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		elseif d_type == "c" then
			this_dist = lib_mg_continental.get_distance_3d_chebyshev({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		elseif d_type == "e" then
			this_dist = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		elseif d_type == "l" then
			this_dist = lib_mg_continental.get_distance_3d_least({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		elseif d_type == "m" then
			this_dist = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
		elseif d_type == "x" then
			local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			this_dist = (d_a + d_c + d_e + d_m) * 0.25
		elseif d_type == "r" then
			local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			this_dist = d_a + d_c + d_e + d_m
		elseif d_type == "ac" then
			local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x,y = a.y,  z = a.z}, {x = b.x, y = b.y, z = b.z})
			this_dist = (d_a + d_c) * 0.5
		elseif d_type == "ae" then
			local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			this_dist = (d_a + d_e) * 0.5
		elseif d_type == "am" then
			local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			this_dist = (d_a + d_m) * 0.5
		elseif d_type == "ce" then
			local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			this_dist = (d_c + d_e) * 0.5
		elseif d_type == "cm" then
			local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			this_dist = (d_c + d_m) * 0.5
		elseif d_type == "em" then
			local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			this_dist = (d_e + d_m) * 0.5
		elseif d_type == "ace" then
			local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			this_dist = (d_a + d_c + d_e) * 0.35
		elseif d_type == "acm" then
			local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			this_dist = (d_a + d_c + d_m) * 0.35
		elseif d_type == "aem" then
			local d_a = lib_mg_continental.get_distance_3d_average({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			this_dist = (d_a + d_e + d_m) * 0.35
		elseif d_type == "cem" then
			local d_c = lib_mg_continental.get_distance_3d_chebyshev({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_e = lib_mg_continental.get_distance_3d_euclid({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			local d_m = lib_mg_continental.get_distance_3d_manhattan({x = a.x, y = a.y, z = a.z}, {x = b.x, y = b.y, z = b.z})
			this_dist = (d_c + d_e + d_m) * 0.35
		else
			this_dist = 0
		end
	
		return this_dist
	
	end





--##
--##	NOISE FUNCTIONS
--##

	function lib_mg_continental.max_height(noiseprm)
		local height = 0					--	30		18
		local scale = noiseprm.scale				--	18		10.8
		for i=1,noiseprm.octaves do				--	10.8		6.48
			height=height + scale				--	6.48		3.88
			scale = scale * noiseprm.persist		--	3.88		2.328
		end							--	-----		------
		return height+noiseprm.offset				--			41.496 + (-4)
	end								--			37.496
	
	function lib_mg_continental.min_height(noiseprm)
		local height = 0
		local scale = noiseprm.scale
		for i=1,noiseprm.octaves do
			height=height - scale
			scale = scale * noiseprm.persist
		end	
		return height+noiseprm.offset
	end
	
	function lib_mg_continental.get_noise_height(palt,pbase,pheight)
		if palt > pbase then
			return palt
		end
		return (pbase * pheight) + (palt * (1.0 - pheight))
	end
	
	function lib_mg_continental.rangelim(a)
		if a < 0 then
			a = 0.0
		end
		if a > 1 then
			a = 1.0
		end
		return a
	end




--##
--##	NOISE DATA FUNCTIONS
--##

	local mult = lib_mg_continental.mg_world_scale
	local noise_scale = lib_mg_continental.mg_noise_scale

	local np_terrain = lib_mg_continental.P["np_terrain"]

	----local hills_offset = 64*mult
	local hills_thresh = floor((noise_scale * mult) * 0.5)
	local shelf_thresh = floor((noise_scale * mult) * 0.5) 
	local cliffs_thresh = floor((noise_scale * mult) * 0.5)
	--local hills_thresh = floor((np_terrain.scale) * 0.5)
	--local shelf_thresh = floor((np_terrain.scale) * 0.5) 
	--local cliffs_thresh = floor((np_terrain.scale) * 0.5)

	lib_mg_continental.mg_hills_thresh = hills_thresh
	lib_mg_continental.mg_shelf_thresh = shelf_thresh
	lib_mg_continental.mg_cliffs_thresh = cliffs_thresh


	local base_min = lib_mg_continental.min_height(np_terrain)
	local base_max = lib_mg_continental.max_height(np_terrain)
	local base_rng = base_max-base_min
	local easing_factor = 1/(base_max*base_max*4)

	lib_mg_continental.mg_base_min = base_min
	lib_mg_continental.mg_base_max = base_max
	lib_mg_continental.mg_base_rng = base_rng
	lib_mg_continental.mg_easing_factor = easing_factor




--##
--##	ISLANDS TERRAIN SHAPING FUNCTIONS:	get_terrain_height, _shelf, _hills, _cliffs, _adjustable variants.
--##

	function lib_mg_continental.get_terrain_height(theight,hheight,cheight)
			-- parabolic gradient
		if theight > 0 and theight < shelf_thresh then
			theight = theight * (theight * theight / (shelf_thresh * shelf_thresh) * 0.5 + 0.5)
		end	
			-- hills
		if theight > hills_thresh then
			theight = theight + max((theight - hills_thresh) * hheight,0)
			-- cliffs
		elseif theight > 1 and theight < hills_thresh then 
			local clifh = max(min(cheight,1),0) 
			if clifh > 0 then
				clifh = -1 * (clifh - 1) * (clifh - 1) + 1
				theight = theight + (hills_thresh - theight) * clifh * ((theight < 2) and theight - 1 or 1)
			end
		end
		return theight
	end
	 
	function lib_mg_continental.get_terrain_height_shelf(theight)
			-- parabolic gradient
		if theight > 0 and theight < shelf_thresh then
			theight = theight * (theight * theight / (shelf_thresh * shelf_thresh) * 0.5 + 0.5)
		end
	
		return theight
	end
	
	function lib_mg_continental.get_terrain_height_hills(theight,hheight)
			-- hills
		if theight > hills_thresh then
			theight = theight + max((theight - hills_thresh) * hheight,0)
		end
		return theight
	end
	 
	function lib_mg_continental.get_terrain_height_cliffs(theight,cheight)
			-- cliffs
		if theight > 1 and theight < hills_thresh then 
			local clifh = max(min(cheight,1),0) 
			if clifh > 0 then
				clifh = -1 * (clifh - 1) * (clifh - 1) + 1
				theight = theight + (hills_thresh - theight) * clifh * ((theight < 2) and theight - 1 or 1)
				--theight = theight + (cliffs_thresh - theight) * clifh * ((theight < 2) and theight - 1 or 1)
			end
		end
		return theight
	end
	 
	function lib_mg_continental.get_terrain_height_cliffs_hills(theight,hheight,cheight)
			-- hills
		if theight > hills_thresh then
			theight = theight + math.max((theight - hills_thresh) * hheight,0)
			-- cliffs
		elseif theight > 1 and theight < hills_thresh then 
			local clifh = math.max(math.min(cheight,1),0) 
			if clifh > 0 then
				clifh = -1*(clifh-1)*(clifh-1) + 1
				theight = theight + (hills_thresh - theight) * clifh * ((theight<2) and theight-1 or 1)
			end
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
	
	function lib_mg_continental.get_terrain_height_adjustable_cliffs(theight,cheight,clff_thresh)
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
	
	function lib_mg_continental.get_terrain_height_adjustable_hills(theight,hheight,hlls_thresh)
			-- hills
		if theight > hlls_thresh then
			theight = theight + math.max((theight-hlls_thresh) * hheight,0)
			--theight = theight + math.max((theight-hlls_thresh) + hheight,0)
		end
		return theight
	end
	
	function lib_mg_continental.get_terrain_height_adjustable_all(theight,hheight,cheight,shlf_thresh,hlls_thresh)
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
	
	function lib_mg_continental.get_terrain_height_shelf_adjustable_hills(theight,hheight,cheight,hlls_thresh)
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









