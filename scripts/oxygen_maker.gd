extends StaticBody3D

var stored_items = []

@export var ingredient_scenes := {
	"watermelon": preload("res://scenes/items/Ingredients/watermelon_item.tscn"),
	"pumpkin": preload("res://scenes/items/Ingredients/pumpkin_item.tscn"),
	"carrot": preload("res://scenes/items/Ingredients/carrot_item.tscn"),
	"mist_seed": preload("res://scenes/items/Ingredients/mist_seed_item.tscn"),
	"mush_seed": preload("res://scenes/items/Ingredients/mush_seed_item.tscn")
}

@onready var holder = $Holder

var valid_items = ["mist_seed", "watermelon"]


func interact(player, hand):
	var item = player.get_hand_item(hand)
	
	# --- PUT ---
	if item != null:
		if item.tag not in valid_items:
			print("Invalid item")
			return
		
		stored_items.append(item)
		
		item.reparent(holder, false)
		item.position = Vector3(0, 0, stored_items.size() * 0.1)
		
		player.clear_hand_item(hand)
		print("Inserted:", item.tag)
		return
	
	# --- TAKE ---
	if item == null and stored_items.size() > 0:
		var taken = stored_items.pop_back()
		
		var hand_node = player.hand_left if hand == "left" else player.hand_right
		taken.reparent(hand_node, false)
		
		if hand == "left":
			player.left_hand_item = taken
		else:
			player.right_hand_item = taken
		
		var scene = ingredient_scenes[taken.tag]
		if scene:
			player.give_item_to_hand(scene, hand)
		
		print("Took back item")


func get_interaction_text(player):
	return "Left/Right: Insert/Take Out Mist Seed / Watermelon)"
