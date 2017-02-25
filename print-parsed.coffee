yaml = require('json2yaml')

color = (string, color) ->
	colors = 
		reset: "\x1b[0m"
		bright: "\x1b[1m"
		dim: "\x1b[2m"
		underscore: "\x1b[4m"
		blink: "\x1b[5m"
		reverse: "\x1b[7m"
		hidden: "\x1b[8m"
		FgBlack: "\x1b[30m"
		red: "\x1b[31m"
		green: "\x1b[32m"
		yellow: "\x1b[33m"
		blue: "\x1b[34m"
		magenta: "\x1b[35m"
		cyan: "\x1b[36m"
		white: "\x1b[37m"

	colors[color] + string + colors.reset

# Size is how much you want it to show
# 0 -> everything
# 1 -> exclude useless stuff
# 2 -> exclude non important stuff
print = (tree, size = 0) ->
	res = yaml.stringify(tree)
		.replace(/\  type:/g, (m) => m.replace(/\ /g, ''))

	if size >= 1
		res = res
			.replace(/\n\s*(?:line|const_type).*/g, '')
			.replace(/left: |right: /g, '--->')
			.replace(/\ --*/g, (m) => if m.match(/--/) then m else ' --->>')

	if size >= 2
		res = res
			.replace(/\n\s*(?:name|value|operator).*/g, '')
			.replace(/type: /g, '')

	res = res
		.replace(/[0-9][0-9]*/g, (m) => color(m, 'blue'))
		.replace(/:=|[+\-*\/%=<>]/g, (m) => color(m, 'green'))
		.replace(/false|true/g, (m) => color(m, 'magenta'))
		.replace(/\  /g, color '|         ', 'dim')
		.replace(/(?:name\:|variable\:)\s*".*"/g, (m) => m.replace(/".*"/, (m) => '"' + color(m, 'red').replace(/"/g, '') + '"'))
		.replace(/type:\s*".*"/g, (m) => m.replace(/".*"/, (m) => '"' + color(m, 'cyan').replace(/"/g, '') + '"'))

	if size >= 2
		res = res
			.replace(/".*"/g, (m) => '"' + color(m, 'blue').replace(/"/g, '') + '"')

	console.log res

module.exports = print