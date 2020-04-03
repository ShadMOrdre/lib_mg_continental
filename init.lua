
lib_mg_continental = {}
lib_mg_continental.name = "lib_mg_continental"
lib_mg_continental.ver_max = 0
lib_mg_continental.ver_min = 1
lib_mg_continental.ver_rev = 0
lib_mg_continental.ver_str = lib_mg_continental.ver_max .. "." .. lib_mg_continental.ver_min .. "." .. lib_mg_continental.ver_rev
lib_mg_continental.authorship = "ShadMOrdre, paramat, Termos, burli, Gael-de-Sailly, duane-r, and others"
lib_mg_continental.license = "LGLv2.1"
lib_mg_continental.copyright = "2019"
lib_mg_continental.path_mod = minetest.get_modpath(minetest.get_current_modname())
lib_mg_continental.path_world = minetest.get_worldpath()

local S
local NS
	if minetest.get_modpath("intllib") then
		S = intllib.Getter()
	else
		-- S = function(s) return s end
		-- internationalization boilerplate
		S, NS = dofile(lib_mg_continental.path_mod.."/intllib.lua")
	end

lib_mg_continental.intllib = S

minetest.log(S("[MOD] lib_mg_continental:  Loading..."))
minetest.log(S("[MOD] lib_mg_continental:  Version:") .. S(lib_mg_continental.ver_str))
minetest.log(S("[MOD] lib_mg_continental:  Legal Info: Copyright ") .. S(lib_mg_continental.copyright) .. " " .. S(lib_mg_continental.authorship) .. "")
minetest.log(S("[MOD] lib_mg_continental:  License: ") .. S(lib_mg_continental.license) .. "")


	lib_mg_continental.voxel_mg_voronoi = minetest.setting_get("lib_mg_continental_enable") or true				--true


-- switch for debugging
	lib_mg_continental.debug = false



	lib_mg_continental_max_height_difference = 4
	lib_mg_continental_half_map_chunk_size = 40
	lib_mg_continental_quarter_map_chunk_size = 20



	if lib_mg_continental.voxel_mg_voronoi == true then
		dofile(lib_mg_continental.path_mod.."/lib_mg_continental_voxel.lua")					--WORKING MAPGEN with and without biomes
	end


minetest.log(S("[MOD] lib_mg_continental:  Successfully loaded."))








