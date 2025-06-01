local M = {}

---@generic T
---@class Shortcut `T`
---@field combo string
---@field action function(self: T)
---@field condition function(self: T)
---@field description string
local Shortcut = {}

---@generic T
---@param combo string
---@param action function(self: `T`)
---@param condition function(self: T)
---@param description string
function Shortcut:new(combo, action, condition, description)
	local shortcut = setmetatable({}, self)
	self.__index = self

	shortcut.combo = combo
	shortcut.action = action
	shortcut.condition = condition
	shortcut.description = description

	return shortcut
end

-- A container for executing shortcuts
---@class Shortcuts
---@field shortcuts Shortcut[]
local Shortcuts = {
	shortcuts = {},
}

function Shortcuts:new(shortcuts)
	local s = setmetatable({}, self)
	self.__index = self
	s.shortcuts = shortcuts
	return shortcuts
end

---@generic T
---@param view T
---@return boolean
function Shortcuts:run(view)
	for _, shortcut in self.shortcuts do
		if shortcut.condition(view) then
			local res = shortcut:action(view)
			if res then
				return res
			end
		end
	end
	return false
end

---@param buf string.buffer
function Shortcuts:dump(buf)
	for _, shortcut in self.shortcuts do
		buf.put(shortcut.description, "\n")
	end
end

M.Shortcut = Shortcut
M.Shortcuts = Shortcuts

return M
