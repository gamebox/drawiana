local View = require("view").View
local List = require("designsystem.list").List

local M = {}

---@class LayerPanel : View
---@field list List
---@field selected number
local LayerPanel = View:new()

local padding = 4

---@param layers Tool[]
---@param x number
---@param y number
---@param w? number
---@param h? number
---@return LayerPanel
function LayerPanel:new(layers, x, y, w, h)
	local lp = {}

	setmetatable(lp, self)
	self.__index = self
	lp.h = h
	lp.w = w

	lp:new_layers(layers, true)
	lp.x = x
	lp.y = y
	return lp
end

---@param layers Tool[]
---@param focused boolean
function LayerPanel:new_layers(layers, focused)
	local layer_text = {}
	for _, layer in ipairs(layers) do
		local to = layer:get_name()
		table.insert(layer_text, to)
	end

	local selected = 0
	if #layer_text > 0 then
		selected = 1
	end

	if self.list ~= nil then
		focused = self.list.focused
		selected = self.list.selected
	end
	local x, y, w, h = self.x, self.y, self.w - (padding * 2), self.h - (padding * 2)
	self.list = List:new(
		layer_text,
		function(value, index)
			self:listchanged(value, index)
		end,
		nil,
		{
			x = x + padding,
			y = y + padding,
			w = math.max(0, (w or 200) - (padding * 2)),
			h = math.max(0, (h or 600) - (padding * 2)),
		}
	)
	self.selected = selected
	self.list.selected = self.selected
	self.list.focused = focused
end

function LayerPanel:select(index)
	self.list.selected = index
	self.selected = index
end

---@param _ string
---@param index number
function LayerPanel:listchanged(_, index)
	self.selected = index
end

---@param x number
---@param y number
function LayerPanel:mousemoved(x, y)
	if self.list:mousemoved(x, y) then
		return
	end
end

---@param x number
---@param y number
---@return boolean
function LayerPanel:mousepressed(x, y)
	if self:inarea(x, y) then
		self.list.focused = true
		if self.list:mousepressed(x, y) then
			return true
		end
		return true
	else
		self.list.focused = false
	end
	return false
end

---@param x number
---@param y number
---@return boolean
function LayerPanel:mousereleased(x, y)
	if self.list.focused and self.list:mousereleased(x, y) then
		return true
	end
	return false
end

---@param combo string
---@return boolean
function LayerPanel:keypressed(combo)
	if self.list.focused and combo == "escape" then
		self.list.focused = false
		return true
	elseif self.list.focused and self.list:keypressed(combo) then
		return true
	end
	return false
end

---@return boolean
function LayerPanel:keyreleased()
	if self.list.focused and self.list:keyreleased() then
		return true
	end
	return false
end

---@param dt number
function LayerPanel:update(dt)
	self.list:update(dt)
	self.list.x = self.x + padding
	self.list.y = self.y + padding
end

function LayerPanel:draw()
	love.graphics.setColor(0.20, 0.20, 0.20, 1)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	self.list:draw()
end

-- Export class table
M.LayerPanel = LayerPanel

-- Return module table
return M
