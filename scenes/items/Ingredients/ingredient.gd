extends StaticBody3D

@export var ingredient_tag: String
@export var ingredient_scene: PackedScene  # watermelon/mist/etc scene
@export var finite_enabled: bool = false


func interact(player, hand):
	# Do nothing if E is pressed
	if hand == "none":
		return

	var held_item = player.get_hand_item(hand)

	EventBus.taken_item.emit()
	AudioManager.create_audio(SoundEffect.SoundEffectType.PICK_UP_INGREDIENT)

	# Disable placing back item to a wrong place
	if held_item != null and held_item.tag != ingredient_tag:
		# print("Wrong item type")
		return

	# TAKE from source
	if held_item == null:
		player.give_item_to_hand(ingredient_scene, hand)

		# Ingredients/items that are finite (disappears after picking up)
		var finite_ingredients = ["moon_seed", "vial_bad", "cure"]
		if ingredient_tag in finite_ingredients or finite_enabled:
			call_deferred("queue_free")
		return


func get_interaction_text(_player):
	return "Left/Right click: Take " + ingredient_tag
