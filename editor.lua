local View = require("view").View
local Controls = require("controls").Controls
local toolfactory = require("tools").toolfactory
local dump = require("utils").dump
local file_format = require("file_format")
local dialog = require("dialog")
local heading = require("designsystem.heading")
local input = require("designsystem.input")
local button = require("designsystem.button")
local layer_panel = require("layer_panel")

local M = {}

---@class Editor : View
---@field h number
---@field w number
---@field controls Controls
---@field current_tool Tool
---@field stack Tool[]
---@field undo_stack Tool[]
---@field save_file_dialog Dialog|nil
---@field currentfilename string|nil
---@field layer_panel LayerPanel|nil
local Editor = View:new()

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
		local file, opened, ok, err, state
		file, err = love.filesystem.newFile(name, "r")
		opened, err = file:open("r")
		if not opened then
			print("Could not open file: " .. (err or "No error specified"))
		end
		ok, state = file_format.FileFormat:deserialize(file)
		file:close()
		if ok and state ~= nil then
			for _, t in pairs(state.stack) do
				local tool
				print(dump(t))
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
	if self.save_file_dialog ~= nil then
		self.save_file_dialog:mousemoved(x, y)
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
	if self.save_file_dialog ~= nil then
		if self.save_file_dialog:mousepressed(x, y) and self.save_file_dialog.shouldclose then
			self.save_file_dialog = nil
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
	if self.save_file_dialog ~= nil then
		self.save_file_dialog:mousereleased(x, y)
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
	if self.save_file_dialog ~= nil then
		self.save_file_dialog:keyreleased()
		return true
	end
	if self.layer_panel ~= nil then
		self.layer_panel:keyreleased()
		return
	end
end

function Editor:openSaveDialog()
	self.save_file_dialog = dialog.Dialog:new("sm", function(xoffset, yoffset, w, h)
		local view = {}
		local meta = View:new()
		setmetatable(view, meta)
		meta.__index = meta

		view.content = {}

		local head = heading.Heading:new("Save file", 24)
		local inp = input.Input:new(self.currentfilename or "")
		local okbutton = button.Button:new("Ok", function()
			self:save(inp.rawText)
		end)
		local cancelbutton = button.Button:new("Cancel", function()
			self:dismissSaveDialog()
		end)

		table.insert(view.content, head)
		table.insert(view.content, inp)
		table.insert(view.content, okbutton)
		table.insert(view.content, cancelbutton)

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

		view.mousepressed = function(zelf, x, y)
			for _, v in pairs(zelf.content) do
				if v:mousepressed(x, y) then
					return
				end
			end
		end
		view.mousemoved = function(zelf, x, y)
			for _, v in pairs(zelf.content) do
				v:mousemoved(x, y)
			end
		end
		view.mousereleased = function(zelf, x, y)
			for _, v in pairs(zelf.content) do
				if v:mousereleased(x, y) then
					return
				end
			end
		end
		view.keypressed = function(zelf, combo)
			for _, v in pairs(zelf.content) do
				if v:keypressed(combo) then
					return
				end
			end
		end
		view.update = function(zelf, dt)
			for _, v in pairs(zelf.content) do
				v:update(dt)
			end
		end
		view.draw = function(zelf)
			for _, v in pairs(zelf.content) do
				v:draw()
			end
		end

		return view
	end)
end

---@param name? string|nil
function Editor:save(name)
	name = name or self.currentfilename
	if name ~= nil then
		local file, _ = love.filesystem.newFile(name)
		if file == nil then
			self.save_file_dialog = nil
			return
		end
		local opened, err = file:open("w")
		if not opened then
			print("couldn't open: " .. err)
			self.save_file_dialog = nil
			return
		end
		local success, err_ = file_format.FileFormat:persist(file, self.stack, {})
		if not success then
			print("couldn't save: " .. err_)
		end
		file:close()
		self.save_file_dialog = nil
	end
end

function Editor:dismissSaveDialog()
	self.save_file_dialog = nil
end

function Editor:toggle_layer_panel()
	if self.layer_panel == nil then
		self.layer_panel = layer_panel.LayerPanel:new(self.stack, self.w - 300, 0, 300, math.floor(self.h / 3))
	else
		self.layer_panel = nil
	end
end

function Editor:keypressed(combo)
	if combo == "Shift+Meta+d" then
		print("STACK:")
		print(dump(self.stack))
		print("CURRENT TOOL:")
		print(dump(self.current_tool))
		print("layer_panel view:")
		print(dump(self.layer_panel))
		return
	end
	if combo == "Meta+s" then
		self:openSaveDialog()
		return
	end
	if combo == "Meta+o" then
		print("TODO: implement open file from editor!")
		return
	end
	if combo == "Meta+l" then
		self:toggle_layer_panel()
		return
	end
	if combo == "Meta+backspace" then
		print(combo .. " " .. (self.layer_panel or { selected = 999999999 }).selected)
		print(dump(self.layer_panel))
	end
	if combo == "Meta+backspace" and self.layer_panel ~= nil and self.layer_panel.selected > 0 then
		table.remove(self.stack, self.layer_panel.selected)
		if self.layer_panel ~= nil then
			self.layer_panel = layer_panel.LayerPanel:new(self.stack, self.w - 300, 0, 300)
		end
		return
	end
	if self.save_file_dialog ~= nil then
		if self.save_file_dialog:keypressed(combo) and self.save_file_dialog.shouldclose then
			self.save_file_dialog = nil
		end
		return true
	end
	if self.layer_panel ~= nil then
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
			self.layer_panel:new_layers(self.stack)
			self.layer_panel.selected = sel - 1
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
			self.layer_panel:new_layers(self.stack)
			self.layer_panel.selected = sel + 1
			return true
		end
	end
	if self.current_tool:keypressed(combo) then
		if not self.current_tool.building then
			self:push_current_on_stack()
		end
		return
	end
	if self.controls:keypressed(combo) then
		self.current_tool = self.controls:newtool()
		return
	end
	if combo == "u" then
		local undone = table.remove(self.stack, #self.stack)
		if self.layer_panel ~= nil then
			self.layer_panel = layer_panel.LayerPanel:new(self.stack, self.w - 300, 0, 300)
		end
		table.insert(self.undo_stack, undone)
	elseif combo == "Shift+u" and #self.undo_stack > 0 then
		local redone = table.remove(self.undo_stack, #self.undo_stack)
		table.insert(self.stack, redone)
		if self.layer_panel ~= nil then
			self.layer_panel = layer_panel.LayerPanel:new(self.stack, self.w - 300, 0, 300)
		end
	end
end

function Editor:update(dt)
	if self.save_file_dialog ~= nil then
		self.save_file_dialog:update(dt)
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
		return
	end
	if self.save_file_dialog ~= nil then
		self.save_file_dialog:draw()
	end
end

M.Editor = Editor

return M
