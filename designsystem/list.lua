local View = require("view").View

local M = {}

local themedefaults = {
	bgcolor = { r = 1, g = 1, b = 1, a = 1 },
	hovercolor = { r = 0, g = 0, b = 0.75, a = 0.6 },
	textcolor = { r = 0, g = 0, b = 0, a = 1 },
}

local padding = 4
local trackw = 8

---@package
---@alias RGBA { r:number, g: number, b: number, a: number }

---@class List : View
---@field options love.Text[]
---@field rawoptions string[]
---@field fontsize? number
---@field onselected fun(value: string, index: number)
---@field itemh number
---@field constraints? { h?: number, w?: number }
---@field bgcolor RGBA
---@field hovercolor RGBA
---@field textcolor RGBA
---@field selected number
---@field focused boolean
---@field needs_scroll boolean
---@field scroll_height number
---@field scroll_y number
---@field canvas love.Canvas
local List = View:new()

---@param options string[]
---@param onselected fun(value: string, index: number)
---@param themeopts? { bgcolor? : RGBA, hovercolor? : RGBA, textcolor? : RGBA }|nil
---@param sizeopts? { x : number, y : number, w : number, h : number }|nil
---@return List
function List:new(options, onselected, themeopts, sizeopts)
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

	local h = itemh * 3 + (padding * 2)
	local w = itemw + (padding * 2)

	---@type List
	local list = {
		options = opts,
		rawoptions = options,
		onselected = onselected,
		itemh = itemh,
		bgcolor = themeopts.bgcolor or themedefaults.bgcolor,
		hovercolor = themeopts.hovercolor or themedefaults.hovercolor,
		textcolor = themeopts.textcolor or themedefaults.textcolor,
		selected = 0,
		focused = false,
		needs_scroll = false,
		scroll_y = 0,
		scroll_height = #options * (itemh + padding),
		w = w,
		h = h,
		canvas = love.graphics.newCanvas(w, h),
	}
	if list.scroll_height > list.h then
		list.needs_scroll = true
	end

	if sizeopts ~= nil then
		list.h = sizeopts.h
		list.w = sizeopts.w
		list.x = sizeopts.x
		list.y = sizeopts.y
	end

	setmetatable(list, self)
	self.__index = self

	return list
end

function List:keypressed(combo)
	if combo == "down" and self.focused and #self.options > 0 then
		self.selected = math.min(#self.options, self.selected + 1)
		local selected_item_scroll_y = (self.itemh + padding) * self.selected
		if (selected_item_scroll_y - self.scroll_y) > self.h then
			self.scroll_y = self.scroll_y + self.h
		end
		self.onselected(self.rawoptions[self.selected], self.selected)
		return true
	end
	if combo == "up" and self.focused and #self.options > 0 then
		self.selected = math.max(1, self.selected - 1)
		local selected_item_scroll_y = (self.itemh + padding) * self.selected
		if (selected_item_scroll_y - self.scroll_y) <= 0 then
			self.scroll_y = self.scroll_y - self.h
		end
		self.onselected(self.rawoptions[self.selected], self.selected)
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
		if #self.options > 0 and self.selected == 0 then
			self.selected = 1
			self.onselected(self.rawoptions[self.selected], self.selected)
		end
		if x > (self.x + self.w - 8) then
		elseif #self.options > 0 then
			local local_y = y - self.y
			-- See if the click is within an option
			local posy = 0
			for i, _ in pairs(self.options) do
				local next_posy = posy + self.itemh + padding
				if local_y > posy and local_y <= next_posy then
					self.selected = i
					self.onselected(self.rawoptions[self.selected], self.selected)
					break
				end
				posy = next_posy
			end
		end
		return true
	end
	return false
end

---@param dt number
---@diagnostic disable-next-line unused-local
function List:update(dt)
	if self.canvas:getHeight() ~= self.h or self.canvas:getWidth() ~= self.w then
		self.canvas = love.graphics.newCanvas(math.max(1, self.w), math.max(1, self.h))
	end
	self.canvas:renderTo(function()
		love.graphics.clear(self.bgcolor.r, self.bgcolor.g, self.bgcolor.b, self.bgcolor.a or 1)
		local posy = padding - self.scroll_y
		for i, opt in pairs(self.options) do
			if self.selected == i then
				love.graphics.setColor(self.hovercolor.r, self.hovercolor.g, self.hovercolor.b, self.hovercolor.a)
				love.graphics.rectangle("fill", 0, posy - padding, self.w, self.itemh + (padding * 2))
			end
			love.graphics.setColor(self.textcolor.r, self.textcolor.g, self.textcolor.b, self.textcolor.a)
			love.graphics.draw(opt, padding, posy)
			posy = posy + self.itemh + padding
		end
		if self.needs_scroll then
			-- Scroll Track
			local trackx = self.w - trackw
			local thumbh = math.floor(self.h / self.scroll_height * 100) * self.h / 100
			love.graphics.setColor(0.60, 0.60, 0.60, 1)
			love.graphics.rectangle("fill", trackx, 0, trackw, self.h)

			-- Scroll Thumb
			love.graphics.setColor(0.40, 0.40, 0.40, 0.7)
			local percent_scrolled = math.floor(self.scroll_y / self.scroll_height * 100)
			local thumby = math.ceil(self.h * percent_scrolled / 100)
			love.graphics.rectangle("fill", trackx + 1, thumby, trackw - 2, thumbh)
		end
	end)
end

function List:draw()
	love.graphics.setColor(self.bgcolor.r, self.bgcolor.g, self.bgcolor.b, self.bgcolor.a)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(self.canvas, self.x, self.y)
	if self.focused then
		love.graphics.setColor(0, 0, 0.75, 0.3)
		love.graphics.setLineWidth(1)
		love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
	end
end

M.List = List

return M
