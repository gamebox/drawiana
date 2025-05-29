local BlobReader = require("moonblob.BlobReader")
local BlobWriter = require("moonblob.BlobWriter")

local M = {}

local FileFormat = {}

---@param file love.File A File object opened for writing
---@param stack Tool[]
---@param palette Color[]
---@return boolean success, string error
function FileFormat:persist(file, stack, palette)
	local state = { stack = stack, palette = palette }
	local buf = BlobWriter()
	buf:write(state)
	return file:write(buf:tostring())
end

---@param file love.File A File object opened for reading
---@return boolean, { stack : Tool[], palette : Color[] }|nil
function FileFormat:deserialize(file)
	local bytes = file:read("string")
	local reader = BlobReader(bytes)
	local res = {}
	local t = reader:read(res)
	if t["stack"] then
		res.stack = t["stack"]
	end
	res.palette = t["palette"] or {}
	return true, res
end

M.FileFormat = FileFormat

return M
