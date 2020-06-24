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

	return nil
end

function lib_mg_continental.load_defaults_csv(separator, path)
	local file = io.open(lib_mg_continental.path_mod.."/sets/"..path, "r")
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

	return nil
end

