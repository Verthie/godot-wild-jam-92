extends StaticBody3D

var stored_item = null

@onready var holder = $Holder

var stored_tag = null
var visual_item = null

@export var cutscene_manager: Node
var shown_first_text := false

func interact(player, hand):
	if not shown_first_text and cutscene_manager.second_cutscene_done:
		player.show_ui("bowl", Globals.UITextType.TUTORIAL)
		shown_first_text = true
	
	# Press E should do nothing on the bowl
	if hand == "none":
		return
		
	var item = player.get_hand_item(hand)
	
	# --- PUT ---
	if item != null and stored_tag == null:
		stored_tag = item.tag
		
		item.queue_free()
		player.clear_hand_item(hand)
		
		# create visual in bowl
		var scene = Globals.ingredient_scenes.get(stored_tag, null)
		if scene:
			visual_item = scene.instantiate()
			holder.add_child(visual_item)
			
			visual_item.position = Vector3(0, 0, 0)
			visual_item.scale = Vector3(0.8, 0.8, 0.8)
			
		
		# print("Item placed in bowl: ", stored_tag)
		return
	
	# --- TAKE ---
	if item == null and stored_tag != null:
		var tag = stored_tag
		stored_tag = null
		
		# remove visual
		if visual_item:
			visual_item.queue_free()
			visual_item = null
		
		# spawn real item back on hand
		var scene = Globals.ingredient_scenes.get(tag, null)
		if scene:
			player.give_item_to_hand(scene, hand)
		
		# print("Item taken: ", tag)


func get_interaction_text(player):
	if stored_item == null:
		return "Bowl\nLeft/Right: Put item"
	else:
		return "Bowl\nLeft/Right: Take item"
