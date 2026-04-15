extends StaticBody3D

@export var stand_path: NodePath
var brewing_stand

func _ready():
	brewing_stand = get_node(stand_path)

func interact(player, hand):
	# Only allow pressing E on the BIG ROUND BUTTON
	if hand != "none":
		return
	
	brewing_stand.start_brewing()

func get_interaction_text(player):
	if brewing_stand.current_index >= 5:
		return "Press E to brew!"
	else:
		return "Big Round Button\nNeed 5 items!"
