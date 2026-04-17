extends Node

var amount := 0
var seed_amount: int:
	get:
		return amount
	set(value):
		amount = clamp(value, 0, 5)

var last_saved_sequence: Array = []

@export var ingredient_scenes := {
	"watermelon": preload("res://scenes/items/Ingredients/watermelon_item.tscn"),
	"pumpkin": preload("res://scenes/items/Ingredients/pumpkin_item.tscn"),
	"carrot": preload("res://scenes/items/Ingredients/carrot_item.tscn"),
	"mist_seed": preload("res://scenes/items/Ingredients/mist_seed_item.tscn"),
	"mush_seed": preload("res://scenes/items/Ingredients/mush_seed_item.tscn"),
	"beetroot": preload("res://scenes/items/Ingredients/beetroot_item.tscn"),
	"potato": preload("res://scenes/items/Ingredients/potato_item.tscn"),
	
	"moon_seed": preload("res://scenes/items/Ingredients/moon_seed_item.tscn"),
	
	"vial_bad": preload("res://scenes/items/vials/vial_bad_item.tscn"),
	"cure": preload("res://scenes/items/vials/cure_item.tscn")
}

var icon_lookup = {
	"watermelon": preload("res://assets/textures/icons/watermelon.png"),
	"pumpkin": preload("res://assets/textures/icons/pumpkin.png"),
	"carrot": preload("res://assets/textures/icons/carrot.png"),
	"mist_seed": preload("res://assets/textures/icons/mist_seed.png"),
	"mush_seed": preload("res://assets/textures/icons/mush_seed.png"),
	"beetroot": preload("res://assets/textures/icons/beetroot.png"),
	"potato": preload("res://assets/textures/icons/potato.png"),
	
	"moon_seed": preload("res://assets/textures/icons/moon_seed.png"),
	
	"vial_bad": preload("res://assets/textures/icons/vial_bad.png"),
	"cure": preload("res://assets/textures/icons/cure.png")
}
