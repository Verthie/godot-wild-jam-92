extends StaticBody3D

var current_items = [null, null, null, null, null]
var current_index := 0
var output_item = null
var cure_crafted = false

var correct_recipe = []
# Example: ["watermelon", "pumpkin", "carrot", "watermelon", "mush_seed"]

# remember to check export (Inspector), do it on brewing_stand in Main_Scene
@export var board_path: NodePath 
var board
@export var sampler_path: NodePath
var sampler

@onready var output_slot = $OutputSlot  # Node3D in front


func generate_recipe():
	var ingredients = ["watermelon", "pumpkin", "carrot", "mist_seed", "mush_seed",
	"potato", "beetroot"]
	var outside_ingredients = ["mist_seed", "mush_seed"]
	var recipe = []

	while recipe.size() < 5:
		var next = ingredients.pick_random()

		# no more than 2 in a recipe
		if recipe.count(next) >= 2:
			continue

		recipe.append(next)

	if recipe.count("mist_seed") + recipe.count("mush_seed") < 1:
		# force replace one slot with outside item
		recipe[randi() % 5] = outside_ingredients.pick_random()

	print("Shh, the recipe is: ", recipe)
	return recipe


func _ready() -> void:
	# Connect brewing stand to sampler
	if sampler_path != NodePath():
		sampler = get_node(sampler_path)
	else:
		print("Sampler not found in scene")
	
	
	# Connect brewing stand to wordle board
	if board_path != NodePath():
		board = get_node(board_path)
	else:
		print("Board path not found in scene")
	
	# Generate a random recipe
	correct_recipe = generate_recipe()


func interact(player, hand):
	# Press E should do nothing on the brewing stand
	if hand == "none":
		return
	
	# If sampler is empty
	if sampler.remaining_brews <= 0:
		return

	var held_item = player.get_hand_item(hand)
	
	# --- Force player to take vial first ---
	if output_item != null:
			return
	

	# --- CASE 1: player holding item → put into stand ---
	if held_item:
		if current_index >= 5:
			# print("Stand full!")
			AudioManager.create_audio(SoundEffect.SoundEffectType.BREWERY_WRONG)
			return

		AudioManager.create_audio(SoundEffect.SoundEffectType.INSERT_INGREDIENT)

		add_ingredient(held_item.tag)

		# remove from player
		held_item.queue_free()
		player.clear_hand_item(hand)

		return

	# --- CASE 2: empty hand → take last item ---
	if current_index > 0:
		current_index -= 1
		board.remove_last_icon(current_index)

		var item_tag = current_items[current_index]
		current_items[current_index] = null

		var scene = Globals.ingredient_scenes[item_tag]
		if scene:
			player.give_item_to_hand(scene, hand)

		return



func add_ingredient(item_tag):
	current_items[current_index] = item_tag
	board.add_ingredient_icon(item_tag, current_index)

	current_index += 1

	# print("Current items:", current_items)


func start_brewing():
	# --- Test conditions ---
	# -----------------------------------
	# block if output (vial) not taken
	if output_item != null:
		return
		
	if current_index < 5:
		# print("Need all 5 ingredients!")
		return
	
	if not sampler.locked:
		return
	
	if sampler.remaining_brews <= 0:
		return
	# -------------------------------------
	
	# Confirm start brewing
	print("Brewing started...")

	var result = evaluate_guess(current_items, correct_recipe)

	if board:
		board.display_result(result)
	
	if current_items == correct_recipe:
		print("Congrats! You've crafted a CURE")
		cure_crafted = true
		spawn("cure")
	else:
		spawn("bad_vial")
		
	sampler.brew() # Use up one moon_seed
	reset_items()
	
	if sampler.remaining_brews <=0 and not cure_crafted:
		print("You lost the game bro")
		# TODO trigger game lost sequence


func reset_items():
	current_items = [null, null, null, null, null]
	current_index = 0


func spawn(type: String):
	var scene
	
	if type == "cure":
		scene = preload("res://scenes/items/vials/cure.tscn")
	else:
		scene = preload("res://scenes/items/vials/vial_bad.tscn")
	
	if scene:
		output_item = scene.instantiate()
		output_slot.add_child(output_item)
		
		output_item.transform = Transform3D.IDENTITY


# Wordle
func evaluate_guess(guess: Array, correct_recipe: Array) -> Array:
	var result = []
	var ingredients_evaluated = []

	# initialize
	for i in range(correct_recipe.size()):
		result.append("gray")
		ingredients_evaluated.append(false)

	# --- PASS 1: GREEN (correct position) ---
	for i in range(guess.size()):
		if guess[i] == correct_recipe[i]:
			result[i] = "green"
			ingredients_evaluated[i] = true

	# --- PASS 2: YELLOW (correct item, wrong position) ---
	for i in range(guess.size()):
		if result[i] == "green":
			continue

		for j in range(correct_recipe.size()):
			if not ingredients_evaluated[j] and guess[i] == correct_recipe[j]:
				result[i] = "yellow"
				ingredients_evaluated[j] = true
				break

	return result

func get_interaction_text(player):
	# block if output (vial) not taken
	if output_item != null:
		return "Take the vial first!"
	if not sampler.locked:
		return "Sampler not activated"
	if sampler.remaining_brews <= 0:
		return "Sampler depleted"
	if current_index < 5:
		return "Brewing Stand\nLeft/Right: Insert/Take out item"
	else:
		return "Brewing Stand\nReady to Brew!"
