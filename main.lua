local KeyHandler = require("keyhandler").KeyHandler
local Editor = require("editor").Editor
local MainMenu = require("main_menu").MainMenu
local keyhandler = KeyHandler:new()
local dump = require("utils").dump

local screen

---@param x number
---@param y number
function love.mousemoved(x, y)
	screen:mousemoved(x, y)
end

---@param x number
---@param y number
function love.mousepressed(x, y)
	screen:mousepressed(x, y)
end

---@param x number
---@param y number
function love.mousereleased(x, y)
	screen:mousereleased(x, y)
end

function love.keypressed(_, scancode)
	local emitted, combo = keyhandler:keypressed(scancode)
	if not emitted or combo == nil then
		return
	end
	if combo == "Meta+q" then
		love.event.quit(0)
	end
	screen:keypressed(combo)
end

function love.keyreleased(_, scancode)
	keyhandler:keyreleased(scancode)
	screen:keyreleased(scancode)
end

function love.update(dt)
	screen:update(dt)
end

---@param name? string|nil
local loadNewFile = function(name)
	screen = Editor:new(name)
end

function love.load()
	local _, _, flags = love.window.getMode()

	-- The window's flags contain the index of the monitor it's currently in.
	local width, height = love.window.getDesktopDimensions(flags.display)
	love.window.setMode(math.floor(width * 0.75), math.floor(height * 0.75), { centered = false })
	screen = MainMenu:new(loadNewFile)
end

function love.draw()
	screen:draw()
end
