local View = require("view").View

local M = {}

---@class Dialog : View
---@field content View
---@field shouldclose boolean
local Dialog = View:new()

---@alias ModalSize
---| '"sm"' # 300w x 200h
---| '"md"' # 450w x 300h
---| '"lg"' # 700w x 500h

---@param size ModalSize
---@return number w, number h
local dimensionsFromSize = function(size)
	if size == "sm" then
		return 300, 200
	elseif size == "md" then
		return 450, 300
	else
		return 700, 500
	end
end

---@param size ModalSize
---@param content fun(x: number, y: number, w: number, h: number): View
function Dialog:new(size, content)
	local window_w, window_h, _ = love.window.getMode()
	local w, h = dimensionsFromSize(size)
	local d = {
		window_w = window_w,
		window_h = window_h,
		w = w,
		h = h,
		x = math.floor((window_w - w) / 2),
		y = math.floor((window_h - h) / 2),
	}
	local c = content(d.x, d.y, w, h)
	d.content = c

	setmetatable(d, self)
	self.__index = self

	return d
end

function Dialog:keypressed(combo)
	if self.content:keypressed(combo) then
		return true
	end
	if combo == "escape" then
		self.shouldclose = true
		return true
	end
end

function Dialog:mousepressed(x, y)
	if self.content:mousepressed(x, y) then
		return true
	end
	if not self:inarea(x, y) then
		self.shouldclose = true
		return true
	end
	return false
end

function Dialog:mousemoved(x, y)
	if self.content:mousemoved(x, y) then
		return true
	end
end

function Dialog:mousereleased(x, y)
	if self.content:mousereleased(x, y) then
		return true
	end
end

function Dialog:update(dt)
	self.content:update(dt)
end

function Dialog:draw()
	love.graphics.setColor(0, 0, 0, 0.3)
	love.graphics.rectangle("fill", self.x + 8, self.y + 8, self.w, self.h)
	love.graphics.setColor(0.20, 0.20, 0.20, 1)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	love.graphics.setColor(0, 0, 0.75, 0.6)
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x - 2, self.y - 2, self.w + 4, self.h + 4)
	self.content:draw()
end

M.Dialog = Dialog

return M
