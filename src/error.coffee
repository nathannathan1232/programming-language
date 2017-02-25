error = (text) ->
	'\x1b[31mError: \x1b[0m\x1b[1m\x1b[31m' + text + '\x1b[0m'

module.exports = error