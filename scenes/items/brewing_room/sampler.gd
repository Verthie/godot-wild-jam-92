extends StaticBody3D


var locked := false

var max_brews := 5
var remaining_brews := 5

@onready var display_label: Label3D = $NumberDisplay/Label3D

func _ready() -> void:
	update_display()

func interact(player, hand):
	# Interact by left click or right click
	if hand == "none":
		return
	
	# already locked → no interaction at all
	if locked:
		return
	
	var item = player.get_hand_item(hand)
	
	# --- INSERT MOON SEED ---
	if item != null and item.tag == "moon_seed" and not locked:
		locked = true
		
		remaining_brews = max_brews
		update_display()
		
		item.queue_free()
		player.clear_hand_item(hand)
		
		# play sound (insert moon seed / item)
		# play sound (sampler locked)
		return

func brew():
	remaining_brews -= 1
	update_display()


func update_display():
	if not locked:
		display_label.text = "4"
	elif remaining_brews > 0:
		display_label.text = str(remaining_brews)
	else:
		display_label.text = "0"


func get_interaction_text(player):
	if not locked:
		return "Please Insert Moon Seed"
	
	if remaining_brews > 0:
		return "Brews Left: " + str(remaining_brews)
	
	return "Sampler Depleted"
