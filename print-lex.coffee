###
# Prints lexed code so it's easily readable.
###

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

padding = (string, length) ->
	while string.length < length
		string += ' '
	string

print_lex = (l) ->
	res = padding('- Type -', 18) + ':   ' + padding('- value - ', 12) + '\n'
	for i in l
		break if !i?
		c =
			switch i.type
				when 'string'
					'yellow'
				when 'number'
					'blue'
				when 'binary_operator'
					'green'
				when 'keyword', 'var_type', 'function_start', 'block_start'
					'cyan'
				else
					'reset'
		res +=
			switch i.type
				when 'line_break'
					'-\n'
				when 'block_end'
					color '      block end\n', 'bright'
				else
					padding(i.type, 18) + ':   ' +
					padding(color(i.value, c), 15) + '\n'
	res

module.exports = print_lex