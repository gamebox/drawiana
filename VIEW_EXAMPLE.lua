-- THIS IS ONLY AN EXAMPLE.  DO NOT USE.  TODO: remove this once copied into a file and you have renamed VIEWEXAMPLE to your View's name
-- Import View parent class for all views
local View = require("view").View

-- Create module table
local M = {}

-- Create class table
---THIS SHOULD NOT BE IMPORTED OR USED TODO: remove this AND the following line once copied into a file
---@package
---@class VIEWEXAMPLE : View
local VIEWEXAMPLE = View:new()

-- Constructor for class
---@return VIEWEXAMPLE
function VIEWEXAMPLE:new()
	-- Initialization.  TODO: remove this when implemented

	-- Create table for instance
	---@type VIEWEXAMPLE
	local lp = {}

	-- Subclass logic
	setmetatable(lp, self)
	self.__index = self

	-- Return instance
	return lp
end

-- Create overrides for View lifecycle methods

---@param x number
---@param y number
---@return boolean
---@diagnostic disable-next-line unused-local TODO: remove this when implemented
function VIEWEXAMPLE:mousemoved(x, y) end

---@param x number
---@param y number
---@return boolean
---@diagnostic disable-next-line unused-local TODO: remove this when implemented
function VIEWEXAMPLE:mousepressed(x, y)
	return false
end

---@param x number
---@param y number
---@return boolean
---@diagnostic disable-next-line unused-local TODO: remove this when implemented
function VIEWEXAMPLE:mousereleased(x, y)
	return false
end

---@param combo string
---@return boolean
---@diagnostic disable-next-line unused-local TODO: remove this when implemented
function VIEWEXAMPLE:keypressed(combo)
	return false
end

---@return boolean
function VIEWEXAMPLE:keyreleased()
	return false
end

---@param dt number
---@diagnostic disable-next-line unused-local TODO: remove this when implemented
function VIEWEXAMPLE:update(dt) end

function VIEWEXAMPLE:draw() end

-- Export class table
M.VIEWEXAMPLE = VIEWEXAMPLE

-- Return module table
return M
