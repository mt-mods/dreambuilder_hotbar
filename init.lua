local storage = minetest.get_mod_storage()
local themename = ""

if minetest.global_exists("dreambuilder_theme") then
	themename = dreambuilder_theme.name.."_"
end

local base_img = themename.."gui_hb_bg_1.png"
local imgref_len = string.len(base_img) + 8 -- accounts for the stuff in the string.format() below.
local hotbar_size_default = 16

local img = {}
for i = 0, 31 do
	img[i+1] = string.format(":%04i,0=%s", i*64, base_img)
end
local hb_img = table.concat(img)

local function validate_size(s)
	local size = s and tonumber(s) or hotbar_size_default
	return math.floor(0.5 + math.max(1, math.min(size, 32)))
end

hotbar_size_default = validate_size(minetest.settings:get("hotbar_size"))

local function migrate_file2modstorage()
	local path = minetest.get_worldpath()..DIR_DELIM.."hotbar_settings"
	local f = io.open(path, "r")
	if f then
		local hotbar_sizes = minetest.deserialize(f:read("*all"))
		f:close()
		local counter = 0
		for name, size in pairs(hotbar_sizes) do
			if size ~= hotbar_size_default then
				storage:set_int(name, tonumber(size))
				counter = counter + 1
			end
		end
		os.remove(path)
		minetest.log("action", "[dreambuilder_hotbar] Migrated " .. counter .. " player hotbars to modstorage")
	end
end

local function get_hotbar_size(player)
	local name = player:get_player_name()
	local meta = player:get_meta()
	local size = meta:get_int("hotbar_size")
	if size == 0 then -- not present
		size = storage:get_int(name)
		if size ~= 0 then -- migrate
			storage:set_string(name, "")
			meta:set_int("hotbar_size", size)
		end
	end
	return size > 0 and size or hotbar_size_default
end

local function update_hotbar(player, hotbar_size)
	player:hud_set_hotbar_itemcount(hotbar_size)
	player:hud_set_hotbar_selected_image(themename.."gui_hotbar_selected.png")
	player:hud_set_hotbar_image("[combine:"..(hotbar_size*64).."x64"..string.sub(hb_img, 1, hotbar_size*imgref_len))
end

local function set_hotbar_size(player, size)
	local meta = player:get_meta()
	local hotbar_size = validate_size(size)
	meta:set_int("hotbar_size", hotbar_size)
	update_hotbar(player, hotbar_size)
	return hotbar_size
end

minetest.register_on_joinplayer(function(player)
	minetest.after(0.5, function()
		update_hotbar(player, get_hotbar_size(player))
	end)
end)

minetest.register_chatcommand("hotbar", {
	params = "<size>",
	description = "Sets the size of your hotbar, from 1 to 32 slots, default " .. hotbar_size_default,
	func = function(name, slots)
		local size = set_hotbar_size(minetest.get_player_by_name(name), slots)
		minetest.chat_send_player(name, "[_] Hotbar size set to " ..size.. ".")
	end
})

migrate_file2modstorage()