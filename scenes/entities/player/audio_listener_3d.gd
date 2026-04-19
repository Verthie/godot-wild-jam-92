extends AudioListener3D


func _ready() -> void:
	# for pausing movement/oxygen etc when reading
	# making sure get_tree().paused does not pause this node along
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)
