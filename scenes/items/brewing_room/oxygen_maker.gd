extends StaticBody3D

signal produced_oxygen

var stored_items = []
var visual_items = []

@export var capacity := 2

@onready var holder = $Holder
@onready var slots = [$Holder/Slot0, $Holder/Slot1]

var correct_recipe = ["mist_seed", "watermelon"]

@export var cutscene_manager: Node
var shown_first_text := false

func interact(player, hand):
	if not shown_first_text and cutscene_manager.second_cutscene_done:
		player.show_ui("o2", Globals.UITextType.TUTORIAL)
		shown_first_text = true
	
	# Press E should do nothing on the brewing stand
	# NOTE VERT: Changing some stuff just for testing
	# NOTE Mainly just allowing to produce oxygen using the oxygen maker by pressing "e" on it
	# NOTE Can be deleted/changed later just make sure to emit the same signal as I placed at the end when you implement producing the oxygen
	# Jason: Changed the check condition so either order of mist and watermelon works
	# (Since there are only two items, I'll just use this method to check)
	if hand == "none":
		# return
		# CHANGES:
		if stored_items.size() != capacity:
			return

		if stored_items[0] in correct_recipe and stored_items[1] in correct_recipe:
			stored_items.clear()
			visual_items.clear()
			for slot: Node3D in slots:
				for node in slot.get_children():
					node.queue_free()
			produced_oxygen.emit()

		return


	var item = player.get_hand_item(hand)

	# --- PUT ---
	if item != null:
		if stored_items.size() >= capacity:
			# print("Oxygen dispenser is full")
			AudioManager.create_audio(SoundEffect.SoundEffectType.BREWERY_WRONG)
			return

		AudioManager.create_audio(SoundEffect.SoundEffectType.INSERT_INGREDIENT)
		var tag = item.tag
		stored_items.append(item.tag)

		item.queue_free()
		player.clear_hand_item(hand)
		# print("Inserted: ", tag)

		# spawn visual item
		var scene = Globals.ingredient_scenes.get(tag, null)
		if scene:
			var instance = scene.instantiate()
			var index = stored_items.size() - 1
			var slot = slots[index]
			slot.add_child(instance)


			instance.scale = Vector3(0.6, 0.6, 0.6)

			# slight randomness
			instance.rotation_degrees.y = randf() * 360

			visual_items.append(instance)

		return


	# --- TAKE ---
	if item == null and stored_items.size() > 0:
		var tag = stored_items.pop_back()

		# remove visual
		var visual = visual_items.pop_back()
		if visual:
			visual.queue_free()

		# give real item back
		var scene = Globals.ingredient_scenes.get(tag, null)
		if scene:
			player.give_item_to_hand(scene, hand)

		# print("Took back: ", tag)


func get_interaction_text(player):
	if stored_items.size() == capacity and stored_items[0] in correct_recipe and stored_items[1] in correct_recipe:
		return "Oxygen Dispenser\nPress E: Produce oxygen"
	elif stored_items.size() >= capacity:
		return "Oxygen Dispenser\nFull"
	elif stored_items.size() == 0:
		return "Oxygen Dispenser\nLeft/Right: Insert"
	else:
		return "Oxygen Dispenser\nLeft/Right: Insert / Take"
