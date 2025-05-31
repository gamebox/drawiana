local View = require("view").View
local ascii_key_from_combo = require("textkeys").ascii_key_from_combo
local fonts = require("fonts")

local M = {}

---@class Input : View
---@field rawText string
---@field font love.Font
---@field text love.Text
---@field normalto love.Text
---@field blinkto love.Text
---@field fontsize? number
---@field constraints? { h?: number, w?: number }
---@field focused boolean
---@field blink_on boolean
---@field blink_ts number
local Input = View:new()

---@param text? string
---@param fontsize? number
---@param constraints? { h?: number, w?: number }
---@return Input
function Input:new(text, fontsize, constraints)
	text = text or ""
	fontsize = fontsize or 14
	local font = fonts.get_regular_font(fontsize)
	local to = love.graphics.newText(font, text)
	local blinkto = love.graphics.newText(font, text .. "|")
	local w, h = to:getDimensions()
	if text == "" then
		w, h = blinkto:getDimensions()
	end
	if constraints ~= nil then
		-- Do something
	end
	---@type Input
	local input = {
		text = to,
		font = font,
		w = w + 4,
		h = h + 4,
		focused = false,
		rawText = text,
		blink_on = false,
		blink_ts = 0,
		normalto = to,
		blinkto = blinkto,
	}

	setmetatable(input, self)
	self.__index = self

	input:updatetextobjects()
	return input
end

---@param x number
---@param y number
---@diagnostic disable-next-line unused-local
function Input:mousemoved(x, y) end

---@param x number
---@param y number
---@return boolean
---@diagnostic disable-next-line unused-local
function Input:mousepressed(x, y)
	if self:inarea(x, y) then
		self.focused = true
		return true
	else
		self.focused = false
	end
	return false
end

---@param x number
---@param y number
---@return boolean
---@diagnostic disable-next-line unused-local
function Input:mousereleased(x, y)
	return false
end

---@param combo string
---@return boolean
---@diagnostic disable-next-line unused-local
function Input:keypressed(combo)
	local validkey, letter = ascii_key_from_combo(combo)
	local change = false
	if validkey then
		self.rawText = self.rawText .. letter
		change = true
	end
	if combo == "backspace" then
		self.rawText = string.sub(self.rawText, 1, #self.rawText - 1)
		change = true
	end
	if change then
		self:updatetextobjects()
		return true
	end
	return false
end

function Input:updatetextobjects()
	local text = self.rawText
	self.normalto = love.graphics.newText(self.font, text .. "|")
	self.blinkto = love.graphics.newText(self.font, text)
end

---@return boolean
function Input:keyreleased()
	return false
end

---@param dt number
function Input:update(dt)
	self.blink_ts = self.blink_ts + dt
	if self.blink_ts >= 0.5 then
		self.blink_on = not self.blink_on
		self.blink_ts = 0
	end
	if self.focused and self.blink_on then
		self.text = self.blinkto
	else
		self.text = self.normalto
	end
end

function Input:draw()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	if self.focused then
		love.graphics.setColor(0, 0, 0.75, 0.6)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
	end
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.draw(self.text, self.x + 2, self.y + 2)
	if self.focused and self.blink_on then
		love.graphics.draw(self.blinkto, self.x + 2, self.y + 2)
	else
		love.graphics.draw(self.normalto, self.x + 2, self.y + 2)
	end
end

M.Input = Input

return M
