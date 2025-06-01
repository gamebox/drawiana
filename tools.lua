local ascii_key_from_combo = require("textkeys").ascii_key_from_combo

local M = {}

---@enum Toolname
local toolnames = {
	unknown = 0,
	rectangle = 1,
	circle = 2,
	line = 3,
	text = 4,
}

---@class Tool
---@field toolname Toolname
---@field color Color
---@field width number
---@field building boolean
---@field selected boolean
---@field x number
---@field y number
---@field h number
---@field w number
---@field name string?
---@field private default_name string
local Tool = {
	toolname = toolnames.unknown,
	color = { r = 0, g = 0, b = 0, a = 1 },
	width = 0,
	x = 0,
	y = 0,
	h = 0,
	w = 0,
	selected = false,
	building = false,
	name = nil,
	default_name = "Tool",
}

---@return Tool
function Tool:new()
	local t = {}
	setmetatable(t, self)
	self.__index = self
	return t
end

---@param dt number
---@diagnostic disable-next-line unused-local
function Tool:update(dt) end

function Tool:draw() end

---@param color Color
function Tool:setColor(color)
	self.color = color
end

---@param width number
function Tool:setLineWidth(width)
	self.width = width
end

---@param x number The x position
---@param y number The y position
---@return boolean
---@diagnostic disable-next-line unused-local
function Tool:mousemoved(x, y)
	return false
end

---@param x number The x position
---@param y number The y position
---@return boolean
---@diagnostic disable-next-line unused-local
function Tool:mousepressed(x, y)
	return false
end

---@param x number The x position
---@param y number The y position
---@return boolean
---@diagnostic disable-next-line unused-local
function Tool:mousereleased(x, y)
	return false
end

---@param combo string
---@return boolean
---@diagnostic disable-next-line unused-local
function Tool:keypressed(combo)
	return false
end

---@param dx number
---@param dy number
---@diagnostic disable-next-line unused-local
function Tool:move(dx, dy) end

function Tool:draw_selection_box()
	if self.selected then
		love.graphics.setColor(0.0, 0.0, 0.75, 0.3)
		love.graphics.setLineWidth(1)
		love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
	end
end

function Tool:get_name()
	return self.name or self.default_name
end

-- LINE

---@class Line: Tool
---@field width number
---@field color Color
---@field points number[]
local Line = Tool:new()

---@param linewidth number
---@param color Color
---@return Line
function Line:new(linewidth, color)
	---@type Line
	local l = {
		toolname = toolnames.line,
		width = linewidth,
		color = color,
		points = {},
		default_name = "Line",
	}

	setmetatable(l, self)
	self.__index = self

	return l
end

function Line:mousepressed(x, y)
	self.building = true
	table.insert(self.points, x)
	table.insert(self.points, y)
	return true
end

function Line:mousemoved(x, y)
	if self.building then
		table.insert(self.points, x)
		table.insert(self.points, y)
		return true
	end
	return false
end

function Line:set_dimensions()
	local startx, starty, endx, endy = 0, 0, 0, 0

	for i, point in ipairs(self.points) do
		if i % 2 == 0 then
			starty = math.min(starty, point)
			endy = math.max(endy, point)
		else
			startx = math.min(startx, point)
			endx = math.max(endx, point)
		end
	end

	self.x = startx
	self.y = starty
	self.w = endx - startx
	self.h = endy - starty
end

function Line:mousereleased()
	if self.building then
		self.building = false
		self:set_dimensions()
		return true
	end
	return false
end

function Line:alter_line_width(delta)
	self:setLineWidth(math.min(300, math.max(0, self.width + delta)))
end

function Line:draw()
	if #self.points < 4 then
		return
	end
	love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a or 1)
	love.graphics.setLineWidth(self.width)
	love.graphics.line(self.points)
	self:draw_selection_box()
end

---@param dx number
---@param dy number
function Line:move(dx, dy)
	for i = 1, #self.points, 1 do
		if i % 2 == 0 then
			self.points[i] = self.points[i] + dy
		else
			self.points[i] = self.points[i] + dx
		end
	end
	self.x = self.x + dx
	self.y = self.y + dy
end

-- RECTANGLE

---@class Rectangle: Tool
---@field width number
---@field mode "fill"|"line"
---@field color Color
---@field start { x : number, y : number }|nil
---@field end_ { x : number, y : number }|nil
---@field moving boolean
local Rectangle = Tool:new()

---@param linewidth number
---@param color Color
---@return Rectangle
function Rectangle:new(linewidth, color)
	local l = {
		toolname = toolnames.rectangle,
		width = linewidth,
		mode = "fill",
		color = color,
		start = nil,
		end_ = nil,
		moving = false,
		default_name = "Rectangle",
	}

	setmetatable(l, self)
	self.__index = self
	return l
end

---@param o table
function Tool:deserialize(o)
	local t = self:new()

	for key, value in pairs(o) do
		t[key] = value
	end

	return t
end

function Rectangle:draw()
	if self.start == nil or self.end_ == nil then
		return
	end
	local opacity = self.color.a or 1
	if self.building then
		opacity = 0.3
	end
	love.graphics.setColor(self.color.r, self.color.g, self.color.b, opacity)
	love.graphics.setLineWidth(self.width)

	if self.building then
		local x1, y1, x2, y2 =
			math.min(self.start.x, self.end_.x),
			math.min(self.start.y, self.end_.y),
			math.max(self.start.x, self.end_.x),
			math.max(self.start.y, self.end_.y)
		love.graphics.rectangle(self.mode, x1, y1, x2 - x1, y2 - y1)
	else
		love.graphics.rectangle(self.mode, self.x, self.y, self.w, self.h)
	end
	self:draw_selection_box()
end

function Rectangle:mousepressed(x, y)
	self.building = true
	self.start = { x = x, y = y }
	self.end_ = { x = x, y = y }
	return true
end

function Rectangle:mousemoved(x, y)
	if self.building then
		self.end_ = { x = x, y = y }
		return true
	end
	return false
end

function Rectangle:set_dimensions()
	local x1, y1, x2, y2 =
		math.min(self.start.x, self.end_.x),
		math.min(self.start.y, self.end_.y),
		math.max(self.start.x, self.end_.x),
		math.max(self.start.y, self.end_.y)
	self.x = x1
	self.y = y1
	self.w = x2 - x1
	self.h = y2 - y1
end

function Rectangle:mousereleased()
	if self.building then
		self.building = false
		self:set_dimensions()
		return true
	end
	return false
end

function Rectangle:keypressed(combo)
	if self.building and combo == "Ctrl+=" then
		self.equal_sides = not self.equal_sides
		return true
	end
	return false
end

---@param dx number
---@param dy number
function Rectangle:move(dx, dy)
	print("moving (" .. dx .. ", " .. dy .. ")")
	self.x = self.x + dx
	self.y = self.y + dy
end

-- TEXT

---@class Text: Tool
---@field width number
---@field color Color
---@field start { x : number, y : number }|nil
---@field text string
---@field size number
---@field blink_ts number
---@field blink_on boolean
local Text = Tool:new()

---@param linewidth number
---@param color Color
---@return Text
function Text:new(linewidth, color)
	---@type Text
	local l = {
		toolname = toolnames.text,
		width = linewidth,
		color = color,
		start = nil,
		text = "",
		size = 14,
		blink_ts = 0,
		blink_on = false,
		default_name = "Text",
	}

	setmetatable(l, self)
	self.__index = self
	return l
end

function Text:update(dt)
	self.blink_ts = self.blink_ts + dt
	if self.blink_ts >= 0.5 then
		self.blink_on = not self.blink_on
		self.blink_ts = 0
	end
end

function Text:draw()
	if self.start == nil then
		return
	end
	local text = self.text
	if self.building and self.blink_on then
		text = text .. "|"
	elseif self.building then
		text = text .. " "
	end
	love.graphics.setNewFont(self.size)
	if self.building then
		love.graphics.setColor(0.75, 0.75, 0.75, 0.25)
		love.graphics.setLineWidth(1)
		local text_drawable = love.graphics.newText(love.graphics.getFont(), text)
		local textw, texth = text_drawable:getDimensions()
		love.graphics.rectangle("line", self.start.x - 10, self.start.y - 10, textw + 20, texth + 20)
	end
	local opacity = self.color.a or 1
	love.graphics.setColor(self.color.r, self.color.g, self.color.b, opacity)
	love.graphics.setLineWidth(self.width)

	love.graphics.print(text, self.start.x, self.start.y)
end

function Text:keypressed(combo)
	local validkey, letter = ascii_key_from_combo(combo)
	if self.building and validkey then
		self.text = self.text .. letter
		return true
	end
	if combo == "backspace" then
		self.text = string.sub(self.text, 1, #self.text - 1)
		return true
	end
	if combo == "Ctrl+b" then
		self.size = self.size + 2
		return true
	end
	return false
end

function Text:mousepressed(x, y)
	if self.building then
		self.building = false
		return true
	end
	self.building = true
	self.start = { x = x, y = y }
	return true
end

function Text:mousemoved()
	return false
end

function Text:mousereleased()
	return false
end

-- CIRCLE

---@class Circle: Tool
---@field width number
---@field mode "fill"|"line"
---@field color Color
---@field origin { x : number, y : number }|nil
---@field radiusx number
---@field radiusy number
---@field equal_sides boolean
local Circle = Tool:new()

---@param linewidth number
---@param color Color
---@return Circle
function Circle:new(linewidth, color)
	local l = {
		toolname = toolnames.circle,
		width = linewidth,
		mode = "fill",
		color = color,
		origin = nil,
		radiusx = 0,
		radiusy = 0,
		equal_sides = false,
		default_name = "Circle",
	}

	setmetatable(l, self)
	self.__index = self
	return l
end

function Circle:draw()
	if self.origin == nil or self.radiusy == 0 or self.radiusx == 0 then
		return
	end
	local opacity = self.color.a or 1
	if self.building then
		opacity = 0.3
	end
	love.graphics.setColor(self.color.r, self.color.g, self.color.b, opacity)
	love.graphics.setLineWidth(self.width)

	love.graphics.ellipse(self.mode, self.origin.x, self.origin.y, self.radiusx, self.radiusy)
end

function Circle:mousepressed(x, y)
	self.building = true
	self.origin = { x = x, y = y }
	return true
end

function Circle:mousemoved(x, y)
	if self.building and self.origin ~= nil then
		self.radiusx = math.abs(self.origin.x - x)
		self.radiusy = math.abs(self.origin.y - y)
		return true
	end
	return false
end

function Circle:mousereleased()
	if self.building then
		self.building = false
		return true
	end
	return false
end

function Circle:keypressed(combo)
	if self.building and combo == "Ctrl+=" then
		self.equal_sides = not self.equal_sides
		return true
	end
	return false
end

-- Deseralize tool

local toolfactory = function(t)
	local toolname = t["toolname"]
	if toolname == nil then
		return false, nil
	else
		local tool
		if toolname == 1 then
			tool = Rectangle:deserialize(t)
			tool:set_dimensions()
		elseif toolname == 2 then
			tool = Circle:deserialize(t)
		elseif toolname == 3 then
			tool = Line:deserialize(t)
			tool:set_dimensions()
		elseif toolname == 4 then
			tool = Text:deserialize(t)
		else
			tool = Tool:deserialize(t)
		end
		return true, tool
	end
end

-- EXPORTS

M.Line = Line
M.Rectangle = Rectangle
M.Text = Text
M.Circle = Circle
M.toolfactory = toolfactory
M.toolnames = toolnames

return M
