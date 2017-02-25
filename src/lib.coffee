error = require('./error.js')
Decimal = require('./decimal.js')

class Value
	constructor: (type, value, options) ->
		@type = type
		@value = value

		if type is 'number'
			@value = new Decimal(value)

		if options
			for i of options
				@[i] = options[i]

	# Make sure that an object is a proper value
	is_value_object: (v) ->
		typeof v is 'object' and
			v.hasOwnProperty('type') and
			v.hasOwnProperty('value') and
			true or false

	ValueArray: ValueArray

class ValueArray
	constructor: (options) ->

		@type = 'array'

		@items = []

		if options
			for i of options
				@[i] = options[i]

	set_val: (i, v) ->
		@items[i] = v

	get_val: (i) ->
		if 0 <= i <= @items.length - 1
			@items[i]
		else
			new Value('boolean', false)

	push: (v) ->
		@items.push v

	pop: (v) ->
		@items.pop()

# Converts a value into another type. For example string -> number.
# Takes a value object and returns a value object.
convert_value = (v, type) ->
	if not Value::is_value_object v
		throw error v

	if v.type is type
		return v

	#console.log v.type + '->' + type
	switch v.type + '->' + type
		when 'number->string'
			new Value('string', v.value.toString())

		when 'string->number'
			new Value('number', v.value.toString())

		when 'boolean->number'
			new Value('number', if v.value is true then 1 else 0)

		when 'number->boolean'
			new Value('boolean', if v.value.isZero() then false else true)

		when 'string->boolean'
			new Value('boolean', if v.value is 'true' then true else false)

		when 'boolean->string'
			new Value('string', v.value.toString())

		else
			throw error 'Can not convert ' + v.type + ' to ' + type

# Returns true if a value is truthy. Everything is truthy except:
# number -> 0
# boolean -> false
# string -> ""
is_truthy = (v) ->
	if not Value::is_value_object v
		throw error v

	switch v.type
		# Booleans area easy. Just true or false
		when 'boolean'
			v.value is true or v.value is 'true'
		
		# 0 or -0 evaluates to false. Everything else it true
		when 'number'
			if v.value.isZero() then false else true

		# Strings return true unless it's an empty string
		when 'string'
			if v.value is '' then false else true

# Are two values similar?
# Generally if the values are equal after a conversion
# to string, they are similar.
# 
# Examples
# "true" == true -> true
# "50"   == 50   -> true
# false  == 0    -> true
# true   == 5    -> false
# true   == 1    -> true
# true   == "1"  -> false
similar = (a, b) ->
	if a.type is 'boolean' and b.type is 'number'
		if ((b.value is '0' and a.value is false) or (b.value is '1' and a.value is true))
			return true

		else
			return false

	if b.type is 'boolean' and a.type is 'number'
		if ((a.value is '0' and b.value is false) or (a.value is '1' and b.value is true))
			return true

		else
			return false

	# Just incase the string convert is going to mess it up, check before conversion.
	if a.value is b.value
		return true

	na = convert_value(a, 'string').value
	nb = convert_value(b, 'string').value

	return na == nb

more_than = (a, b) ->
	chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
		.split('')

	if a.type is 'number' and b.type is 'number'
		return if a.value.lessThanOrEqualTo(b.value) then false else true

	a = convert_value(a, 'string').value
	b = convert_value(b, 'string').value

	if a.length isnt b.length
		return a.length > b.length

	for i in [0...a.length]
		if chars.indexOf(a[i]) isnt chars.indexOf(b[i])
			return chars.indexOf(a[i]) > chars.indexOf(b[i])
	false

ASSIGNMENT_OPERATORS = [
	'=', ':=', '+=', '-=', '*=', '/=', '%=', '.='
]

# Operators that return a number
NUMERICAL_OPERATORS = [
	'+', '-', '*', '/', '%', '|', '&', '**', '<<', '>>'
]

LOGICAL_OPERATORS = [
	'&&', '||', '^'
]

# Operators that return a boolean
BOOLEAN_OPERATORS = [
	'<', '>', '>=', '<=', '!=', '~~'
]

# Preforms a binary operation on two values. Inputs must be value objects,
# and a value object will always be returned.
binary_operation = (a, b, op) ->
	if not Value::is_value_object a or not Value::is_value_object b
		throw error 'Invalid operation ' + op + ' on ' + a + ' and ' + b

	# If a numerical operator is being used, convert both values to a number
	if NUMERICAL_OPERATORS.includes op
		na = convert_value(a, 'number').value
		nb = convert_value(b, 'number').value

	switch op
		# Numerical Operators
		when '+'
			new Value('number', na.add(nb))
		when '-'
			new Value('number', na.minus(nb))
		when '*'
			new Value('number', na.times(nb))
		when '/'
			new Value('number', na.dividedBy(nb))
		when '%'
			new Value('number', na.modulo(nb))
		when '**'
			new Value('number', na.pow(nb))
		when '<<'
			new Value('number', na.bitShift(nb))
		when '>>'
			new Value('number', na.bitUnShift(nb))

		# Boolean operators
		when '=='
			new Value('boolean', similar(a, b))
		when '!='
			new Value('boolean', not similar(a, b))
		when '>'
			new Value('boolean', more_than(a, b))
		when '>='
			new Value('boolean', more_than(a, b) or similar(a, b))
		when '<='
			new Value('boolean', not more_than(a, b))
		when '<'
			new Value('boolean', not (more_than(a, b) or similar(a, b)))

		# When concating, make the result have the type of the first value.
		when '.'
			na = convert_value(a, 'string')
			nb = convert_value(b, 'string')
			new Value('string',
				na.value + '' + nb.value
			)

		# && returns the second value if both are truthy, otherwise false.
		when '&&'
			if is_truthy(a) and is_truthy(b)
				return b

			else
				return new Value('boolean', false)

		# || returns the first value if it's truthy, otherwise the second value.
		# A sequence of them will return the first item that's truthy.
		when '||'
			return if is_truthy(a) then a else b

		# XOR operator. If only one is true, return it. Otherwise return false.
		when '^'
			if is_truthy(a) ^ is_truthy(b)
				return if is_truthy(a) then a else b
			
			else
				return new Value('boolean', false)

		else
			throw error 'can not preform operation ' + op +
			' between ' + a.type + ' and ' + b.type
		
module.exports = {
	# Variables
	NUMERICAL_OPERATORS
	ASSIGNMENT_OPERATORS
	LOGICAL_OPERATORS
	BOOLEAN_OPERATORS

	# Functions
	binary_operation
	is_truthy
	convert_value

	# Classes
	Value
	ValueArray
}