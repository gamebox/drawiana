local M = {}

---@class View
---@field x number
---@field y number
---@field h number
---@field w number
---@field active boolean
local View = {}

function View:new()
	local v = {
		x = 0,
		y = 0,
		h = 0,
		w = 0,
		active = true,
	}
	setmetatable(v, self)
	self.__index = self
	return v
end

---@param x number
---@param y number
---@diagnostic disable-next-line unused-local
function View:mousemoved(x, y) end

---@param x number
---@param y number
---@return boolean
---@diagnostic disable-next-line unused-local
function View:mousepressed(x, y)
	return false
end

---@param x number
---@param y number
---@return boolean
---@diagnostic disable-next-line unused-local
function View:mousereleased(x, y)
	return false
end

---@param combo string
---@return boolean
---@diagnostic disable-next-line unused-local
function View:keypressed(combo)
	return false
end

---@return boolean
function View:keyreleased()
	return false
end

---@param dt number
---@diagnostic disable-next-line unused-local
function View:update(dt) end

function View:draw() end

---@param x number
---@param y number
---@return boolean
function View:inarea(x, y)
	return x > self.x and x < (self.x + self.w) and y > self.y and y < (self.y + self.h)
end

M.View = View

return M
