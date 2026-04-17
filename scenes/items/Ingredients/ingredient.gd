extends StaticBody3D

@export var ingredient_tag: String
@export var ingredient_scene: PackedScene  # watermelon/mist/etc scene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func interact(player, hand):
	# Do nothing if E is pressed
	if hand == "none":
		return
	
	var held_item = player.get_hand_item(hand)
	
	# Disable placing back item to a wrong place
	if held_item != null and held_item.tag != ingredient_tag:
		# print("Wrong item type")
		return
	
	# TAKE from source
	if held_item == null:
		player.give_item_to_hand(ingredient_scene, hand)
		
		# Ingredients that are finite
		if ingredient_tag == "moon_seed":
			call_deferred("queue_free")
		return
	
	# PUT BACK to source
	# Disabled
	'''
	if held_item.tag == ingredient_tag:
		held_item.queue_free()
		player.clear_hand_item(hand)
		return
	'''

func get_interaction_text(player):
	return "Left/Right click: Take " + ingredient_tag
