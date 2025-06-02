local tools = require("tools")
local slider = require("designsystem.slider")
local freehand_points = require("freehand_points")
local Rectangle = tools.Rectangle
local Line = tools.Line
local Text = tools.Text
local Circle = tools.Circle
local View = require("view").View
local Dialog = require("dialog").Dialog
local Button = require("designsystem.button").Button
local utils = require("utils")
local fonts = require("fonts")

local M = {}

---@alias Color { r : number, g : number, b : number, a? : number }
---@alias Orientation 0 | 1

---@type Orientation
local HORIZONTAL = 0
---@type Orientation
local VERTICAL = 1

---@type Color
local black = { r = 0, g = 0, b = 0 }
---@type Color
local white = { r = 1, g = 1, b = 1 }
---@type Color
local selected_color = { r = 0.1, g = 0.4, b = 0.8 }

---@type Color[]
local color_options = {
	{ r = 1, g = 0, b = 0 },
	{ r = 0.5, g = 0, b = 0 },
	{ r = 1, g = 1, b = 0 },
	{ r = 0.5, g = 0.5, b = 0 },
	{ r = 0.92, g = 0.49, b = 0.1 },
	{ r = 1, g = 0, b = 1 },
	{ r = 0.5, g = 0, b = 0.5 },
	{ r = 0, g = 1, b = 0 },
	{ r = 0, g = 0.5, b = 0 },
	{ r = 0, g = 1, b = 1 },
	{ r = 0, g = 0.5, b = 0.5 },
	{ r = 0, g = 0, b = 1 },
	white,
	{ r = 0.66, g = 0.66, b = 0.66 },
	{ r = 0.33, g = 0.33, b = 0.33 },
	black,
}

---@class ColorDialog : View
---@field r number The initial value for the red slider
---@field g number The initial value for the green slider
---@field b number The initial value for the blue slider
---@field private ok_button Button
---@field private cancel_button Button
---@field private red_slider Slider
---@field private green_slider Slider
---@field private blue_slider Slider
local ColorDialog = View:new({ r = 0, g = 0, b = 0, on_save = function() end })

---Create a new ColorDialog
---@param x number
---@param y number
---@param w number
---@param h number
---@param on_save function(color: Color|nil)
---@return ColorDialog
function ColorDialog:new(x, y, w, h, on_save)
	local dialog = setmetatable({}, self)
	self.__index = self

	dialog.x = x
	dialog.y = y
	dialog.h = h
	dialog.w = w

	dialog.cancel_button = Button:new("Cancel", function()
		on_save(nil)
	end)
	local slider_height = 16

	dialog.red_slider = slider.Slider:new(
		x + 4,
		y + 48,
		dialog.w - 8,
		slider_height,
		{ track_height = slider_height, fill_color = color_options[1], value = 20 }
	)
	dialog.green_slider = slider.Slider:new(
		x + 4,
		y + 48 + slider_height + 4,
		dialog.w - 8,
		slider_height,
		{ track_height = slider_height, fill_color = color_options[8], value = 40 }
	)
	dialog.blue_slider = slider.Slider:new(
		x + 4,
		y + 48 + ((slider_height + 4) * 2),
		dialog.w - 8,
		slider_height,
		{ track_height = slider_height, fill_color = color_options[12], value = 60 }
	)

	dialog.cancel_button.x = x + w - dialog.cancel_button.w - 4
	dialog.cancel_button.y = y + h - dialog.cancel_button.h - 4

	dialog.ok_button = Button:new("Ok", function()
		on_save({ r = dialog.r / 100, g = dialog.g / 100, b = dialog.b / 100 })
	end)

	dialog.ok_button.x = dialog.cancel_button.x - 4 - dialog.ok_button.w
	dialog.ok_button.y = dialog.cancel_button.y
	dialog.ok_button.bgcolor = { r = 0, g = 0.1, b = 0.6, a = 1 }

	return dialog
end

function ColorDialog:update(dt)
	_ = dt
	self.r = self.red_slider.value
	self.g = self.green_slider.value
	self.b = self.blue_slider.value
end

function ColorDialog:mousemoved(x, y)
	self.red_slider:mousemoved(x, y)
	self.blue_slider:mousemoved(x, y)
	self.green_slider:mousemoved(x, y)
	self.cancel_button:mousemoved(x, y)
	self.ok_button:mousemoved(x, y)
end

function ColorDialog:mousepressed(x, y)
	if
		self.red_slider:mousepressed(x, y)
		or self.blue_slider:mousepressed(x, y)
		or self.green_slider:mousepressed(x, y)
		or self.cancel_button:mousepressed(x, y)
		or self.ok_button:mousepressed(x, y)
	then
		return true
	end
	return false
end

function ColorDialog:mousereleased(x, y)
	if
		self.red_slider:mousereleased(x, y)
		or self.blue_slider:mousereleased(x, y)
		or self.green_slider:mousereleased(x, y)
		or self.cancel_button:mousereleased(x, y)
		or self.ok_button:mousereleased(x, y)
	then
		return true
	end
	return false
end

function ColorDialog:keypressed(combo)
	if
		self.red_slider:keypressed(combo)
		or self.blue_slider:keypressed(combo)
		or self.green_slider:keypressed(combo)
		or self.cancel_button:keypressed(combo)
		or self.ok_button:keypressed(combo)
	then
		return true
	end
	return false
end

function ColorDialog:keyreleased()
	if
		self.red_slider:keyreleased()
		or self.blue_slider:keyreleased()
		or self.green_slider:keyreleased()
		or self.cancel_button:keyreleased()
		or self.ok_button:keyreleased()
	then
		return true
	end
	return false
end

local title_font = fonts.get_bold_font(20)

function ColorDialog:draw()
	love.graphics.setColor(1, 1, 1, 1)
	local text = love.graphics.newText(title_font, "Configure Color")
	love.graphics.draw(text, self.x + 4, self.y + 4)
	-- draw sliders
	self.red_slider:draw()
	self.green_slider:draw()
	self.blue_slider:draw()
	love.graphics.setColor(self.red_slider.value / 100, self.green_slider.value / 100, self.blue_slider.value / 100, 1)
	love.graphics.rectangle("fill", self.blue_slider.x, self.blue_slider.y + self.blue_slider.h + 8, 24, 24)
	-- draw buttons
	self.cancel_button:draw()
	self.ok_button:draw()
end

---@class Controls : View
---@field current_color Color
---@field current_line_width number
---@field color_opt_width number
---@field color_opt_height number
---@field orientation Orientation
---@field tool string
---@field tools string[]
---@field tool_options Tool[]
---@field tool_indexes { [string]: number }
---@field color_options Color[]
---@field color_dialog ColorDialog|nil
---@field add_color_button Button
local Controls = View:new({
	current_color = white,
	current_line_width = 1,
	color_opt_height = 0,
	color_opt_width = 0,
	orientation = HORIZONTAL,
	tool = "line",
	tool_options = {},
	tools = { "rectangle", "rectangle_outline", "circle", "circle_outline", "straight", "line", "freehand", "text" },
	tool_indexes = {},
	color_options = color_options,
})

---Creates a new Controls view.  Is a valid [View](lua://View)
---@param x number The x position where the controls will render
---@param y number The y position where the controls will render
---@param h number The amount of pixels given to the controls to render in the x-axis
---@param w number The amount of pixels given to the controls to render in the y-axis
function Controls:new(x, y, h, w)
	---@type Controls
	local controls = setmetatable({}, self)
	self.__index = self

	controls.x = x
	controls.y = y
	controls.h = h
	controls.w = w
	controls.current_color = color_options[13]
	controls.tool = controls.tools[5]
	controls.tool_options = {}
	controls.tool_indexes = {}
	controls.color_dialog = nil
	controls.add_color_button = Button:new("Add", function()
		self:open_color_dialog()
	end, 12)
	local bgcolor = utils.with(black, "a", 1)
	controls.add_color_button.bgcolor = bgcolor

	for i, t in ipairs(Controls.tools) do
		controls.tool_indexes[t] = i
	end

	controls:setup_tools()

	return controls
end

function Controls:setup_tools()
	local controls = self

	-- Create tools
	local r = Rectangle:new(1, black)
	r.mode = "fill"
	local r2 = Rectangle:new(3, black)
	r2.mode = "line"
	local straight = Line:new(1, black, true)
	local l = Line:new(1, black)
	l:setColor(selected_color)
	local circle = Circle:new(1, black)
	circle.mode = "fill"
	local circle_o = Circle:new(3, black)
	circle_o.mode = "line"
	local t = Text:new(1, black)
	t.size = 20
	t.text = "T"
	table.insert(controls.tool_options, r)
	table.insert(controls.tool_options, r2)
	table.insert(controls.tool_options, circle)
	table.insert(controls.tool_options, circle_o)
	table.insert(controls.tool_options, straight)
	table.insert(controls.tool_options, l)
	table.insert(controls.tool_options, t)

	-- Layout tools
	local h, w = controls.h, controls.w
	if h > w then
		controls.orientation = VERTICAL
		controls.color_opt_width = 40
		controls.color_opt_height = math.floor(controls.h / #color_options)
		local border = 2
		r.start = { x = controls.x + border, y = controls.y + border }
		r.end_ = { x = controls.x + controls.color_opt_width - 2, y = controls.y + controls.color_opt_height - 2 }
		r2.start = { x = controls.x, y = controls.y }
		r2.end_ =
			{ x = controls.x + (controls.color_opt_width - 2) * 2, y = controls.y + controls.color_opt_height - 2 }
		straight.points = {
			controls.x + 8,
			controls.y + 8,
			controls.x + controls.color_opt_width - 8,
			controls.y + controls.color_opt_height - 8,
		}
		l.points = freehand_points(controls.x, controls.y + controls.color_opt_height)
	else
		local border = 2
		controls.orientation = HORIZONTAL
		controls.color_opt_width = 40
		controls.color_opt_height = math.floor(controls.h / 2)
		local xoffset = controls.x
		r.start = { x = xoffset + 2, y = controls.y + 2 }
		r.end_ = { x = xoffset + controls.color_opt_width - 4, y = controls.y + controls.color_opt_height - 2 }
		xoffset = xoffset + controls.color_opt_width
		r2.start = { x = xoffset + 4, y = controls.y + 4 }
		r2.end_ = { x = xoffset + controls.color_opt_width - 4, y = controls.y + controls.color_opt_height - 4 }
		xoffset = xoffset + controls.color_opt_width
		circle.radiusx = controls.color_opt_width / 2 - 5
		circle.radiusy = controls.color_opt_height / 2 - 5
		circle.origin =
			{ x = xoffset + (controls.color_opt_width / 2), y = controls.y + (controls.color_opt_height / 2) }
		xoffset = xoffset + controls.color_opt_width
		circle_o.radiusx = controls.color_opt_width / 2 - 7
		circle_o.radiusy = controls.color_opt_height / 2 - 7
		circle_o.origin =
			{ x = xoffset + (controls.color_opt_width / 2), y = controls.y + (controls.color_opt_height / 2) }
		xoffset = xoffset + controls.color_opt_width
		straight.points = {
			xoffset + 8,
			controls.y + 8,
			xoffset + controls.color_opt_width - 8,
			controls.y + controls.color_opt_height - 8,
		}
		xoffset = xoffset + controls.color_opt_width
		l.points = freehand_points(xoffset + 4, controls.y)

		xoffset = xoffset + controls.color_opt_width
		t.start = { x = xoffset + border + 12, y = controls.y + border }
	end

	r:set_dimensions()
	r2:set_dimensions()
end

function Controls:alter_line_width(delta)
	self.current_line_width = (math.min(300, math.max(0, self.current_line_width + delta)))
end

function Controls:mousemoved(x, y)
	if self.color_dialog ~= nil then
		self.color_dialog:mousemoved(x, y)
	end
	self.add_color_button:mousemoved(x, y)
end

function Controls:mousereleased(x, y)
	if
		(self.color_dialog ~= nil and self.color_dialog:mousereleased(x, y))
		or self.add_color_button:mousereleased(x, y)
	then
		return true
	end
end

function Controls:mousepressed(x, y)
	if
		(self.color_dialog ~= nil and self.color_dialog:mousepressed(x, y)) or self.add_color_button:mousepressed(x, y)
	then
		return true
	end

	if self:inarea(x, y) then
		local index = 1
		while x > index * self.color_opt_width do
			index = index + 1
		end
		if y - self.y < math.floor(self.color_opt_height) then
			if index > #self.tools then
				return true
			end
			self.tool = self.tools[index]
			for _, tool in pairs(self.tool_options) do
				tool:setColor(black)
			end
			self.tool_options[index]:setColor(selected_color)
		else
			if index > #color_options then
				return true
			end
			self.current_color = color_options[index]
		end

		return true
	end
	return false
end

function Controls:debug()
	print("===", "Controls:debug", "===")
	print(
		"current_color",
		"r: ",
		self.current_color.r,
		"g:",
		self.current_color.g,
		"b:",
		self.current_color.b,
		"a:",
		self.current_color.a
	)
	print("current_line_width", self.current_line_width)
	print("color_opt_width", self.color_opt_width)
	print("color_opt_height", self.color_opt_height)
	print("orientation", self.orientation)
	print("tool", self.tool)
	print("---", "Tools:", self.tools, "---")
	for _, tool in ipairs(self.tools) do
		print("   ", tool, tool)
	end
	print("---", "Tools END", "---")
	print("---", "Color Options:", self.color_options, "---")
	for _, color_option in ipairs(self.tools) do
		print("   ", color_option, color_option)
	end
	print("---", "Color Options END", "---")
	if self.color_dialog ~= nil then
		print("color_dialog", self.color_dialog)
	end
	print("===", "Controls:debug END", "===")
end

function Controls:keypressed(combo)
	local idx = 0
	if combo == "Shift+Meta+d" then
		self:debug()
	end

	if
		(self.color_dialog ~= nil and self.color_dialog:keypressed(combo)) or self.add_color_button:keypressed(combo)
	then
		return true
	end
	if combo == "r" then
		idx = self.tool_indexes["rectangle"]
		self.tool = "rectangle"
	elseif combo == "Shift+r" then
		idx = self.tool_indexes["rectangle_outline"]
		self.tool = "rectangle_outline"
	elseif combo == "c" then
		idx = self.tool_indexes["circle"]
		self.tool = "circle"
	elseif combo == "Shift+c" then
		idx = self.tool_indexes["circle_outline"]
		self.tool = "circle_outline"
	elseif combo == "l" then
		idx = self.tool_indexes["line"]
		self.tool = "line"
	elseif combo == "t" then
		idx = self.tool_indexes["text"]
		self.tool = "text"
	elseif combo == "1" then
		self.current_color = color_options[1]
		idx = self.tool_indexes[self.tool]
	elseif combo == "2" then
		self.current_color = color_options[2]
		idx = self.tool_indexes[self.tool]
	elseif combo == "3" then
		self.current_color = color_options[3]
		idx = self.tool_indexes[self.tool]
	elseif combo == "4" then
		self.current_color = color_options[4]
		idx = self.tool_indexes[self.tool]
	elseif combo == "5" then
		self.current_color = color_options[5]
		idx = self.tool_indexes[self.tool]
	elseif combo == "6" then
		self.current_color = color_options[6]
		idx = self.tool_indexes[self.tool]
	elseif combo == "7" then
		self.current_color = color_options[7]
		idx = self.tool_indexes[self.tool]
	elseif combo == "8" then
		self.current_color = color_options[8]
		idx = self.tool_indexes[self.tool]
	elseif combo == "9" then
		self.current_color = color_options[9]
		idx = self.tool_indexes[self.tool]
	elseif combo == "0" then
		self.current_color = color_options[10]
		idx = self.tool_indexes[self.tool]
	end
	if idx > 0 then
		self.tool = self.tools[idx]
		for _, tool in pairs(self.tool_options) do
			tool:setColor(black)
		end
		self.tool_options[idx]:setColor(selected_color)
		return true
	end
	if combo == "b" then
		self:alter_line_width(1)
		return true
	elseif combo == "Shift+b" then
		self:alter_line_width(10)
		return true
	elseif combo == "s" then
		self:alter_line_width(-1)
		return true
	elseif combo == "Shift+s" then
		self:alter_line_width(-10)
		return true
	end
	if combo == "Shift+=" and self.color_dialog == nil then
		self:open_color_dialog()
		return true
	end
	return false
end

---@param color Color
function Controls:on_color_dialog_closed(color)
	if color ~= nil then
		table.insert(color_options, #color_options + 1, color)
		self.color_options = color_options
	end
	self.color_dialog = nil
end

function Controls:open_color_dialog()
	local zelf = self
	self.color_dialog = Dialog:new("md", function(x, y, w, h)
		return ColorDialog:new(x, y, w, h, function(color)
			zelf:on_color_dialog_closed(color)
		end)
	end)
end

function Controls:draw()
	love.graphics.setColor(0.75, 0.75, 0.75, 1)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.color_opt_height)
	if self.orientation == HORIZONTAL then
		for i, opt in pairs(self.color_options) do
			love.graphics.setColor(opt.r, opt.g, opt.b, opt.a or 1)
			love.graphics.rectangle(
				"fill",
				(i - 1) * self.color_opt_width,
				self.y + self.color_opt_height,
				self.color_opt_width,
				self.color_opt_height
			)
			if opt == self.current_color then
				love.graphics.setLineWidth(4)
				love.graphics.setColor(selected_color.r, selected_color.g, selected_color.b, opt.a or 0.7)
				love.graphics.rectangle(
					"line",
					(i - 1) * self.color_opt_width + 2,
					self.y + 2 + self.color_opt_height,
					self.color_opt_width - 4,
					self.h - 4
				)
			end
		end
		self.add_color_button.x = #self.color_options * self.color_opt_width + 2
		self.add_color_button.y = self.y + 2 + self.color_opt_height
		self.add_color_button:draw()
	else
		for i, opt in pairs(self.color_options) do
			love.graphics.setColor(opt.r, opt.g, opt.b, opt.a or 1)
			love.graphics.rectangle(
				"fill",
				self.x + self.color_opt_width,
				(i - 1) * self.color_opt_height,
				self.color_opt_width,
				self.color_opt_height
			)
			if opt == self.current_color then
				love.graphics.setLineWidth(4)
				love.graphics.setColor(selected_color.r, selected_color.g, selected_color.b, selected_color.a or 0.7)
				love.graphics.rectangle(
					"line",
					self.x + 2 + self.color_opt_width,
					(i - 1) * self.color_opt_height + 2,
					self.color_opt_width - 4,
					self.h - 4
				)
			end
		end
	end
	for _, t in pairs(self.tool_options) do
		t:draw()
	end
	-- TODO: Implement add color button
	love.graphics.setColor(black.r, black.g, black.b, black.a or 1)
	love.graphics.print("" .. self.current_line_width, self.w - 50, self.y + 2)
	if self.color_dialog ~= nil then
		self.color_dialog:draw()
	end
end

---@param dt number
---@diagnostic disable-next-line unused-argument
function Controls:update(dt)
	if self.color_dialog ~= nil then
		self.color_dialog:update(dt)
	end
end

---@return Tool
function Controls:newtool()
	-- Line is default
	if self.tool == "rectangle" then
		return Rectangle:new(self.current_line_width, self.current_color)
	end
	if self.tool == "rectangle_outline" then
		local rect = Rectangle:new(self.current_line_width, self.current_color)
		rect.mode = "line"
		return rect
	end
	if self.tool == "circle" then
		return Circle:new(self.current_line_width, self.current_color)
	end
	if self.tool == "circle_outline" then
		local circle = Circle:new(self.current_line_width, self.current_color)
		circle.mode = "line"
		return circle
	end
	if self.tool == "text" then
		local text = Text:new(self.current_line_width, self.current_color)
		text.size = 24
		return text
	end
	if self.tool == "straight" then
		return Line:new(self.current_line_width, self.current_color, true)
	end
	return Line:new(self.current_line_width, self.current_color)
end

-- Exports

M.Controls = Controls

return M
