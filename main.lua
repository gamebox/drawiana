local KeyHandler = require("keyhandler").KeyHandler
local Editor = require("editor").Editor
local MainMenu = require("main_menu").MainMenu
local keyhandler = KeyHandler:new()
local dump = require("utils").dump
local lovetest = require("test/lovetest")

local screen
local background_screen

---@param name? string|nil
local loadNewFile = function(name)
	screen = Editor:new(name)
end

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
	print("Combo", combo)
	if combo == "Meta+q" then
		love.event.quit(0)
	end
	if combo == "Meta+o" and background_screen then
		screen = background_screen
		background_screen = nil
		return
	elseif combo == "Meta+o" then
		background_screen = screen
		screen = MainMenu:new(loadNewFile)
		return
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

function love.load(args)
	if lovetest.detect(args) then
		lovetest.run()
		return
	end
	local _, _, flags = love.window.getMode()

	-- The window's flags contain the index of the monitor it's currently in.
	local width, height = love.window.getDesktopDimensions(flags.display)
	love.window.setMode(math.floor(width * 0.4), math.floor(height * 0.95), { centered = false })
	screen = MainMenu:new(loadNewFile)
	background_screen = nil
end

function love.draw()
	screen:draw()
end
