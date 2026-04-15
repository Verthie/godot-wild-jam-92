extends StaticBody3D

@export var ingredient_scenes := {
	"watermelon": preload("res://scenes/items/Ingredients/watermelon_item.tscn"),
	"pumpkin": preload("res://scenes/items/Ingredients/pumpkin_item.tscn"),
	"carrot": preload("res://scenes/items/Ingredients/carrot_item.tscn"),
	"mist_seed": preload("res://scenes/items/Ingredients/mist_seed_item.tscn"),
	"mush_seed": preload("res://scenes/items/Ingredients/mush_seed_item.tscn")
}

var current_items = [null, null, null, null, null]
var current_index := 0
# Just for testing
var correct_recipe = ["watermelon", "pumpkin", "carrot", "mist_seed", "mush_seed"]

@export var board_path: NodePath # remember to check export (Inspector)
var board



func _ready() -> void:
	# Connect brewing stand to wordle board
	if board_path != NodePath():
		board = get_node(board_path)
	else:
		print("Board path not assigned!")
	print(evaluate_guess([1,3,2,2,2], [1,2,3,4,5]))



func _process(delta: float) -> void:
	pass

func interact(player, hand):
	# Press E should do nothing on the brewing stand
	if hand == "none":
		return
	
	var held_item = player.get_hand_item(hand)
	
	# --- CASE 1: player holding item → put into stand ---
	if held_item:
		if current_index >= 5:
			print("Stand full!")
			return
		
		if current_items.has(held_item.tag):
			print("Ingredient already added!")
			return
		
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

func get_interaction_text(player):
	return "Left/Right: Insert/Take out item"

func add_ingredient(item_tag):
	current_items[current_index] = item_tag
	board.add_ingredient_icon(item_tag, current_index)
	
	current_index += 1
	
	print("Current items:", current_items)
	

func start_brewing():
	if current_index < 5:
		print("Need all 5 ingredients!")
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
	
	return result
