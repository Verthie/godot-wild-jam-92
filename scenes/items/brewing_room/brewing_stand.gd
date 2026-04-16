extends StaticBody3D

@export var ingredient_scenes := {
	"watermelon": preload("res://scenes/items/Ingredients/watermelon_item.tscn"),
	"pumpkin": preload("res://scenes/items/Ingredients/pumpkin_item.tscn"),
	"carrot": preload("res://scenes/items/Ingredients/carrot_item.tscn"),
	"mist_seed": preload("res://scenes/items/Ingredients/mist_seed_item.tscn"),
	"mush_seed": preload("res://scenes/items/Ingredients/mush_seed_item.tscn"),
	"beetroot": preload("res://scenes/items/Ingredients/beetroot_item.tscn"),
	"potato": preload("res://scenes/items/Ingredients/potato_item.tscn")
}

var current_items = [null, null, null, null, null]
var current_index := 0
# Just for testing
var correct_recipe = []
# Example: ["watermelon", "pumpkin", "carrot", "watermelon", "mush_seed"]

@export var board_path: NodePath # remember to check export (Inspector)
var board

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
	# Connect brewing stand to wordle board
	if board_path != NodePath():
		board = get_node(board_path)
	else:
		print("Board path not assigned!")
	correct_recipe = generate_recipe()


func interact(player, hand):
	# Press E should do nothing on the brewing stand
	if hand == "none":
		return

	var held_item = player.get_hand_item(hand)

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

		var scene = ingredient_scenes[item_tag]
		if scene:
			player.give_item_to_hand(scene, hand)

		return



func add_ingredient(item_tag):
	current_items[current_index] = item_tag
	board.add_ingredient_icon(item_tag, current_index)

	current_index += 1

	# print("Current items:", current_items)


func start_brewing():
	if current_index < 5:
		# print("Need all 5 ingredients!")
		return

	print("Brewing started...")

	var result = evaluate_guess(current_items, correct_recipe)

	if board:
		board.display_result(result)

	reset_items()

func reset_items():
	current_items = [null, null, null, null, null]
	current_index = 0

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

	if current_items == correct_recipe:
		print("Congrats! You've crafted a CURE")

	return result

func get_interaction_text(player):
	if current_index < 5:
		return "Brewing Stand\nLeft/Right: Insert/Take out item"
	else:
		return "Brewing Stand\nReady to Brew!"
