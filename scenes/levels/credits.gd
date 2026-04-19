extends Control

@onready var button: Button = $Button

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact") or \
	Input.is_action_just_pressed("interact_left") or \
	Input.is_action_just_pressed("interact_right"):
		get_tree().change_scene_to_file("res://scenes/levels/main_menu.tscn")
