local View = require("view").View
local Controls = require("controls").Controls
local toolfactory = require("tools").toolfactory
local file_format = require("file_format")
local dialog = require("dialog")
local heading = require("designsystem.heading")
local input = require("designsystem.input")
local button = require("designsystem.button")
local layer_panel = require("layer_panel")

local M = {}

---@class Editor : View
---@field controls Controls
---@field current_tool Tool
---@field stack Tool[]
---@field undo_stack Tool[]
---@field open_dialog Dialog|nil
---@field currentfilename string|nil
---@field layer_panel LayerPanel|nil
local Editor = View:new()

function Editor:debug()
	print("===", "Editor:debug", "===")
	print("Controls", self.controls)
	print("Current Tool", self.current_tool:get_name())
	print("---", "Stack:", self.stack, "---")
	for _, tool in ipairs(self.stack) do
		print("   ", tool:get_name(), tool)
	end
	print("---", "Stack END", "---")
	print("---", "Undo Stack", self.undo_stack, "---")
	for _, tool in ipairs(self.undo_stack) do
		print("   ", tool:get_name(), tool)
	end
	print("---", "Undo Stack END", "---")
	if self.currentfilename then
		print("Using filename", self.currentfilename)
	else
		print("No filename")
	end
	if self.open_dialog then
		print("Dialog open", self.open_dialog)
	else
		print("Dialog closed", self.open_dialog)
	end
	if self.layer_panel then
		print("Layer Panel open", self.layer_panel)
	else
		print("Layer Panel closed", self.layer_panel)
	end
	print("===", "Editor:debug END", "===")
end

function Editor:push_current_on_stack()
	table.insert(self.stack, self.current_tool)
	self.current_tool = self.controls:newtool()
	self.undo_stack = {}
end

---@param name? string|nil
---@return Editor
function Editor:new(name)
	local stack = {}
	if name ~= nil and name ~= "" then
		print("Opening " .. name)
		local file, ok, err, state
		file, err = love.filesystem.newFile(name, "r")
		_, err = file:open("r")
		if err ~= nil and err ~= "" then
			print("Could not open file: " .. (err or "No error specified"))
		end
		ok, state = file_format.FileFormat:deserialize(file)
		file:close()
		if ok and state ~= nil then
			for _, t in pairs(state.stack) do
				local tool
				ok, tool = toolfactory(t)
				if ok then
					table.insert(stack, tool)
				end
			end
		else
			print("Could not read file: " .. (err or "No error specified"))
		end
	end

	local w, h, _ = love.window.getMode()
	local controls_height = 50
	local controls = Controls:new(0, h - controls_height, controls_height, w)
	local editor = {
		h = h,
		w = w,
		x = 0,
		y = 0,
		controls = controls,
		current_tool = controls:newtool(),
		stack = stack,
		undo_stack = {},
		save_file_dialog = nil,
		currentfilename = name,
	}

	setmetatable(editor, self)
	self.__index = self

	return editor
end

function Editor:mousemoved(x, y)
	if self.open_dialog ~= nil then
		self.open_dialog:mousemoved(x, y)
		return
	end
	if self.layer_panel ~= nil then
		self.layer_panel:mousemoved(x, y)
		return
	end
	self.current_tool:mousemoved(x, y)
	self.controls:mousemoved(x, y)
end

---@param x number
---@param y number
function Editor:mousepressed(x, y)
	if self.open_dialog ~= nil then
		if self.open_dialog:mousepressed(x, y) and self.open_dialog.shouldclose then
			self.open_dialog = nil
		end
		return true
	end
	if self.layer_panel ~= nil then
		self.layer_panel:mousepressed(x, y)
		return
	end
	if self.controls:mousepressed(x, y) then
		self.current_tool = self.controls:newtool()
		return
	end
	if self.current_tool:mousepressed(x, y) then
		if not self.current_tool.building then
			self:push_current_on_stack()
		end
		return
	end
end

function Editor:mousereleased(x, y)
	self.controls:mousereleased(x, y)
	if self.open_dialog ~= nil then
		self.open_dialog:mousereleased(x, y)
		return true
	end
	if self.layer_panel ~= nil then
		self.layer_panel:mousereleased(x, y)
		return
	end
	if self.current_tool:mousereleased(x, y) then
		if not self.current_tool.building then
			self:push_current_on_stack()
		end
		return
	end
end

function Editor:keyreleased()
	if self.open_dialog ~= nil then
		self.open_dialog:keyreleased()
		return true
	end
	if self.layer_panel ~= nil then
		self.layer_panel:keyreleased()
		return
	end
end

function Editor:open_save_dialog()
	self:open_text_entry_dialog("Save file", self.currentfilename or "", function(inp)
		self:save(inp.rawText)
	end)
end

---@param layer Tool
function Editor:open_layer_name_change_dialog(layer)
	local zelf = self
	self:open_text_entry_dialog("Change layer name", layer:get_name() or "", function(inp)
		layer.name = inp.rawText
		zelf.layer_panel:new_layers(self.stack, true)
	end)
end

---@param title string
---@param initial string
---@param okclicked function(input: Input)
function Editor:open_text_entry_dialog(title, initial, okclicked)
	if self.open_dialog ~= nil then
		return
	end
	self.open_dialog = dialog.Dialog:new("sm", function(xoffset, yoffset, w, h)
		local Meta = View:new()
		local view = setmetatable({}, Meta)
		Meta.__index = Meta

		local head = heading.Heading:new(title, 24)
		local inp = input.Input:new(initial)
		local okbutton = button.Button:new("Ok", function()
			okclicked(inp)
			self:dismiss_save_dialog()
		end)
		local cancelbutton = button.Button:new("Cancel", function()
			self:dismiss_save_dialog()
		end)

		table.insert(view.children, head)
		table.insert(view.children, inp)
		table.insert(view.children, okbutton)
		table.insert(view.children, cancelbutton)

		local padding = 8

		head.x = xoffset + padding
		head.y = yoffset + padding
		inp.x = xoffset + padding
		inp.y = yoffset + (h / 2) - (inp.h / 2)
		inp.w = w - (padding * 2)
		okbutton.x = xoffset + w - okbutton.w - padding
		okbutton.y = yoffset + h - okbutton.h - padding
		cancelbutton.x = okbutton.x - 4 - cancelbutton.w
		cancelbutton.y = okbutton.y

		return view
	end)
end

---@param name? string|nil
function Editor:save(name)
	name = name or self.currentfilename
	if name ~= nil then
		local file, _ = love.filesystem.newFile(name)
		if file == nil then
			self.open_dialog = nil
			return
		end
		local opened, err = file:open("w")
		if not opened then
			print("couldn't open: " .. err)
			self.open_dialog = nil
			return
		end
		local success, err_ = file_format.FileFormat:persist(file, self.stack, {})
		if not success then
			print("couldn't save: " .. err_)
		end
		file:close()
		self.open_dialog = nil
	end
end

function Editor:dismiss_save_dialog()
	self.open_dialog = nil
end

function Editor:toggle_layer_panel()
	if self.layer_panel == nil then
		self.layer_panel = layer_panel.LayerPanel:new(self.stack, self.w - 300, 0, 300, math.floor(self.h / 3))
	else
		self.layer_panel = nil
	end
end

---@param combo string
---@return boolean
function Editor:keypressed(combo)
	if combo == "Shift+Meta+d" then
		self:debug()
		return true
	end
	if combo == "Meta+s" then
		self:open_save_dialog()
		return true
	end
	if combo == "Meta+l" then
		self:toggle_layer_panel()
		return true
	end
	if combo == "Meta+backspace" and self.layer_panel ~= nil and self.layer_panel.selected > 0 then
		table.remove(self.stack, self.layer_panel.selected)
		if self.layer_panel ~= nil and #self.stack > 0 then
			local new_selected = self.layer_panel.selected - 1
			self.layer_panel:new_layers(self.stack, true)
			self.layer_panel:select(new_selected)
		end
		return true
	end
	if self.open_dialog ~= nil then
		if self.open_dialog:keypressed(combo) and self.open_dialog.shouldclose then
			self.open_dialog = nil
		end
		return true
	end
	if self.layer_panel ~= nil then
		if combo == "Meta+r" then
			self:open_layer_name_change_dialog(self.stack[self.layer_panel.selected])
			return true
		end
		if self.layer_panel:keypressed(combo) then
			return true
		end
	end
	if self.layer_panel ~= nil and self.layer_panel.selected > 0 then
		local selected_tool = self.stack[self.layer_panel.selected]
		if combo == "up" then
			selected_tool:move(0, -1)
			return true
		elseif combo == "down" then
			selected_tool:move(0, 1)
			return true
		elseif combo == "left" then
			selected_tool:move(-1, 0)
			return true
		elseif combo == "right" then
			selected_tool:move(1, 0)
			return true
		elseif combo == "Shift+up" then
			selected_tool:move(0, -10)
			return true
		elseif combo == "Shift+down" then
			selected_tool:move(0, 10)
			return true
		elseif combo == "Shift+left" then
			selected_tool:move(-10, 0)
			return true
		elseif combo == "Shift+right" then
			selected_tool:move(10, 0)
			return true
		elseif combo == "Meta+up" then
			local sel = self.layer_panel.selected
			if sel <= 1 then
				return true
			end
			local swapping = self.stack[sel - 1]
			local curr = self.stack[sel]
			self.stack[sel - 1] = curr
			self.stack[sel] = swapping
			self.layer_panel:new_layers(self.stack, true)
			self.layer_panel:select(sel - 1)
			return true
		elseif combo == "Meta+down" then
			local sel = self.layer_panel.selected
			if sel > (#self.stack - 1) then
				return true
			end
			local swapping = self.stack[sel + 1]
			local curr = self.stack[sel]
			self.stack[sel + 1] = curr
			self.stack[sel] = swapping
			self.layer_panel:new_layers(self.stack, true)
			self.layer_panel:select(sel + 1)
			return true
		elseif combo == "Shift+Meta+down" then
			print("Moving to the top")
			table.remove(self.stack, self.layer_panel.selected)
			table.insert(self.stack, selected_tool)
			self.layer_panel:select(#self.stack)
			self.layer_panel:new_layers(self.stack, true)
			return true
		elseif combo == "Shift+Meta+up" then
			print("Moving to the bottom")
			table.remove(self.stack, self.layer_panel.selected)
			table.insert(self.stack, 1, selected_tool)
			self.layer_panel:new_layers(self.stack, true)
			self.layer_panel:select(1)
			return true
		end
	end
	if self.current_tool:keypressed(combo) then
		if not self.current_tool.building then
			self:push_current_on_stack()
		end
		return true
	end
	if self.controls:keypressed(combo) then
		self.current_tool = self.controls:newtool()
		return true
	end
	if combo == "u" then
		local undone = table.remove(self.stack, #self.stack)
		if self.layer_panel ~= nil then
			self.layer_panel = layer_panel.LayerPanel:new(self.stack, self.w - 300, 0, 300)
		end
		table.insert(self.undo_stack, undone)
		return true
	elseif combo == "Shift+u" and #self.undo_stack > 0 then
		local redone = table.remove(self.undo_stack, #self.undo_stack)
		table.insert(self.stack, redone)
		if self.layer_panel ~= nil then
			self.layer_panel = layer_panel.LayerPanel:new(self.stack, self.w - 300, 0, 300)
		end
		return true
	end
	return false
end

function Editor:update(dt)
	if self.open_dialog ~= nil then
		self.open_dialog:update(dt)
	end
	if self.layer_panel ~= nil then
		self.layer_panel:update(dt)
		return
	end
	self.controls:update(dt)
	self.current_tool:update(dt)
end

function Editor:draw()
	for i, tool in pairs(self.stack) do
		if self.layer_panel and self.layer_panel.selected == i then
			local real_color = tool.color
			tool.color = { r = real_color.r, g = real_color.g, b = real_color.b, a = (real_color.a or 1) * 0.3 }
			tool:draw()
			tool.color = real_color
		else
			tool:draw()
		end
	end
	self.current_tool:draw()

	self.controls:draw()
	love.graphics.setColor(1, 1, 1, 1)
	if self.layer_panel ~= nil then
		self.layer_panel:draw()
	end
	if self.open_dialog ~= nil then
		self.open_dialog:draw()
	end
end

M.Editor = Editor

return M
