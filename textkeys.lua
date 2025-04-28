local M = {}

local nonalphachars =
	{ "=", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "\\", ";", "'", ",", ".", "/", "`", "[", "]" }
local nonalphauppers =
	{ "+", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "_", "|", ":", '"', "<", ">", "?", "~", "{", "}" }

local textkeysmap = {}
for i = 1, #nonalphachars, 1 do
	textkeysmap[nonalphachars[i]] = nonalphauppers[i]
end

local ascii_key_from_combo = function(combo)
	if string.match(combo, "^Shift+") then
		combo = string.sub(combo, 7)
		if #combo == 1 then
			if textkeysmap[combo] ~= nil then
				combo = textkeysmap[combo]
			end
			combo = string.upper(combo)
		end
	end
	if #combo == 1 then
		return true, combo
	elseif combo == "space" then
		return true, " "
	elseif combo == "return" then
		return true, "\n"
	end
	return false, nil
end

M.textkeysmap = textkeysmap
M.ascii_key_from_combo = ascii_key_from_combo

return M
