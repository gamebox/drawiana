local utils = require("../utils")
local View = require("view").View

---@type Color
local black = { r = 0, g = 0, b = 0, a = 1 }
---@type Color
local semi_white = { r = 1, g = 1, b = 1, a = 0.7 }

local M = {}

---@package
---@class Slider : View
---@field max number
---@field min number
---@field step number
---@field value number
---@field track_color Color
---@field fill_color Color
---@field track_height number
---@field show_value boolean
---@field font_size number
---@field private font love.Font
---@field private value_text love.Drawable
---@field private moving_start number|nil
local Slider = View:new()

-- Constructor for class
---@param x number
---@param y number
---@param w number
---@param h number
---@param opts Slider
---@return Slider
function Slider:new(x, y, w, h, opts)
	---@type Slider
	local slider = setmetatable({
		max = 100,
		min = 0,
		step = 1,
		value = 0,
		track_color = black,
		fill_color = semi_white,
		track_height = 30,
		show_value = false,
		font_size = 20,
		moving = nil,
	}, self)
	self.__index = self

	utils.extend_table(slider, opts)

	slider.x = x
	slider.y = y
	slider.w = w
	slider.h = h
	--slider.font = love.graphics.newFont(self.font_size)

	--slider.value_text = love.graphics.newText(self.font, string.format("%i", self.value))
	-- Return instance
	return slider
end

-- Create overrides for View lifecycle methods

---@param x number
---@param y number
---@return boolean
---@diagnostic disable-next-line unused-local TODO: remove this when implemented
function Slider:mousemoved(x, y)
	if self:inarea(x, y) then
		print("Slider:mousemoved inarea", x, y)
		if self.moving ~= nil then
			local percent = (math.max(self.x, math.min(x, self.x + self.w)) - self.x) / self.w
			self.value = math.max(self.min, math.floor(self.max * percent))
		end
	end
	return false
end

---@param x number
---@param y number
---@return boolean
---@diagnostic disable-next-line unused-local TODO: remove this when implemented
function Slider:mousepressed(x, y)
	if self:inarea(x, y) and self.moving == nil then
		print("Slider:mousepressed inarea", x, y)
		self.moving = x
		return true
	end
	return false
end

---@param x number
---@param y number
---@return boolean
---@diagnostic disable-next-line unused-local TODO: remove this when implemented
function Slider:mousereleased(x, y)
	if self.moving ~= nil then
		self.moving = nil
	end
	return false
end

---@param combo string
---@return boolean
---@diagnostic disable-next-line unused-local TODO: remove this when implemented
function Slider:keypressed(combo)
	return false
end

---@return boolean
function Slider:keyreleased()
	return false
end

---@param dt number
---@diagnostic disable-next-line unused-local TODO: remove this when implemented
function Slider:update(dt) end

function Slider:draw()
	love.graphics.setColor(self.track_color.r, self.track_color.g, self.track_color.b, self.track_color.a)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.track_height)
	love.graphics.setColor(self.fill_color.r, self.fill_color.g, self.fill_color.b, self.fill_color.a)
	love.graphics.rectangle("fill", self.x, self.y, self.w * (self.value / (self.max - self.min)), self.track_height)
end

-- Export class table
M.Slider = Slider

-- Return module table
return M
