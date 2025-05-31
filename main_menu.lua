local View = require("view").View
local Dialog = require("dialog").Dialog
local Heading = require("designsystem.heading").Heading
local Button = require("designsystem.button").Button
local list = require("designsystem.list")

local M = {}

local toppadding = 100
local titlemargin = 50
local optionmargin = 20

---@class MainMenu: View
---@field title love.Text
---@field titlew number
---@field titleh number
---@field titlestartx number
---@field options love.Text[]
---@field optionh number
---@field selected number
---@field load_new fun(name?: string|nil)
---@field dialog Dialog|nil
---@field selectedfile string|nil
local MainMenu = View:new()

---@param load_new fun(name?: string|nil)
function MainMenu:new(load_new)
	local w, h, _ = love.window.getMode()
	local font = love.graphics.newFont(48)
	local option_font = love.graphics.newFont(32)
	local mm = {
		w = w,
		h = h,
		title = love.graphics.newText(font, "DRAWIANA"),
		options = {},
		selected = 1,
		load_new = load_new,
		selectedfile = nil,
	}
	local titlew, titleh = mm.title:getDimensions()
	mm.titleh = titleh
	mm.titlew = titlew
	mm.titlestartx = (mm.w - titlew) / 2
	table.insert(mm.options, love.graphics.newText(option_font, "New File"))
	table.insert(mm.options, love.graphics.newText(option_font, "Open File"))
	table.insert(mm.options, love.graphics.newText(option_font, "Quit"))
	local _, optionh = mm.options[1]:getDimensions()
	mm.optionh = optionh
	setmetatable(mm, self)
	self.__index = self
	return mm
end

function MainMenu:keypressed(combo)
	print("MainMenu:keypressed combo=" .. combo)
	if self.dialog ~= nil then
		self.dialog:keypressed(combo)
		local openfile = false
		if self.selectedfile ~= nil and combo == "return" then
			self.dialog.shouldclose = true
			openfile = true
		end
		if self.dialog ~= nil and self.dialog.shouldclose then
			self.dialog = nil
		end
		if openfile then
			self.load_new(self.selectedfile)
		end
		return
	end
	if combo == "down" then
		if self.selected == #self.options then
			self.selected = 1
		else
			self.selected = self.selected + 1
		end
	elseif combo == "up" then
		if self.selected == 0 then
			self.selected = #self.options
		else
			self.selected = self.selected - 1
		end
	elseif combo == "return" then
		self:handleselected()
	end
end

---@param x number
---@param y number
function MainMenu:mousemoved(x, y)
	if self.dialog ~= nil then
		self.dialog:mousemoved(x, y)
	end
	local optiony = toppadding + self.titleh + titlemargin
	if x < self.titlestartx or x > (self.titlestartx + self.titlew) or y < optiony then
		self.selected = 0
		return
	end
	for i, _ in pairs(self.options) do
		optiony = optiony + self.optionh + optionmargin
		if y < optiony then
			self.selected = i
			return
		end
	end
end

---@param x number
---@param y number
function MainMenu:mousepressed(x, y)
	if self.dialog ~= nil and self.dialog:mousepressed(x, y) then
		if self.dialog.shouldclose then
			self.dialog = nil
		end
		return
	end
	if self:handleselected() then
		return
	end
end

---@param x number
---@param y number
function MainMenu:mousereleased(x, y)
	if self.dialog ~= nil and self.dialog:mousereleased(x, y) then
		return
	end
end

function MainMenu:handleselected()
	if self.selected == 1 then
		self.load_new()
		return true
	elseif self.selected == 2 then
		self.dialog = Dialog:new("md", function(x, y, w, h)
			return self:createdialogcontent(x, y, w, h)
		end)
		return true
	elseif self.selected == 3 then
		love.event.quit(0)
	end
	return false
end

---@return View
function MainMenu:createdialogcontent(xoffset, yoffset, width, height)
	---@type string[]
	local diritems = love.filesystem.getDirectoryItems("")
	local files = {}
	for _, item in pairs(diritems) do
		local start, _, _ = item:find(".drawiana$")
		if start then
			table.insert(files, item)
		end
	end

	local padding = 8
	local view = {}
	view.x = xoffset
	view.y = yoffset
	view.heading = Heading:new("Choose file", 20)
	view.heading.x = xoffset + padding
	view.heading.y = yoffset + padding
	view.list = list.List:new(files, function(value)
		self.selectedfile = value
	end)
	view.list.h = 200
	view.list.w = width - (padding * 2)
	view.list.x = xoffset + padding
	view.list.y = yoffset + view.heading.h + (padding * 2)
	if #files > 0 then
		view.list.selected = 1
		view.list.focused = true
	end
	view.button = Button:new("OK", function()
		self.dialog = nil
		self.load_new(self.selectedfile)
	end)
	view.button.x = xoffset + width - view.button.w - padding
	view.button.y = yoffset + height - view.button.h - padding
	local meta = View:new()
	setmetatable(view, meta)
	meta.__index = meta
	view.draw = function(zelf)
		zelf.heading:draw()
		zelf.list:draw()
		zelf.button:draw()
	end
	view.update = function(zelf, dt)
		zelf.heading:update(dt)
		zelf.list:update(dt)
		zelf.button:update(dt)
	end
	view.mousepressed = function(zelf, x, y)
		if zelf.heading:mousepressed(x, y) then
			return true
		end
		if zelf.list:mousepressed(x, y) then
			return true
		end
		if zelf.button:mousepressed(x, y) then
			return true
		end
	end
	view.mousemoved = function(zelf, x, y)
		if zelf.heading:mousemoved(x, y) then
			return true
		end
		if zelf.list:mousemoved(x, y) then
			return true
		end
		if zelf.button:mousemoved(x, y) then
			return true
		end
	end
	view.mousereleased = function(zelf, x, y)
		if zelf.heading:mousereleased(x, y) then
			return true
		end
		if zelf.list:mousereleased(x, y) then
			return true
		end
		if zelf.button:mousereleased(x, y) then
			return true
		end
	end
	view.keypressed = function(zelf, combo)
		if combo == "tab" then
			if zelf.list.focused then
				zelf.list.focused = false
				zelf.button.focused = true
			elseif zelf.button.focused then
				zelf.button.focused = false
				zelf.list.focused = true
			else
				zelf.list.focused = true
			end
			return true
		end
		if zelf.heading:keypressed(combo) then
			return true
		end
		if zelf.list:keypressed(combo) then
			return true
		end
		if zelf.button:keypressed(combo) then
			return true
		end
	end

	return view
end

function MainMenu:draw()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(self.title, self.titlestartx, toppadding)
	local optiony = toppadding + self.titleh + titlemargin
	for i, option in pairs(self.options) do
		if self.selected == i then
			love.graphics.setColor(0.77, 0.55, 0.55, 1)
		else
			love.graphics.setColor(1, 1, 1, 1)
		end
		local optionw, _ = option:getDimensions()
		local optionx = (self.w - optionw) / 2
		love.graphics.draw(option, optionx, optiony)
		optiony = optiony + self.optionh + optionmargin
	end
	if self.dialog ~= nil then
		self.dialog:draw()
	end
end

function MainMenu:update(dt)
	if self.dialog ~= nil then
		self.dialog:update(dt)
	end
end

M.MainMenu = MainMenu

return M
