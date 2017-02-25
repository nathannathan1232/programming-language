# This is the main file.
# Run using: coffee -c . && node index.js <filename>
# Replace <filename> with the name of your file with the source code.

lex          = require('./lex.js')
parse        = require('./parse2.js')
exec         = require('./exec.js')

print_lex    = require('./print-lex.js')
print_parsed = require('./print-parsed.js')

fs           = require('fs')

filename = process.argv[2]

time = new Date()

code = fs.readFileSync(filename).toString()
l = lex code
#console.log print_lex l
p = parse l
#print_parsed p

exec p

new_time = new Date()
t = time.getTime() - new_time.getTime()
console.log Math.abs(t) + 'ms' + ' | ' + Math.abs(t / 1000) + 's'
