
local storage = minetest.get_mod_storage()

local themename = ""
if minetest.global_exists("dreambuilder_theme") then
	themename = dreambuilder_theme.name.."_"
end

local hotbar_selected_image = themename.."gui_hotbar_selected.png"
local hotbar_image = {}
do
	local hotbar_slot = themename.."gui_hb_bg_1.png"
	local str = ""
	for i = 0, 31 do
		str = str..string.format(":%i,0=%s", i*64, hotbar_slot)
		hotbar_image[i+1] = string.format("[combine:%ix64%s", (i+1)*64, str)
	end
end

local hotbar_size_default = 16

local function validate_size(s)
	local size = tonumber(s) or hotbar_size_default
	return math.max(1, math.min(math.floor(size + 0.5), 32))
end

hotbar_size_default = validate_size(minetest.settings:get("hotbar_size"))

local function get_hotbar_size(player)
	local name = player:get_player_name()
	local meta = player:get_meta()
	local size = meta:get_int("hotbar_size")
	if size == 0 then
		-- Migrate from modstorage if present
		size = storage:get_int(name)
		if size ~= 0 then
			storage:set_string(name, "")
			meta:set_int("hotbar_size", size)
		end
	end
	return size > 0 and size or hotbar_size_default
end

local function update_hotbar(player, hotbar_size)
	player:hud_set_hotbar_itemcount(hotbar_size)
	player:hud_set_hotbar_selected_image(hotbar_selected_image)
	player:hud_set_hotbar_image(hotbar_image[hotbar_size])
end

local function set_hotbar_size(player, size)
	local meta = player:get_meta()
	local hotbar_size = validate_size(size)
	meta:set_int("hotbar_size", hotbar_size)
	update_hotbar(player, hotbar_size)
	return hotbar_size
end

local function after_join(name)
	local player = minetest.get_player_by_name(name)
	if player then
		update_hotbar(player, get_hotbar_size(player))
	end
end

minetest.register_on_joinplayer(function(player)
	minetest.after(0.5, after_join, player:get_player_name())
end)

minetest.register_chatcommand("hotbar", {
	params = "<size>",
	description = "Sets the size of your hotbar, from 1 to 32 slots. Default " .. hotbar_size_default,
	func = function(name, slots)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player is not online."
		end
		local size = set_hotbar_size(player, slots)
		return true, "Hotbar size set to "..size
	end
})

-- Migrate hotbar settings from file to modstorage
local function migrate_storage()
	local path = minetest.get_worldpath()..DIR_DELIM.."hotbar_settings"
	local file = io.open(path, "r")
	if file then
		local hotbar_sizes = minetest.deserialize(file:read("*all"))
		file:close()
		local count = 0
		for name, size in pairs(hotbar_sizes) do
			if size ~= hotbar_size_default then
				storage:set_int(name, tonumber(size))
				count = count + 1
			end
		end
		os.remove(path)
		minetest.log("action", "[dreambuilder_hotbar] Migrated "..count.." player hotbars to modstorage")
	end
end
migrate_storage()
