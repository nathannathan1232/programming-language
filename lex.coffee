error = require('./error.js')

class Token
	constructor: (type, value, line) ->
		@type = type
		@value = value
		@at_line = line

# Preset regexes for replacing found token values.
# For example, when we find a string literal, remove quotes
# around the edge.
presets =
	replace_whitespace: ['\\s', 'g', '']
	replace_whitespace_before: ['^\\s*', '', '']
	make_spaces_single: ['\\s\\s*', 'g', ' ']

tokens =
	'line_break':
		match: '\\s*\\n\\n*'
		replace: [
			presets.replace_whitespace
		]
	'block_end':
		eol: true
		sol: true

	'include':
		match: '\\s*@include'
		replace: [
			presets.replace_whitespace
		]
		eol: false
		sol: true
	'comment':
		match: '\\s*#.*'
		replace: []
		# Make sure not to add multiple line breaks when we comment
		eol: true
		sol: false
	# Reserved words
	'block_continue':
		match: '\\s*(?:else[ \\t]*if|else)'
		replace: [
			presets.replace_whitespace_before
			presets.make_spaces_single
		]
		eol: true
		sol: true
	# '->' is the object sign
	'block_start':
		match: '\\s*(?:if|for|while|until|function|method|\\->)'
		replace: [
			presets.replace_whitespace
		]
		eol: false
		sol: true
	'keyword':
		match: '\\s*(?:return|break|in|of)'
		replace: [
			presets.replace_whitespace
		]
		eol: true
		sol: true
	'boolean':
		match: '\\s*(?:true|false)'
		replace: [
			presets.replace_whitespace
		]
		eol: true
		sol: true

	'function_call':
		match: '\\s*[a-zA-Z]+\\('
		replace: [
			presets.replace_whitespace
			['\\($', '', ''] # Remove parinthesis
		]
		eol: false
		sol: true
	'array_call':
		match: '\\s*[a-zA-Z]+\\['
		replace: [
			presets.replace_whitespace
			['\\[$', '', ''] # Remove parinthesis
		]
		eol: false
		sol: true
	'variable':
		match: '\\s*@?[a-zA-Z_]+'
		replace: [
			presets.replace_whitespace
		]
		eol: true
		sol: true

	'open_curly':
		match: '\\s*\\{'
		replace: [
			presets.replace_whitespace
		]
		eol: false
		sol: true
	'close_curly':
		match: '\\s*\\}'
		replace: [
			presets.replace_whitespace
		]
		eol: true
		sol: false
	'open_parinthesis':
		match: '\\s*\\('
		replace: [
			presets.replace_whitespace
		]
		eol: false
		sol: true
	'close_parinthesis':
		match: '\\s*\\)'
		replace: [
			presets.replace_whitespace
		]
		eol: true
		sol: false
	'open_brackets':
		match: '\\s*\\['
		replace: [
			presets.replace_whitespace
		]
		eol: false
		sol: true
	'close_brackets':
		match: '\\s*\\]'
		replace: [
			presets.replace_whitespace
		]
		eol: true
		sol: false
	'comma':
		match: '\\s*,'
		replace: [
			presets.replace_whitespace
		]
		eol: false
		sol: false
	# Seperates a range in a for loop.
	'range_seperator':
		match: '\\s*\\.\\.\\.'
		replace: [
			presets.replace_whitespace
		]
		eol: false
		sol: false
	# The namespace operator is : or ::.
	# They are binary operators because it makes parsing easier.
	'binary_operator':
		match: '\\s*(?:' +
			'\\|\\||\\||\\&\\&|\\&|' + # Logical
			'==|\\:=|\\+=|-=|\\*=|/=|%=|\\.=|=|' + # Assignment
			'<<|>>|\\^|' + # Bitwise
			'!=|>=|<=|>|<|' + # Comparison
			'\\*\\*|\\+|-|\\*|\\/|%|\\.|' + # Standard
			'\\:{1,2})' # Namespace
		replace: [
			presets.replace_whitespace
		]
		eol: false
		sol: false
	
	# Variable types
	
	# A number must start with a digit, then can have 0 or 1 periods, and
	# zero or one 'e' An 'e' or '.' must be followed by a digit,
	# except an 'e' can have '-' after it.
	'number':
		match: '\\s*[0-9]+(?:\\.[0-9]*)?(?:e-?[0-9]*)?'
		replace: [
			presets.replace_whitespace
		]
		eol: true
		sol: true
	'string':
		match: '\\s*\\"[^\\"\\\\]*(?:\\\\.[^\\"\\\\]*)*\\"'
		replace: [
			presets.replace_whitespace_before
			['^"|"$', 'g', ''] # Remove quotes
		]
		eol: true
		sol: true

next_token = (code) ->
	for token of tokens
		reg = new RegExp '^' + tokens[token].match
		match = code.match reg
		break if match
	token

lex = (code) ->

	code = code.replace(/\s*$/, '')

	lines = (code.match(/\n/g) || []).length
	
	res = []
	
	indents = 0

	while code.length > 0
		# Iterate over the token regexes and find the next token
		token = next_token code
		reg = new RegExp '^' + tokens[token].match
		match = code.match reg

		# Find the line we're on. Used for throwing errors
		line = (lines - (code.match(/\n/g) || []).length + 1)
		
		# If no token is found, throw an error
		if match is null
			throw error 'unexpected token on line ' +
				line + ': ' + code.slice(0, 10).replace(/\n/, ' ') + '...'

		match = match.toString()
		
		# Do replaces according to the configuration for that token type
		if tokens[token].replace
			for i in tokens[token].replace
				reg2 = new RegExp i[0], i[1]
				match = match.replace reg2, i[2]

		# Add the token to the result
		found = new Token token, match, line
		res.push found

		# Remove the token from the beginning of the code
		code = code.replace reg, ''

		# If we added a line break, make sure it should actually be there.
		if token is 'line_break'
			unless (
				tokens[res[res.length - 2].type].eol and
				tokens[next_token(code)].sol
			)
				res.pop()
				continue
		
		# After every line break, check the indents. If it's less than
		# the previous line, add a block end for every unindent.
		if token is 'line_break'
			new_indents = code.match(/^\t*/).toString().length			
			if new_indents < indents
				for i in [0...(indents - new_indents)]
					res.push new Token 'block_end', '', line
	
			indents = new_indents


	# Make sure the last token is a line break
	if (
		res[res.length - 1].type isnt 'line_break' and
		res[res.length - 1].type isnt 'block_end'
	)
		res.push new Token 'line_break', '', line

	# Make sure every block start has a block end
	starts = 0
	ends = 0
	for i in res
		starts++ if i.type is 'block_start' or i.type is 'block_continue'
		ends++ if i.type is 'block_end'

	while ends < starts
		ends++
		res.push new Token 'block_end', '', line

	# Remove comments
	i = 0
	while i < res.length
		if res[i].type is 'comment'
			res.splice(i, 1)
		else
			i++

	res

module.exports = lex