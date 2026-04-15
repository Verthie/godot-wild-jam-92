extends StaticBody3D

func interact(player, hand):
	var item = player.get_hand_item(hand)
	
	if item != null:
		item.queue_free()
		player.clear_hand_item(hand)
		print("Item trashed")
		
func get_interaction_text(player):
	return "Left/Right: Throw item"
