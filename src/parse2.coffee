###
# This file parses tokenized code into an abstract syntax tree.
# It's pretty complicated.
###

print_parsed = require('./print-parsed.js')
error = require('./error.js')

OPENERS = ['open_parinthesis', 'open_brackets', 'function_call', 'array_call']
CLOSERS = ['close_parinthesis', 'close_brackets']

OPERATORS = [
	['=', ':=', '+=', '-=', '*=', '/=', '%=', '.=']
	['^']
	['&&', '&']
	['||', '|']
	['>', '<', '==', '!=', '>=', '<=', '~~']
	['.']
	['<<', '>>']
	['+', '-']
	['*', '/', '%']
	['**']
	[':', '::']
]

operation_importance = (op) ->
	# Lower numbers are done last. Equal operators are done left to right.
	for i in [0...OPERATORS.length]
		return i if OPERATORS[i].includes(op)

clone = (obj) ->
	JSON.parse JSON.stringify obj

class Node
	constructor: (type, line) ->
		@type = type
		@line = line

class Include extends Node
	constructor: (line, name) ->
		super 'include', line
		@name = name

class Block extends Node
	constructor: (line) ->
		super 'block', line
		@children = []

class IfStatment extends Node
	constructor: (line) ->
		super 'if', line
		@blocks = [] # Block

class SingleIf extends Node
	constructor: (line) ->
		super 'single-if', line
		@test = false # Expression
		@block = false # Block

class WhileLoop extends Node
	constructor: (line) ->
		super 'while', line
		@test = false # Expression
		@block = false # Block
		
class ForLoop extends Node
	constructor: (line) ->
		super 'for', line
		@variable = false # Variable
		@start = false # Value
		@end = false # Value
		@step = 1
		@block = false # Block

class FunctionDefine extends Node
	constructor: (line) ->
		super 'function-define', line
		@name = false
		@params = []
		@block = false

class Return extends Node
	constructor: (line) ->
		super 'return', line
		@block = false

class FunctionCall extends Node
	constructor: (line) ->
		super 'function-call', line
		@name = false
		@params = []

class BinaryExpression extends Node
	constructor: (line, operator) ->
		super 'binary_expression', line
		@operator = operator
		@left = false
		@right = false

class ArrayLiteral extends Node
	constructor: (line) ->
		super 'array_literal', line
		@items = []

class ArrayCall extends Node
	constructor: (line) ->
		super 'array_call', line
		@name = false
		@index = false

# Terminator nodes
class Variable extends Node
	constructor: (line) ->
		super 'variable', line
		@name = false

class Constant extends Node
	constructor: (line) ->
		super 'constant', line
		@const_type = false
		@value = false

# Remove all line breaks and block ends from a list of tokens
remove_line_breaks = (tokens) ->
	i = 0
	while i < tokens.length
		if ['line_break', 'block_end'].includes tokens[i].type
			tokens.splice(i--, 1)
		i++
	tokens

# Takes a stack of tokens, and creates an expression with one binary operator.
# Recursivly appends binary nodes to itself
binary_expression = (stack) ->
	stack = clone stack
	
	if is_one_function_call stack
		return parse_function_call stack

	if is_one_array_call stack
		node = new ArrayCall(stack[0].at_line)
		node.name = stack[0].value		
		
		stack.pop()
		stack.shift()

		block = new Block(stack[0].at_line)
		block.children = parse_block stack
		
		node.index = block
		
		return node

	if is_one_array stack
		return parse_array stack

	if ['line_break', 'block_end'].includes stack[stack.length - 1].type
		stack.pop()

	# Find the least important operator and set that as the pivot
	pivot_index = -1
	pivot_importance = Infinity

	bracket_level = 0

	for i in [0...stack.length]
		importance = operation_importance(stack[i].value) + OPERATORS.length * bracket_level
		if stack[i].type is 'binary_operator' and importance <= pivot_importance
			pivot_importance = importance
			pivot_index = i
		else if OPENERS.includes stack[i].type
			bracket_level += 1
		else if CLOSERS.includes stack[i].type
			bracket_level -= 1

	# If a pivot was found, use what came before it as the left, and what's after as right.
	# Make a new binary expression for each of those.
	# If no pivot was found, the stack we got must only contain a variable or constant.
	if pivot_index > -1
		node = new BinaryExpression(stack[pivot_index].at_line, stack[pivot_index].value)

		# Split the stack at the pivot index
		left = stack.slice(0, pivot_index)
		right = stack.slice(pivot_index + 1, stack.length)

		# Remove already-known parinthesis
		left.shift() if left[0].type is 'open_parinthesis'
		right.pop() if right[right.length - 1].type is 'close_parinthesis'

		# Generate the left and right children for the node
		node.left = binary_expression(left)
		node.right = binary_expression(right)

	else if stack.length < 4
		node = parse_value stack

	node

# Parses a single value like variable, number, or string literal
parse_value = (tokens) ->
	if tokens.length < 1
		throw error 'Error trying to parse nothing as value.'

	i = 0
	while i < tokens.length
		if ['open_parinthesis', 'close_parinthesis'].includes tokens[i].type
			tokens.splice(i, 1)
		else
			i++

	if tokens.length > 1
		console.log tokens
		throw error 'parse error'

	token = tokens[0]

	if token.type is 'variable'
		node = new Variable(token.at_line)
		node.name = token.value
	else if ['number', 'string', 'boolean'].includes token.type
		node = new Constant(token.at_line)
		node.const_type = token.type
		node.value = token.value
	else
		throw error 'unexpected token ' + token.value + ' at line ' + token.at_line


	node

# Parses an array from tokens
parse_array = (tokens) ->
	node = new ArrayLiteral(tokens[0].at_line)
	
	# Remove padding brackets
	tokens.shift()
	tokens.pop()

	until tokens.length < 1
		stack = get_next_param tokens
		
		block = new Block(-1)
		block.children = parse_block stack

		node.items.push block

	node

# Remove the next block from a list of tokens and return them.
# This function effects the tokens array outside of it's scope.
get_next_block = (tokens) ->
	stack = []

	indent_levels = 0
	until indent_levels < 0 or tokens.length < 1
		if tokens[0].type is 'block_start' or tokens[0].type is 'block_continue'
			indent_levels += 1
		else if tokens[0].type is 'block_end'
			indent_levels -= 1
		stack.push tokens.shift()

	stack

get_next_line = (tokens) ->
	stack = []

	until  tokens.length < 1 or ['line_break', 'block_end'].includes(tokens[0].type)
		stack.push tokens.shift()

	stack

get_all_params = (tokens) ->
	stack = []

	indent_levels = 0
	until indent_levels < 0 or tokens.length < 1
		if ['open_parinthesis', 'function_call'].includes tokens[0].type
			indent_levels += 1
		else if tokens[0].type is 'close_parinthesis'
			indent_levels -= 1
		stack.push tokens.shift()

	stack

get_next_param = (tokens) ->
	stack = []
	indent_levels = 0
	until  tokens.length < 1 or (indent_levels <= 0 and tokens[0].type is 'comma')
		if OPENERS.includes tokens[0].type
			indent_levels += 1
		else if CLOSERS.includes tokens[0].type
			indent_levels -= 1
		stack.push tokens.shift()

	if tokens.length > 0 and tokens[0].type is 'comma'
		tokens.shift()

	stack

# Tests whether or not an token array is a single array literal
is_one_array = (tokens) ->
	tokens = clone tokens

	indent_levels = 0

	for i in [0...tokens.length]
		if OPENERS.includes tokens[i].type
			indent_levels += 1
		else if CLOSERS.includes tokens[i].type
			indent_levels -= 1
		if indent_levels < 1 and 0 < i < tokens.length - 1
			return false

	return tokens.length > 0 and tokens[0].type is 'open_brackets'

# First token is an array call
is_one_array_call = (tokens) ->
	tokens = clone tokens

	indent_levels = 0
	for i in [0...tokens.length]
		if OPENERS.includes tokens[i].type
			indent_levels += 1
		else if CLOSERS.includes tokens[i].type
			indent_levels -= 1
		if indent_levels < 1 and 0 < i < tokens.length - 1
			return false

	return tokens.length > 0 and tokens[0].type is 'array_call'

# First token should be a function call
is_one_function_call = (tokens) ->
	tokens = clone tokens

	indent_levels = 0
	for i in [0...tokens.length]
		if ['open_parinthesis', 'function_call'].includes tokens[i].type
			indent_levels += 1
		else if tokens[i].type is 'close_parinthesis'
			indent_levels -= 1
		if indent_levels < 1 and 0 < i < tokens.length - 1
			return false

	return tokens.length > 0 and tokens[0].type is 'function_call'

parse_function_call = (tokens) ->
	tokens = clone tokens
	tokens.pop() if tokens[tokens.length - 1].type is 'close_parinthesis'

	node = new FunctionCall(tokens[0].at_line)

	node.name = tokens[0].value

	tokens.shift()

	until tokens.length < 1
		param = get_next_param tokens
		node.params.push binary_expression param

	node

parse_block = (tokens) ->
	tokens = clone tokens

	stack = []

	result = []

	while(tokens.length > 0)
		switch tokens[0].type
			when 'block_start'

				### IF CONDITIONAL ###
				if tokens[0].value is 'if'
					node = new IfStatment(tokens[0].at_line)
					
					# Remove the if token
					tokens.shift()

					# Get the main condition
					single = new SingleIf(tokens[0].at_line)
					
					stack = get_next_line tokens
					single.test = binary_expression stack
					
					# Get the consequent block
					single.block = new Block(tokens[0].at_line)
					stack = get_next_block tokens
					single.block.children = parse_block stack

					# Push block to node
					node.blocks.push single

					# Get all else ifs and elses connected to this if conditional
					while tokens.length > 0 and ['block_continue'].includes tokens[0].type
						single = new SingleIf(tokens[0].at_line)
						if tokens[0].value is 'else'
							tokens.shift()
							# Since there's no test expression, make it true
							single.test = new Constant(tokens[0].at_line)
							single.test.const_type = 'boolean'
							single.test.value = 'true'

							single.block = new Block(tokens[0].at_line)
							stack = get_next_block tokens
							single.block.children = parse_block stack

						else if tokens[0].value is 'else if'
							tokens.shift()
							# Find the test expression for else if
							stack = get_next_line tokens
							single.test = binary_expression stack

							single.block = new Block(tokens[0].at_line)
							stack = get_next_block tokens
							single.block.children = parse_block stack

						node.blocks.push single

					result.push node

					### WHILE LOOP ###
				else if tokens[0].value is 'while'
					node = new WhileLoop(tokens[0].at_line)

					# Remove the while token
					tokens.shift()

					# Find the test expression
					stack = get_next_line tokens
					node.test = binary_expression stack

					# Get everything inside the while loop
					node.block = new Block(tokens[0].at_line)
					stack = get_next_block tokens
					node.block.children = parse_block stack

					result.push node

					### FOR LOOP ###
				else if tokens[0].value is 'for'
					node = new ForLoop(tokens[0].at_line)
					
					# Remove the for token
					tokens.shift()

					# Find the parameters
					stack = get_next_line tokens

					# Find the variable to be used
					if stack[0].type is 'variable'
						node.variable = stack[0].value
					else
						throw error 'Expected variable as first parameter on line ' + stack[0].at_line

					if stack[1].value isnt 'in'
						throw error 'For loop must follow format "for ... in [...]" on line ' + stack[0].at_line

					# Ensure proper range notation
					if stack[2].type isnt 'open_brackets'
						throw error 'For loop must have a range on line ' + stack[0].at_line

					stack.splice(0, 3)

					start_stack = []
					until stack[0].type is 'range_seperator'
						start_stack.push stack.shift()

					node.start = binary_expression start_stack

					if stack[0].type isnt 'range_seperator'
						throw error 'For loop range is missing start/end seperator on line ' + stack[0].at_line

					stack.shift()

					end_stack = []
					until stack[0].type is 'close_brackets'
						end_stack.push stack.shift()

					node.end = binary_expression end_stack

					stack = get_next_block tokens

					node.block = new Block(tokens[0].at_line)
					node.block.children = parse_block stack


					result.push node
				else if tokens[0].value is 'function'
					node = new FunctionDefine(tokens[0].at_line)

					tokens.shift()

					if tokens[0].type is 'function_call'
						node.name = tokens.shift().value
					else
						throw error 'Function definition needs a name at line ' + tokens[0].at_line

					# Get function parameters
					stack = get_all_params tokens

					if stack[stack.length - 1].type is 'close_parinthesis'
						stack.pop()

					params = []

					while stack.length > 0
						params.push binary_expression get_next_param stack

					node.params = params
						
					# Get function body
					node.block = new Block(tokens[0].at_line)

					node.block.children = parse_block get_next_block tokens
					
					result.push node

				stack = []
				continue

				### BLOCK CONTINUE ###
			when 'block_continue'
				# Throw an error if a block continue is by itself.
				throw error 'Block continue found by itself on line ' + tokens[0].at_line + '. Could be an "else" by without a matching "if"'

				### BINARY EXPRESSION ###
			when 'binary_operator', 'function_call', 'variable', 'number', 'string'
				until tokens.length < 1 or tokens[0].type is 'line_break'
					stack.push tokens.shift()
				result.push binary_expression remove_line_breaks stack
				stack = []

			when 'include'
				stack = get_next_line tokens
				
				result.push new Include(stack[1].at_line, stack[1].value)

				stack = []

			else
				stack.push tokens.shift()

	result

parse = (code) ->
	res = new Block(0)

	res.children = parse_block(code)

	res

module.exports = parse