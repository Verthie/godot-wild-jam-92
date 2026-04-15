extends StaticBody3D

func interact(player, hand):
	# Press E should do nothing on the trash can
	if hand == "none":
		return
	
	var item = player.get_hand_item(hand)
	
	if item != null:
		item.queue_free()
		player.clear_hand_item(hand)
		# print("Item trashed")
		
func get_interaction_text(player):
	return "Trash Can\nLeft/Right: Throw item"
