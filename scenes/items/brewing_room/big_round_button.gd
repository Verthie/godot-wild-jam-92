extends StaticBody3D

@export var brewing_stand_path: NodePath
var brewing_stand
@export var sampler_path: NodePath
var sampler

@export var cutscene_manager: Node
var shown_first_text := false

func _ready():	
	# Connect to brewing stand
	if brewing_stand_path != NodePath():
		brewing_stand = get_node(brewing_stand_path)
	else:
		print("Button says: Brewing stand not found in scene")
	
	# Connect to sampler
	if sampler_path != NodePath():
		sampler = get_node(sampler_path)
	else:
		print("Button says: Sampler not found in scene")


func interact(player, hand):
	if not shown_first_text and cutscene_manager.second_cutscene_done:
		player.show_ui("slots", Globals.UITextType.TUTORIAL)
		shown_first_text = true
		
	# Only allow pressing E on the BIG ROUND BUTTON
	if hand != "none":
		return
	
	brewing_stand.start_brewing()

func get_interaction_text(player):

	
	if not sampler.locked:
		return "Sampler not activated"
	if sampler.remaining_brews <= 0:
		return "Sampler depleted"
	
	if brewing_stand.current_index >= 5:
		return "Press E to brew!"
	else:
		return "Big Round Button\nNeed 5 items!"
