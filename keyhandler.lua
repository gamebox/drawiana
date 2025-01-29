local M = {}

---@class KeyHandler
---@field key string|nil
---@field shiftdown boolean
---@field ctrldown boolean
---@field altdown boolean
---@field metadown boolean
local KeyHandler = {
	key = nil,
	shiftdown = false,
	ctrldown = false,
	altdown = false,
	superdown = false,
}

---@return KeyHandler
function KeyHandler:new()
	local kh = {}
	setmetatable(kh, self)
	self.__index = self
	return kh
end

---@param scancode string
---@return boolean, string|nil
function KeyHandler:keypressed(scancode)
	if scancode == "lshift" or scancode == "rshift" then
		self.shiftdown = true
	elseif scancode == "lctrl" or scancode == "rctrl" then
		self.ctrldown = true
	elseif scancode == "lalt" or scancode == "ralt" then
		self.altdown = true
	elseif scancode == "lgui" or scancode == "rgui" then
		self.metadown = true
	else
		self.key = scancode
	end

	if self.key ~= nil then
		local combo = self:createcombo()
		self.key = nil
		return true, combo
	else
		return false, nil
	end
end

---@param scancode string
function KeyHandler:keyreleased(scancode)
	if scancode == "lshift" or scancode == "rshift" then
		self.shiftdown = false
	elseif scancode == "lctrl" or scancode == "rctrl" then
		self.ctrldown = false
	elseif scancode == "lalt" or scancode == "ralt" then
		self.altdown = false
	elseif scancode == "lgui" or scancode == "rgui" then
		self.metadown = false
	end
end

---@return string
function KeyHandler:createcombo()
	local combo = ""
	if self.shiftdown then
		combo = combo .. "Shift+"
	end
	if self.ctrldown then
		combo = combo .. "Ctrl+"
	end
	if self.metadown then
		combo = combo .. "Meta+"
	end
	if self.altdown then
		combo = combo .. "Alt+"
	end
	combo = combo .. self.key

	return combo
end

M.KeyHandler = KeyHandler

return M
