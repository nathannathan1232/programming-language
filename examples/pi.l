@include "./stdlib.js"

# Calculates digits of pi using one of
# the fastest possible algorithms
function pi(iterations)
	res = 0
	i = 0

	while i < iterations
		res +=
			(0-1)**i * factorial(6 * i) * (13591409 + 545140134 * i) /
			(factorial(3*i) * factorial(i) ** 3 * 640320 ** (3 * i + 3 / 2))

		print(i += 1)

	1 / (res * 12)

# 3 iterations gives us 43 correct digits
print(p = pi(3))
