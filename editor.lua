local View = require("view").View
local Controls = require("controls").Controls
local toolfactory = require("tools").toolfactory
local dump = require("utils").dump
local file_format = require("file_format")
local dialog = require("dialog")
local heading = require("designsystem.heading")
local input = require("designsystem.input")
local button = require("designsystem.button")

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
	if name ~= nil then
		local file, opened, ok, err, state
		file, err = love.filesystem.newFile(name, "r")
		opened, err = file:open("r")
		if not opened then
			print("Could not open file: " .. (err or "No error specified"))
		end
		ok, state = file_format.FileFormat:deserialize(file)
		file:close()
		if ok and state ~= nil then
			print("Deserializing tools")
			for _, t in pairs(state.stack) do
				local tool
				print(dump(t))
				ok, tool = toolfactory(t)
				if ok then
					table.insert(stack, tool)
				end
			end
			print("Got these tools")
			print(dump(stack))
		else
			print("Could not read file: " .. (err or "No error specified"))
		end
	end
	local _, _, flags = love.window.getMode()

	-- The window's flags contain the index of the monitor it's currently in.
	local width, height = love.window.getDesktopDimensions(flags.display)
	love.window.setMode(math.floor(width * 0.75), math.floor(height * 0.75), { centered = false })
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
		currentfilename = nil,
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
	self.current_tool:mousemoved(x, y)
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
	if self.save_file_dialog ~= nil then
		self.save_file_dialog:mousereleased(x, y)
		return true
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
			print("No file?")
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

function Editor:keypressed(combo)
	if combo == "Shift+Meta+d" then
		print("STACK:")
		print(dump(self.stack))
		print("CURRENT TOOL:")
		print(dump(self.current_tool))
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
		print("TODO: implement layer panel")
		self:openSaveDialog()
		return
	end
	if self.save_file_dialog ~= nil then
		if self.save_file_dialog:keypressed(combo) and self.save_file_dialog.shouldclose then
			self.save_file_dialog = nil
		end
		return true
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
		table.insert(self.undo_stack, undone)
	elseif combo == "Shift+u" and #self.undo_stack > 0 then
		local redone = table.remove(self.undo_stack, #self.undo_stack)
		table.insert(self.stack, redone)
	end
end

function Editor:update(dt)
	if self.save_file_dialog ~= nil then
		self.save_file_dialog:update(dt)
	end
	self.controls:update(dt)
	self.current_tool:update(dt)
end

function Editor:draw()
	for _, tool in pairs(self.stack) do
		tool:draw()
	end
	self.current_tool:draw()
	self.controls:draw()
	love.graphics.setColor(1, 1, 1, 1)
	if self.save_file_dialog ~= nil then
		self.save_file_dialog:draw()
	end
end

M.Editor = Editor

return M
