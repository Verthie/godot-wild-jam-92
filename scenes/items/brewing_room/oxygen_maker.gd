extends StaticBody3D

signal produced_oxygen

var stored_items = []
var visual_items = []

@export var capacity := 2

@export var ingredient_scenes := {
	"watermelon": preload("res://scenes/items/Ingredients/watermelon_item.tscn"),
	"pumpkin": preload("res://scenes/items/Ingredients/pumpkin_item.tscn"),
	"carrot": preload("res://scenes/items/Ingredients/carrot_item.tscn"),
	"mist_seed": preload("res://scenes/items/Ingredients/mist_seed_item.tscn"),
	"mush_seed": preload("res://scenes/items/Ingredients/mush_seed_item.tscn"),
	"beetroot": preload("res://scenes/items/Ingredients/beetroot_item.tscn"),
	"potato": preload("res://scenes/items/Ingredients/potato_item.tscn")
}

@onready var holder = $Holder
@onready var slots = [$Holder/Slot0, $Holder/Slot1]

var correct_recipe = ["mist_seed", "watermelon"]


func interact(player, hand):

	# Press E should do nothing on the brewing stand
	# NOTE VERT: Changing some stuff just for testing
	# NOTE Mainly just allowing to produce oxygen using the oxygen maker by pressing "e" on it
	# NOTE Can be deleted/changed later just make sure to emit the same signal as I placed at the end when you implement producing the oxygen
	if hand == "none":
		# return
		# CHANGES:
		if stored_items.size() != capacity:
			return

		if stored_items == correct_recipe:
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
			return

		var tag = item.tag
		stored_items.append(item.tag)

		item.queue_free()
		player.clear_hand_item(hand)
		# print("Inserted: ", tag)

		# spawn visual item
		var scene = ingredient_scenes.get(tag, null)
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
		var scene = ingredient_scenes.get(tag, null)
		if scene:
			player.give_item_to_hand(scene, hand)

		# print("Took back: ", tag)


func get_interaction_text(player):
	if stored_items == correct_recipe:
		return "Produce oxygen"
	elif stored_items.size() >= capacity:
		return "Oxygen Dispenser\nFull"
	elif stored_items.size() == 0:
		return "Oxygen Dispenser\nLeft/Right: Insert"
	else:
		return "Oxygen Dispenser\nLeft/Right: Insert / Take"
