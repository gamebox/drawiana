local FileFormat = require("../file_format").FileFormat
local tools = require("../tools")
local utils = require("../utils")

---@class TestFile : love.File
---@field bytes string
local TestFile = {
	bytes = "",
}

---@return TestFile
function TestFile:new()
	local f = {}
	self.__index = self
	setmetatable(f, self)
	return f
end

function TestFile:read()
	return self.bytes
end

function TestFile:write(bytes)
	self.bytes = self.bytes .. bytes
end

function test_file_format_roundtrip()
	local file = TestFile:new()
	---@type Tool[]
	local stack = {
		tools.Circle:new(3, { r = 0, g = 0, b = 0, a = 1 }),
		tools.Rectangle:new(2, { r = 0, g = 0, b = 255, a = 1 }),
	}
	---@type Color[]
	local palette = {
		{ r = 0, g = 0, b = 0, a = 1 },
		{ r = 128, g = 128, b = 128, a = 1 },
		{ r = 255, g = 255, b = 255, a = 1 },
		{ r = 255, g = 0, b = 0, a = 1 },
		{ r = 0, g = 255, b = 0, a = 1 },
		{ r = 0, g = 0, b = 255, a = 1 },
	}
	FileFormat:persist(file, stack, palette)
	local success, deserialized = FileFormat:deserialize(file)
	assert_equal(success, true)
	assert_table(deserialized)
	if deserialized == nil then
		return
	end
	assert_table(deserialized.stack)
	assert_table(deserialized.palette)
	assert_equal(2, #deserialized.stack)
	assert_equal(6, #deserialized.palette)
end
