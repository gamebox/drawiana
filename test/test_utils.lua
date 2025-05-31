local utils = require(".../utils")

function test_utils_extend_table()
	local dest = {
		a = "Hello",
		c = 123,
	}
	local extends = {
		b = "World",
		d = 456,
	}
	utils.extend_table(dest, extends)
	assert_equal(dest["a"], "Hello")
	assert_equal(dest["b"], "World")
	assert_equal(dest["c"], 123)
	assert_equal(dest["d"], 456)
end
