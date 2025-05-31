local M = {}

local base_indent = "  "

local is_valid = function(str)
	return not string.match(str, "[^%a%d_]")
end

local dump
dump = function(o, depth)
	depth = depth or 0
	local indent = string.rep(base_indent, depth, "")
	local more_indent = string.rep(base_indent, depth + 1, "")
	if type(o) == "table" then
		local s = "{\n"
		for k, v in pairs(o) do
			if type(k) == "number" then
				k = "[" .. k .. "]"
			elseif type(k) ~= "string" and is_valid(k) then
			end
			s = s .. more_indent .. k .. " = " .. dump(v, depth + 1) .. ",\n"
		end
		return s .. indent .. "}"
	else
		return tostring(o)
	end
end

M.torgb = function(component)
	return component * 256
end

M.fromrgb = function(rgb)
	return math.ceil(rgb / 256 * 100) / 100
end

M.extend_table = function(base, extends_table)
	for k, v in pairs(extends_table) do
		base[k] = v
	end
end

---@generic T
---@generic K
---@generic V
---@param table `T`
---@param key `K`
---@param value `V`
---@reutnrs T +{ [K]: V }
M.with = function(table, key, value)
	local _with = {}

	for k, v in pairs(table) do
		_with[k] = v
	end
	_with[key] = value

	return _with
end

M.dump = dump

return M
