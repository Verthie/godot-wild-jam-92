extends StaticBody3D

@export var stand_path: NodePath
var brewing_stand

func _ready():
	brewing_stand = get_node(stand_path)

func interact(player, hand):
	if hand != "none":
		return  # only allow E
	
	brewing_stand.start_brewing()
