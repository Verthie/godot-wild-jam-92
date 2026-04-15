extends StaticBody3D

var stored_item = null

@export var ingredient_scenes := {
	"watermelon": preload("res://scenes/items/Ingredients/watermelon_item.tscn"),
	"pumpkin": preload("res://scenes/items/Ingredients/pumpkin_item.tscn"),
	"carrot": preload("res://scenes/items/Ingredients/carrot_item.tscn"),
	"mist_seed": preload("res://scenes/items/Ingredients/mist_seed_item.tscn"),
	"mush_seed": preload("res://scenes/items/Ingredients/mush_seed_item.tscn")
}

@onready var holder = $Holder

func interact(player, hand):
	var item = player.get_hand_item(hand)
	
	# --- PUT ---
	if item != null and stored_item == null:
		stored_item = item
		
		item.reparent(holder, false)
		item.position = Vector3.ZERO
		item.scale = Vector3(0.8, 0.8, 0.8)
		
		player.clear_hand_item(hand)
		print("Item placed in bowl")
		return
	
	# --- TAKE ---
	if item == null and stored_item != null:
		var taken = stored_item
		stored_item = null
		
		var hand_node = player.hand_left if hand == "left" else player.hand_right
		taken.reparent(hand_node, false)
		
		player.left_hand_item = taken if hand == "left" else player.left_hand_item
		player.right_hand_item = taken if hand == "right" else player.right_hand_item
		
		var scene = ingredient_scenes[taken.tag]
		if scene:
			player.give_item_to_hand(scene, hand)
			
		print("Item taken from bowl")


func get_interaction_text(player):
	if stored_item == null:
		return "Bowl\nLeft/Right: Put item"
	else:
		return "Bowl\nLeft/Right: Take item"
