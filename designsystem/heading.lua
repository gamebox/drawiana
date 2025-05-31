local View = require("view").View
local fonts = require("fonts")

local M = {}

---@class Heading : View
---@field text love.Text
---@field fontsize? number
---@field constraints? { h?: number, w?: number }
local Heading = View:new()

---@param text string
---@param fontsize? number
---@param constraints? { h?: number, w?: number }
---@return Heading
function Heading:new(text, fontsize, constraints)
	fontsize = fontsize or 14
	local font = fonts.get_regular_font(fontsize)
	local to = love.graphics.newText(font, text)
	local w, h = to:getDimensions()
	if constraints ~= nil then
		-- Do something
	end
	local heading = {
		text = to,
		w = w,
		h = h,
	}

	setmetatable(heading, self)
	self.__index = self

	return heading
end

function Heading:draw()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(self.text, self.x, self.y)
end

M.Heading = Heading

return M
