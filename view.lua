local utils = require("utils")
local shortcuts = require("shortcuts")

local M = {}

---@class View
---@field x number
---@field y number
---@field h number
---@field w number
---@field active boolean
---@field children View[]
---@field shortcuts Shortcuts
local View = {}

function View:new(extended)
	---@type View
	local v = setmetatable({
		x = 0,
		y = 0,
		h = 0,
		w = 0,
		active = true,
		children = {},
		shortcuts = shortcuts.Shortcuts:new(),
	}, self)

	utils.extend_table(v, extended or {})

	self.__index = self
	return v
end

---@param x number
---@param y number
---@diagnostic disable-next-line unused-local
function View:mousemoved(x, y)
	for _, child in ipairs(self.children) do
		child:mousemoved(x, y)
	end
end

---@param x number
---@param y number
---@return boolean
---@diagnostic disable-next-line unused-local
function View:mousepressed(x, y)
	for _, child in ipairs(self.children) do
		if child:mousepressed(x, y) then
			return true
		end
	end
	return false
end

---@param x number
---@param y number
---@return boolean
---@diagnostic disable-next-line unused-local
function View:mousereleased(x, y)
	for _, child in ipairs(self.children) do
		if child:mousereleased(x, y) then
			return true
		end
	end
	return false
end

---@param combo string
---@return boolean
---@diagnostic disable-next-line unused-local
function View:keypressed(combo)
	if self.shortcuts then
		if self.shortcuts:run(combo) then
			return true
		end
	end
	for _, child in ipairs(self.children) do
		if child:keypressed(combo) then
			return true
		end
	end
	return false
end

---@return boolean
function View:keyreleased()
	for _, child in ipairs(self.children) do
		if child:keyreleased() then
			return true
		end
	end
	return false
end

---@param dt number
---@diagnostic disable-next-line unused-local
function View:update(dt)
	for _, child in ipairs(self.children) do
		child:update(dt)
	end
end

function View:draw()
	for _, child in ipairs(self.children) do
		child:draw()
	end
end

---@param x number
---@param y number
---@return boolean
function View:inarea(x, y)
	return x > self.x and x < (self.x + self.w) and y > self.y and y < (self.y + self.h)
end

M.View = View

return M
