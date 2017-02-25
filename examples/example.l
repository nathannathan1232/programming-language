# Example file
# Comments start with a '#' and end at the end of the line

# Include libraries with the @include annotation.
# stdlib has standard stuff like print and math functions.
@include "./stdlib.js"

# Declare functions like this.
# It will automatically return the result of the expression on the last line.
function add(a, b)
	a + b

# Call functions like this.
n = add(5, 8)

# Operators work too.
n += 5 * (4 % 3) - 100

# Other stuff
array = [0, 1, 2, 3, 4, 5]

array[6] = array[2] + array[5]

array[7] = 1e10

print(array)

# If statments and loops work
i = 0
if i < 5
	i += 3

while i < 100
	print(i += 1)

# Nesting also works

while i > 0
	if i % 2 == 0
		i -= 3
	else
		i += 1
	print(i)

# Function to test wether or not a number is prime.
function isPrime(n)
	res = true
	
	if n <= 1 || n % 2 == 0 || n % 3 == 0
		res = false

	i = 5
	while i * i <= n
		if n % i == 0 || n % (i + 2) == 0
			res = false
		i += 6

	if n == 2 || n == 3
		res = true

	res

nums = [0, 4, 5, 10, 77, 101, 504, 707, 803, 1001]

i = 0
# Period is the concat operator.
while i < 10
	print(nums[i] . "  " . isPrime(nums[i]))
	i += 1

