local M = {}

local light_fonts = {}
local regular_fonts = {}
local bold_fonts = {}

M.get_light_font = function(size)
	local name = "light_" .. size
	if light_fonts[name] then
		return light_fonts[name]
	else
		local font = love.graphics.newFont("static/NotoSans-Light.ttf", size)
		light_fonts[name] = font
		return font
	end
end

M.get_regular_font = function(size)
	local name = "regular_" .. size
	if regular_fonts[name] then
		return regular_fonts[name]
	else
		local font = love.graphics.newFont("static/NotoSans-Regular.ttf", size)
		regular_fonts[name] = font
		return font
	end
end

M.get_bold_font = function(size)
	local name = "bold_" .. size
	if bold_fonts[name] then
		return bold_fonts[name]
	else
		local font = love.graphics.newFont("static/NotoSans-Bold.ttf", size)
		bold_fonts[name] = font
		return font
	end
end

return M
