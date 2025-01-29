local View = require("view").View

local M = {}

---@class Button : View
---@field text love.Text
---@field fontsize? number
---@field onclick function
---@field hovered boolean
---@field pressed boolean
---@field constraints? { h?: number, w?: number }
---@field bgcolor { r:number, g: number, b: number, a: number }
---@field hovercolor { r:number, g: number, b: number, a: number }
---@field textcolor { r:number, g: number, b: number, a: number }
local Button = View:new()

---@param text string
---@param onclick function
---@param fontsize? number
---@param constraints? { h?: number, w?: number }
---@return Button
function Button:new(text, onclick, fontsize, constraints)
	fontsize = fontsize or 14
	local font = love.graphics.newFont(fontsize)
	local to = love.graphics.newText(font, text)
	local w, h = to:getDimensions()
	if constraints ~= nil then
		-- Do something
	end
	local button = {
		text = to,
		w = w + 8,
		h = h + 8,
		onclick = onclick,
		hovered = false,
		pressed = false,
		bgcolor = { r = 0.33, g = 0.33, b = 0.33, a = 1 },
		hovercolor = { r = 0.37, g = 0.37, b = 0.37, a = 1 },
		textcolor = { r = 1, g = 1, b = 1, a = 1 },
	}

	setmetatable(button, self)
	self.__index = self

	return button
end

function Button:mousepressed(x, y)
	if self:inarea(x, y) then
		self.pressed = true
		return true
	end
	return false
end

function Button:mousemoved(x, y)
	if self:inarea(x, y) then
		self.hovered = true
		return
	end
	if self.hovered then
		self.hovered = false
		return
	end
end

function Button:mousereleased(x, y)
	if self:inarea(x, y) and self.pressed then
		self.onclick()
		self.pressed = false
	end
end

function Button:draw()
	if self.hovered then
		love.graphics.setColor(self.hovercolor.r, self.hovercolor.g, self.hovercolor.b, self.hovercolor.a)
	else
		love.graphics.setColor(self.bgcolor.r, self.bgcolor.g, self.bgcolor.b, self.bgcolor.a)
	end
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	if self.pressed then
		love.graphics.setColor(0, 0, 0.75, 0.6)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
	end
	love.graphics.setColor(self.textcolor.r, self.textcolor.g, self.textcolor.b, self.textcolor.a)
	love.graphics.draw(self.text, self.x + 4, self.y + 4)
end

M.Button = Button

return M
