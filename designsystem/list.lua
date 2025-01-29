local View = require("view").View

local M = {}

local themedefaults = {
	bgcolor = { r = 1, g = 1, b = 1, a = 1 },
	hovercolor = { r = 0, g = 0, b = 0.75, a = 0.6 },
	textcolor = { r = 0, g = 0, b = 0, a = 1 },
}

local padding = 4

---@package
---@alias RGBA { r:number, g: number, b: number, a: number }

---@class List : View
---@field options love.Text[]
---@field rawoptions string[]
---@field fontsize? number
---@field onselected fun(value: string)
---@field itemh number
---@field constraints? { h?: number, w?: number }
---@field bgcolor RGBA
---@field hovercolor RGBA
---@field textcolor RGBA
---@field selected number
---@field focused boolean
local List = View:new()

---@param options string[]
---@param onselected fun(value: string)
---@param themeopts? { bgcolor? : RGBA, hovercolor? : RGBA, textcolor? : RGBA }
---@return List
function List:new(options, onselected, themeopts)
	themeopts = themeopts or themedefaults
	---@type love.Text[]
	local opts = {}
	local font = love.graphics.newFont(14)
	local itemh, itemw = 0, 0
	for i, opt in pairs(options) do
		table.insert(opts, love.graphics.newText(font, opt))
		local w, h = opts[i]:getDimensions()
		itemh = math.max(itemh, h)
		itemw = math.max(itemw, w)
	end

	---@type List
	local list = {
		options = opts,
		rawoptions = options,
		onselected = onselected,
		itemh = itemh,
		bgcolor = themeopts.bgcolor or themedefaults.bgcolor,
		hovercolor = themeopts.hovercolor or themedefaults.hovercolor,
		textcolor = themeopts.textcolor or themedefaults.textcolor,
		h = itemh * 3 + (padding * 2),
		w = itemw + (padding * 2),
		selected = 0,
		focused = false,
	}

	setmetatable(list, self)
	self.__index = self

	return list
end

function List:keypressed(combo)
	if combo == "down" and self.focused then
		self.selected = math.min(#self.options, self.selected + 1)
		self.onselected(self.rawoptions[self.selected])
		return true
	end
	if combo == "up" and self.focused then
		self.selected = math.max(0, self.selected - 1)
		self.onselected(self.rawoptions[self.selected])
		return true
	end
	if combo == "esc" and self.focused then
		self.focused = false
		return true
	end
	return false
end

function List:mousepressed(x, y)
	if self:inarea(x, y) then
		self.focused = true
		if #self.options > 0 then
			self.selected = 1
			self.onselected(self.rawoptions[self.selected])
		end
		return true
	end
	return false
end

function List:draw()
	love.graphics.setColor(self.bgcolor.r, self.bgcolor.g, self.bgcolor.b, self.bgcolor.a)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	local posy = self.y + padding
	for i, opt in pairs(self.options) do
		if self.selected == i then
			love.graphics.setColor(self.hovercolor.r, self.hovercolor.g, self.hovercolor.b, self.hovercolor.a)
			love.graphics.rectangle("fill", self.x, posy - padding, self.w, self.itemh + (padding * 2))
		end
		love.graphics.setColor(self.textcolor.r, self.textcolor.g, self.textcolor.b, self.textcolor.a)
		love.graphics.draw(opt, self.x + padding, posy)
		posy = posy + self.itemh + padding
	end
end

M.List = List

return M
