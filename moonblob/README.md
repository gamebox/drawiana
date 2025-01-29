# moonblob - binary serialization library

## Note: If you can, use LuaJIT's [String Buffer Library](https://repo.or.cz/luajit-2.0.git/blob_plain/HEAD:/doc/ext_buffer.html) library instead. It's better designed and probably a lot faster than moonblob.

moonblob is a compact LuaJIT library written in moonscript that performs serialization into an efficient binary format. It can be used to parse arbitrary binary data, or to serialize data for efficient storage or transmission.

## How to use

### Writing data
```lua
BlobWriter = require('BlobWriter')

blob = BlobWriter()

-- Store raw binary data
blob
	:u8(23)
	:number(123.45)
	:f32(23.0)
	:string('string')
	...

-- Store Lua types
blob
	:write({ key: 'value', tbl: { 1, 2, 3 } }) -- no cycles allowed!
	:write(23)
	:write(true)
	:write('string')

-- Write data to file
file = io.open('filename.ext', 'wb')
file:write(blob:tostring())
file:close()
```
### Reading data
```lua
BlobReader = require('BlobReader')

-- Load data from file
file = io.open('filename.ext', 'rb')
blob = BlobReader(file:read('*all'))
file:close()

-- Parse raw binary data
u8 = blob:u8()
s16 = blob:s16()
str = blob:cstring()
float = blob:f32()
...

-- Read Lua types
tbl = blob:table()
bool = blob:bool() -- 8 bits, 0 == false
num = blob:number()
str = blob:string()
```
## Documentation

[API reference](https://megagrump.github.io/moonblob/doc/)

### Reading and writing Lua types

[`BlobReader:read`](https://megagrump.github.io/moonblob/doc/classes/BlobReader.html#read) and [`BlobWriter:write`](https://megagrump.github.io/moonblob/doc/classes/BlobWriter.html#write) can be used to store Lua values along with their type. `BlobReader:read` can only read data that was previously written by `BlobWriter:write`.

These data types are supported by `BlobReader:read` and `BlobWriter:write`:
* `number` (64 bit)
* `string` (up to 2^32-1 bytes)
* `boolean`
* `table`
* `cdata`

Type and length information will be added as metadata by the `write` function. Metadata overhead is 1 byte per value written for type information, and between 1 and 5 bytes per string written for length information. Tables can contain `number`, `string`, `boolean`, 'cdata', and `table` as key and value types. An error is being thrown if other types or cyclic nested tables are encountered.

### Low level I/O

A low level interface is provided for handling arbitrary binary data.

	number       -- Lua number (64 bit floating point)
	bool         -- boolean value (8 bits; 0 == false)
	string       -- Lua string
	table        -- Lua table
	s8  / u8     -- signed/unsigned 8 bit integer value
	s16 / u16    -- signed/unsigned 16 bit integer value
	s32 / u32    -- signed/unsigned 32 bit integer value
	s64 / u64    -- signed/unsigned 64 bit integer value
	vs32 / vu32  -- length-encoded signed/unsigned 32 bit value
	f32 / f64    -- 32/64 bit floating point value
	raw          -- raw binary data (length must be specified)
	cstring      -- zero-terminated string
	array        -- sequential table of typed values
	cdata        -- LuaJIT cdata

To describe the raw data format in a more concise manner, use [`BlobWriter:pack`](https://megagrump.github.io/moonblob/doc/classes/BlobWriter.html#pack) and [`BlobReader:unpack`](https://megagrump.github.io/moonblob/doc/classes/BlobReader.html#unpack). These functions work similar to `string.unpack` and `string.pack` in Lua 5.3, although some details are different (fixed instead of native data sizes; more supported data types; some features are not implemented). See [API reference](https://megagrump.github.io/moonblob/doc) for details.

### Compatibility

The library was developed on and for x86 and x64 machines - other architectures are currently untested.

Since moonblob uses the ffi library and C data types, it is not compatible with vanilla Lua and can only be used with LuaJIT.

### License

Copyright 2017-2021 megagrump

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
