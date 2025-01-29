assert(love, "Run main.lua with LÖVE >= 11")
package.moonpath = "#{package.moonpath};../?.moon" -- grab BlobWriter/Reader from parent directory

gfx, timer, fs = love.graphics, love.timer.getTime, love.filesystem
BENCHMARK_TIME = 1 -- approx. number of seconds each benchmark runs

tests =
	largeNumArray: -> [ i * .5 for i = 1, 2 ^ 16 ]
	largeU32Array: -> [ i * i for i = 1, 2 ^ 16 ]
	smallNumArray: -> [ i * .5 for i = 1, 255 ]
	smallU8Array: -> [ i for i = 0, 255 ]
	simpleTable: ->
		{
			zero: 0
			number1: 23
			number2: 42
			number3: 666.66
			string: 'text'
			bool: true
		}

	deepTable: ->
		result =
			number: 42
			string: 'text'
			bool: true
			nested: { }

		current = result.nested
		for i = 1, 1000
			current.nested =
				number: i
				string: 'text ' .. i
				bool: true
			current = current.nested
		result

testNames = [ name for name in pairs(tests) ]
table.sort(testNames)

benchmarks =
	names: {}
	libraries: {}

loadBenchmarks = ->
	dir = fs.getDirectoryItems('benchmarks')
	for item in *dir
		continue unless item\match('benchmark_')
		name = item\gsub('%.moon', '')
		benchmark = require('benchmarks.' .. name)

		benchmarks.libraries[name] =
			description: benchmark.description
			results: {}
			serialize: { k, v for k, v in pairs(benchmark.serialize) }
			deserialize: { k, v for k, v in pairs(benchmark.deserialize) }

	benchmarks.names = [ name for name in pairs(benchmarks.libraries) ]
	table.sort(benchmarks.names, (a, b) -> b < a)


local benchmarkThread
frame = 0

run = (what, data) ->
	time, counter, resultData = 0, 0
	okay, result = pcall(->
		start = timer!
		while time < BENCHMARK_TIME
			resultData = what(data)
			time = timer! - start
			counter = counter + 1

		return {
			count: counter
			time: time
			data: resultData
		}
	)

	unless okay
		print(result)
		result = {
			count: 0
			time: BENCHMARK_TIME
			error: result
		}
	result

runBenchmarks = ->
	testData = { name, func! for name, func in pairs(tests) }

	collectgarbage('stop')

	for test in *testNames
		data = testData[test]
		for libName in *benchmarks.names
			lib = benchmarks.libraries[libName]
			collectgarbage!
			okay, result = pcall(run, lib.serialize[test], data)
			lib.results[test] = { serialize: result }
			coroutine.yield!

			collectgarbage!
			okay, result = pcall(run, lib.deserialize[test], result.data)
			lib.results[test].deserialize = result
			coroutine.yield!

	collectgarbage('restart')

	for part in *{ "serialize", "deserialize" }
		output = {
			part .. " | " .. table.concat(testNames, ' | '),
			"--- | "\rep(#testNames + 1),
		}
		for libName in *benchmarks.names
			lib = benchmarks.libraries[libName]
			line = lib.description .. " | "
			for test in *testNames
				results = lib.results[test][part]
				line = line .. (math.floor(results.count / results.time + .5)) .. " | "
			output[#output + 1] = line
		print(table.concat(output, '\n'))

love.load = ->
	loadBenchmarks!
	benchmarkThread = coroutine.create(runBenchmarks)

love.update = ->
	x, y, frame = 10, 1, frame + 1
	frame = frame + 1
	return if frame < 5
	coroutine.resume(benchmarkThread)

lineHeight = math.floor(gfx.getFont!\getHeight! * 1.25)

love.keypressed = (key) ->
	love.event.quit! if key == 'escape'

drawResult = (lib, result, max, x, y) ->
	w, h = gfx.getDimensions!
	w, h = w / 2 - 20, lineHeight

	if result.error
		gfx.setColor(1, .4, .4)
		gfx.print("%s FAILED: %s"\format(lib, result.error), x, y)
	else
		gfx.setColor(.2, .2, .8)
		gfx.rectangle('fill', x, y, w * (result.count / max), lineHeight - 2)
		gfx.setColor(1, 1, 1)
		if type(result.data) == 'string'
			gfx.print("%s: %.2f ops/sec (%d bytes)"\format(lib, result.count / result.time, #result.data), x + 10, y)
		else
			gfx.print("%s: %.2f ops/sec"\format(lib, result.count / result.time), x + 10, y)

maxCount = {
	serialize: {}
	deserialize: {}
}

love.draw = ->
	gfx.clear(.2, .2, .2)

	x, y = 10, 5
	for test in *testNames
		maxCount.serialize[test] = maxCount.serialize[test] or 0
		maxCount.deserialize[test] = maxCount.deserialize[test] or 0
		for part in *{ 'serialize', 'deserialize' }
			for libName, lib in pairs(benchmarks.libraries)
				count = maxCount[part]
				results = lib.results[test]
				count[test] = math.max(results[part].count, count[test]) if results and results[part]

	ry = y
	for test in *testNames
		for part in *{ 'serialize', 'deserialize' }
			ry, rx = y, x + (part == 'deserialize' and 320 or 0)
			gfx.setColor(1, 1, 1)
			gfx.print("%s %s"\format(part, test), rx, y)
			ry += lineHeight
			for libName in *benchmarks.names
				lib = benchmarks.libraries[libName]
				results = lib.results[test]
				if results and results[part]
					drawResult(lib.description, results[part], maxCount[part][test], rx, ry)
				else
					gfx.setColor(1, 1, 1)
					gfx.print("waiting for %s..."\format(lib.description), rx, ry)
				ry += lineHeight
			ry += lineHeight
		y = ry
