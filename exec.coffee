error = require('./error.js')
lib = require('./lib.js')
Decimal = require('./decimal.js')

ASSIGNMENT_OPERATORS = [
	'=', ':=', '+=', '-=', '*=', '/=', '%=', '.='
]

class VariableList
	constructor: ->
		@vars = []

	get_var: (name) ->
		if @vars.hasOwnProperty(name)
			@vars[name]

		else
			throw error name + ' is not defined!'

	set_var: (name, value) ->
		@vars[name] = value

	merge: (scope) ->
		for i of scope.vars
			if scope.vars.hasOwnProperty(i)
				@set_var(i, scope.vars[i])

load_module = (filename, scope) ->
	m = require(filename)

	for i of m.variables
		scope.set_var(i, m.variables[i])

	for i of m.functions
		f = new lib.Value('function', 'native', {
			function_type: 'native'
			params: m.functions[i].params
			block: m.functions[i].block
		})
		scope.set_var(i, f)


# Runs one node from a tree. Guarenteed to return a proper value object.
run = (node, scope) ->

	switch node.type
		# Loads a module from file
		when 'include'
			load_module(node.name, scope)

		# Runs a code block. The return value is whatever is run last.
		when 'block'
			for i in node.children
				res = run(i, scope)

			res

		when 'function-define'
			scope.set_var(node.name, new lib.Value('function', 'local', {
				params: node.params
				block: node.block
			}))

		when 'function-call'
			fn = scope.get_var(node.name)

			# Create local scope
			local_scope = new VariableList()
			local_scope.merge(scope)


			# Local function
			if fn.value is 'local'
				for i in [0...fn.params.length]
					local_scope.set_var(fn.params[i].name, run(node.params[i], scope))
				return run(fn.block, local_scope)

			# Native function
			else
				for i in [0...fn.params.length]
					local_scope.set_var(fn.params[i], run(node.params[i], scope))
				
				return fn.block(local_scope)

		when 'if'
			res = new lib.Value('boolean', false)
			for i in [0...node.blocks.length]				
				if lib.is_truthy(run node.blocks[i].test, scope)
					res = run node.blocks[i].block, scope
					break
			res

		when 'while'
			res = new lib.Value('boolean', false)
			while lib.is_truthy(run node.test, scope)
				res = run node.block, scope

			res
		# Returns a value from a binary expression
		when 'binary_expression'
			if ASSIGNMENT_OPERATORS.includes node.operator
				
				if node.left.type is 'variable'
					if node.operator is '='
						scope.set_var(node.left.name, run(node.right, scope))

					# Something like += or *=
					else
						scope.set_var(
							node.left.name 
							lib.binary_operation(
								scope.get_var(node.left.name)
								run(node.right, scope)
								node.operator.replace(/\=/, '')
							)
						)
				else if node.left.type is 'array_call'
					arr = scope.get_var(node.left.name)
					index = run(node.left.index, scope).value.toString()

					if node.operator is '='
						arr.set_val(index, run(node.right, scope))

					else
						arr.set_val(
							index 
							lib.binary_operation(
								arr.get_val(index)
								run(node.right, scope)
								node.operator.replace(/\=/, '')
							)
						)
				else
					console.log node.left
					throw error 'Invalid expression on left side of assignment operator. Line ' +
						node.line

			else
				lib.binary_operation(
					run(node.left, scope)
					run(node.right, scope)
					node.operator
				)

		when 'array_literal'
			res = new lib.ValueArray()

			for i in [0...node.items.length]
				res.push run(node.items[i], scope)

			res

		when 'array_call'
			arr = scope.get_var(node.name)

			index = run(node.index, scope)


			arr.get_val Number index.value+''


		# This only gets a variable. The binary expression will
		# take care of setting variables.
		when 'variable'
			scope.get_var(node.name)

		# Returns a new value based on the node value
		when 'constant'
			value = node.value

			return new lib.Value(
				node.const_type
				value
			)

exec = (code) ->
	run(code, new VariableList())
	console.log '---'

module.exports = exec