extends Node3D

@onready var rows = [
	$"Wordle Row1",
	$"Wordle Row2",
	$"Wordle Row3",
	$"Wordle Row4",
	$"Wordle Row5"
]

var current_row := 0
var current_index := 0

func _ready() -> void:
	# display_result(["green", "green", "yellow", "yellow", "gray"])
	pass
	
	
func display_result(result: Array):
	var row = rows[current_row]
	var tiles = row.get_children()
	
	for i in range(result.size()):
		var color = Color.DIM_GRAY
		
		match result[i]:
			"green":
				color = Color.GREEN
			"yellow":
				color = Color.YELLOW
		
		tiles[i].flip_to_color(color)
		
		# print("Play flip sound")
		
		await get_tree().create_timer(0.4).timeout
	
	current_row += 1
	current_row = current_row % rows.size()
	# Not really needed, but if we enter our 6th guess
	# the result will be shown at the first row again, cycling it 


func add_ingredient_icon(tag: String, index: int):
	var row = rows[current_row]
	var tile = row.get_children()[index]
	
	tile.set_icon(tag)
	tile.appear()

func remove_last_icon(index: int):
	var row = rows[current_row]
	var tile = row.get_children()[index]
	
	tile.clear()

func set_tile_color(tile, color):
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	tile.material_override = mat
