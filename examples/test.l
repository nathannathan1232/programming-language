@include "./stdlib.js"

i = 0
while i < 1000
	i += 1

if i != 1000
	print("Failed at position 0")

while i > 0
	if i % 2 == 0
		i -= 3
	else
		i += 1

if i != 0-1
	print("Failed at position 1")


n =
	8 + 2
	+ 1

if n != 11
	print("Failed at position 2")

a = 1e100
b = 1e-100

if a / b != 1e200 || a * b != 1
	print("Failed at position 3")

print("Test done!")