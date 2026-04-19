extends StaticBody3D

func interact(player, hand):
	# Press E should do nothing on the trash can
	if hand == "none":
		return

	var item = player.get_hand_item(hand)

	if item != null:
		# Moon seed and cure cannot be thrown away in trash can
		var unthrowable_items = ["moon_seed", "cure"]
		if item.tag in unthrowable_items:
			return

		AudioManager.create_3d_audio_at_location(self.global_position, SoundEffect.SoundEffectType.TRASH_ITEM)

		item.queue_free()
		player.clear_hand_item(hand)
		# print("Item trashed")

func get_interaction_text(player):
	return "Trash Can\nLeft/Right: Throw item"
