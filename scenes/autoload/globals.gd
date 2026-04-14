extends Node

var amount := 0
var seed_amount: int:
	get:
		return amount
	set(value):
		amount = clamp(value, 0, 5)

var last_saved_sequence: Array = []
