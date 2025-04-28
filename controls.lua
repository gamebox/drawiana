local Rectangle = require("tools").Rectangle
local Line = require("tools").Line
local Text = require("tools").Text
local Circle = require("tools").Circle

local M = {}

---@alias Color { r : number, g : number, b : number, a? : number }
---@alias Orientation 0 | 1

---@type Orientation
local HORIZONTAL = 0
---@type Orientation
local VERITCAL = 1

---@type Color
local black = { r = 0, g = 0, b = 0 }
---@type Color
local white = { r = 1, g = 1, b = 1 }
---@type Color
local selected_color = { r = 0.1, g = 0.4, b = 0.8 }

---@type Color[]
local color_options = {
	{ r = 1, g = 0, b = 0 },
	{ r = 0.5, g = 0, b = 0 },
	{ r = 1, g = 1, b = 0 },
	{ r = 0.5, g = 0.5, b = 0 },
	{ r = 0.92, g = 0.49, b = 0.1 },
	{ r = 1, g = 0, b = 1 },
	{ r = 0.5, g = 0, b = 0.5 },
	{ r = 0, g = 1, b = 0 },
	{ r = 0, g = 0.5, b = 0 },
	{ r = 0, g = 1, b = 1 },
	{ r = 0, g = 0.5, b = 0.5 },
	{ r = 0, g = 0, b = 1 },
	white,
	{ r = 0.66, g = 0.66, b = 0.66 },
	{ r = 0.33, g = 0.33, b = 0.33 },
	black,
}

---@class Controls table
---@field x number
---@field y number
---@field h number
---@field w number
---@field current_color Color
---@field current_line_width number
---@field color_opt_width number
---@field color_opt_height number
---@field orientation Orientation
---@field tool string
---@field tool_options Tool[]
---@field color_options Color[]
local Controls = {
	x = 0,
	y = 0,
	h = 0,
	w = 0,
	current_color = white,
	current_line_width = 1,
	color_opt_height = 0,
	color_opt_width = 0,
	orientation = HORIZONTAL,
	tool = "line",
	tool_options = {},
	tools = { "rectangle", "rectangle_outline", "circle", "circle_outline", "line", "text" },
	color_options = color_options,
}

---@param x number The x position where the controls will render
---@param y number The y position where the controls will render
---@param h number The amount of pixels given to the controls to render in the x-axis
---@param w number The amount of pixels given to the controls to render in the y-axis
function Controls:new(x, y, h, w)
	local c = {
		x = x,
		y = y,
		h = h,
		w = w,
		current_color = white,
		tool = "line",
		tool_options = {},
	}
	local r = Rectangle:new(1, black)
	r.mode = "fill"
	local r2 = Rectangle:new(3, black)
	r2.mode = "line"
	local l = Line:new(1, black)
	local circle = Circle:new(1, black)
	circle.mode = "fill"
	local circle_o = Circle:new(3, black)
	circle_o.mode = "line"
	local t = Text:new(1, black)
	t.size = 20
	t.text = "T"
	table.insert(c.tool_options, r)
	table.insert(c.tool_options, r2)
	table.insert(c.tool_options, circle)
	table.insert(c.tool_options, circle_o)
	table.insert(c.tool_options, l)
	table.insert(c.tool_options, t)
	if h > w then
		c.orientation = VERITCAL
		c.color_opt_width = 40
		c.color_opt_height = math.floor(c.h / #color_options)
		local border = 2
		r.start = { x = c.x + border, y = c.y + border }
		r.end_ = { x = c.x + c.color_opt_width - 2, y = c.y + c.color_opt_height - 2 }
		r2.start = { x = c.x, y = c.y }
		r2.end_ = { x = c.x + (c.color_opt_width - 2) * 2, y = c.y + c.color_opt_height - 2 }
		l.points = {}
	else
		local border = 2
		c.orientation = HORIZONTAL
		c.color_opt_width = 40
		c.color_opt_height = math.floor(c.h / 2)
		local xoffset = c.x
		r.start = { x = xoffset + 2, y = c.y + 2 }
		r.end_ = { x = xoffset + c.color_opt_width - 4, y = c.y + c.color_opt_height - 2 }
		xoffset = xoffset + c.color_opt_width
		r2.start = { x = xoffset + 4, y = c.y + 4 }
		r2.end_ = { x = xoffset + c.color_opt_width - 4, y = c.y + c.color_opt_height - 4 }
		xoffset = xoffset + c.color_opt_width
		circle.radiusx = c.color_opt_width / 2 - 5
		circle.radiusy = c.color_opt_height / 2 - 5
		circle.origin = { x = xoffset + (c.color_opt_width / 2), y = c.y + (c.color_opt_height / 2) }
		xoffset = xoffset + c.color_opt_width
		circle_o.radiusx = c.color_opt_width / 2 - 7
		circle_o.radiusy = c.color_opt_height / 2 - 7
		circle_o.origin = { x = xoffset + (c.color_opt_width / 2), y = c.y + (c.color_opt_height / 2) }
		xoffset = xoffset + c.color_opt_width
		l.points = {
			xoffset + 8,
			c.y + 8,
			xoffset + c.color_opt_width - 8,
			c.y + c.color_opt_height - 8,
		}
		l:setColor(selected_color)
		xoffset = xoffset + c.color_opt_width
		t.start = { x = xoffset + border + 12, y = c.y + border }
	end

	r:set_dimensions()
	r2:set_dimensions()

	setmetatable(c, self)
	self.__index = self

	return c
end

function Controls:alter_line_width(delta)
	self.current_line_width = (math.min(300, math.max(0, self.current_line_width + delta)))
end

---@param controls Controls
---@param x number
---@param y number
local in_area = function(controls, x, y)
	if x < controls.x or y < controls.y or x > (controls.x + controls.w) or y > (controls.y + controls.h) then
		return false
	end
	return true
end

function Controls:mousepressed(x, y)
	if in_area(self, x, y) then
		local index = 1
		while x > index * self.color_opt_width do
			index = index + 1
		end
		if y - self.y < math.floor(self.color_opt_height) then
			if index > #self.tools then
				return true
			end
			self.tool = self.tools[index]
			for _, tool in pairs(self.tool_options) do
				tool:setColor(color_options[#color_options])
			end
			self.tool_options[index]:setColor(selected_color)
		else
			if index > #color_options then
				return true
			end
			self.current_color = color_options[index]
		end

		return true
	end
	return false
end

function Controls:keypressed(combo)
	local idx = 0
	if combo == "r" then
		idx = 1
		self.tool = "rectangle"
	-- elseif combo == "c" then
	-- 	self.tool = "circle"
	-- 	return true
	elseif combo == "Shift+r" then
		idx = 2
		self.tool = "rectangle_outline"
	-- elseif combo == "Shift+c" then
	-- 	self.tool = "circle_outline"
	elseif combo == "l" then
		idx = 3
		self.tool = "line"
	elseif combo == "t" then
		idx = 4
		self.tool = "text"
	end
	if idx > 0 then
		self.tool = self.tools[idx]
		for _, tool in pairs(self.tool_options) do
			tool:setColor(color_options[#color_options])
		end
		self.tool_options[idx]:setColor(selected_color)
		return true
	end
	if combo == "b" then
		self:alter_line_width(1)
		return true
	elseif combo == "Shift+b" then
		self:alter_line_width(10)
		return true
	elseif combo == "s" then
		self:alter_line_width(-1)
		return true
	elseif combo == "Shift+s" then
		self:alter_line_width(-10)
		return true
	end
	return false
end

function Controls:draw()
	love.graphics.setColor(0.75, 0.75, 0.75, 1)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.color_opt_height)
	if self.orientation == HORIZONTAL then
		for i, opt in pairs(color_options) do
			love.graphics.setColor(opt.r, opt.g, opt.b, opt.a or 1)
			love.graphics.rectangle(
				"fill",
				(i - 1) * self.color_opt_width,
				self.y + self.color_opt_height,
				self.color_opt_width,
				self.color_opt_height
			)
			if opt == self.current_color then
				love.graphics.setLineWidth(4)
				love.graphics.setColor(selected_color.r, selected_color.g, selected_color.b, opt.a or 0.7)
				love.graphics.rectangle(
					"line",
					(i - 1) * self.color_opt_width + 2,
					self.y + 2 + self.color_opt_height,
					self.color_opt_width - 4,
					self.h - 4
				)
			end
		end
	else
		for i, opt in pairs(color_options) do
			love.graphics.setColor(opt.r, opt.g, opt.b, opt.a or 1)
			love.graphics.rectangle(
				"fill",
				self.x + self.color_opt_width,
				(i - 1) * self.color_opt_height,
				self.color_opt_width,
				self.color_opt_height
			)
			if opt == self.current_color then
				love.graphics.setLineWidth(4)
				love.graphics.setColor(selected_color.r, selected_color.g, selected_color.b, selected_color.a or 0.7)
				love.graphics.rectangle(
					"line",
					self.x + 2 + self.color_opt_width,
					(i - 1) * self.color_opt_height + 2,
					self.color_opt_width - 4,
					self.h - 4
				)
			end
		end
	end
	for _, t in pairs(self.tool_options) do
		t:draw()
	end
	-- TODO: Implement add color button
	love.graphics.setColor(black.r, black.g, black.b, black.a or 1)
	love.graphics.print("" .. self.current_line_width, self.w - 50, self.y + 2)
end

---@param dt number
---@diagnostic disable-next-line unused-argument
function Controls:update(dt) end

---@return Tool
function Controls:newtool()
	-- Line is default
	if self.tool == "rectangle" then
		return Rectangle:new(self.current_line_width, self.current_color)
	end
	if self.tool == "rectangle_outline" then
		local rect = Rectangle:new(self.current_line_width, self.current_color)
		rect.mode = "line"
		return rect
	end
	if self.tool == "circle" then
		return Circle:new(self.current_line_width, self.current_color)
	end
	if self.tool == "circle_outline" then
		local circle = Circle:new(self.current_line_width, self.current_color)
		circle.mode = "line"
		return circle
	end
	if self.tool == "text" then
		local text = Text:new(self.current_line_width, self.current_color)
		text.size = 24
		return text
	end
	return Line:new(self.current_line_width, self.current_color)
end

-- Exports

M.Controls = Controls

return M
