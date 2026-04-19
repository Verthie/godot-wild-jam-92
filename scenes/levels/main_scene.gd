extends Node3D

@onready var launch_area: Area3D = $LaunchArea
@onready var ui: Interface = $UI
@onready var cutscene_manager: Node = $CutsceneManager
@onready var player: Player = $CharacterController

var allow_cure_placement: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if (Input.is_action_just_pressed("interact_left") or Input.is_action_just_pressed("interact_right")) and allow_cure_placement:
		var left_hand_ingredient = player.get_hand_item("left")
		var right_hand_ingredient = player.get_hand_item("right")
		if (left_hand_ingredient != null and left_hand_ingredient.tag == "cure") or (right_hand_ingredient != null and right_hand_ingredient.tag == "cure"):
			cutscene_manager.play_final_cutscene()

func _ready() -> void:
	player.canvas_layer.hide()
	TransitionNode.fade_out()
	launch_area.body_entered.connect(_on_launch_area_body_entered)
	launch_area.body_exited.connect(_on_launch_area_body_exited)


func _on_launch_area_body_entered(body: Node3D) -> void:
	if body is not Player:
		return
	ui.display_prompt("Place in the cure")
	allow_cure_placement = true

func _on_launch_area_body_exited(body: Node3D) -> void:
	if body is not Player:
		return
	ui.hide_prompt()
	allow_cure_placement = false
