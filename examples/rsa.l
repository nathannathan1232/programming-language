# Generates an RSA encryption key.
# Work in progress

@include "./stdlib.js"

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

function getPrimes()
	# Generate random starting numbers
	a = floor(random(1000) * 1e4)
	b = floor(random(1000) * 1e4)
	
	# Make numbers even
	if a % 2 == 0
		a += 1
	if b % 2 == 0
		b += 1
	
	# Increment until they're prime
	while not(isPrime(a))
		a += 2
	while not(isPrime(b))
		b += 2

	[a, b]

function gcd(a, b)
	i = 0
	if a < b
		l = a
	else
		l = b

	r = 0

	while i < l
		if a % i == 0 && b % i == 0
			r = i
		i += 1

	r

function lcm(a, b)
	g = gcd(a, b)

	abs(a * b) / g

function getCoPrime(n)
	i = floor(n / 10)

	while not(gcd(i, n))
		i += 1

	i

function key()
	p = getPrimes()

	t = lcm(p[0] - 1, p[1] - 1)

	c = getCoPrime(t)

print(key())

print(getCoPrime(key()))