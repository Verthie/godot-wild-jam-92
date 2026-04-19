extends Control

const GAME_SCENE: PackedScene = preload("res://scenes/levels/main_scene.tscn")
const CREDITS_SCENE: PackedScene = preload("res://scenes/levels/credits.tscn")

@onready var start: Button = %Start
@onready var credits: Button = %Credits
@onready var exit: Button = %Exit
@onready var transition

func _ready() -> void:
	start.pressed.connect(_on_start_button_pressed)
	credits.pressed.connect(_on_credits_button_pressed)
	exit.pressed.connect(_on_exit_button_pressed)

func _on_start_button_pressed() -> void:
	await TransitionNode.fade_in()
	get_tree().change_scene_to_packed(GAME_SCENE)

func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_packed(CREDITS_SCENE)

func _on_exit_button_pressed() -> void:
	get_tree().quit()
