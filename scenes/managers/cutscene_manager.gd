extends Node

@export var ui: CanvasLayer
@export var player: Player
@export var monster: Monster
@export var cutscene_camera: Camera3D
@export var animation_player: AnimationPlayer

@export var play_cutscenes: bool = true
@export var player_initial_location: Vector3 = Vector3(6.997, 2.382, 8.535)
@export var player_initial_rotation: Vector3 = Vector3(0, 75.9, 0)

var player_camera: Camera3D
var player_canvas: CanvasLayer

func _ready() -> void:
	# add black screen for the blink

	await get_tree().process_frame

	player_camera = player.camera
	player_canvas = player.canvas_layer

	if !play_cutscenes:
		player_camera.current = true
		cutscene_camera.current = false
		return

	_cutscene_setup()

	_open_eyes()

	animation_player.play("wake_up_camurai")
	await animation_player.animation_finished

	await get_tree().create_timer(0.2).timeout

	_cutscene_end()

func apply_blur() -> void:
	# var tween = create_tween()
	# tween.tween_property(cutscene_camera, "compositor.compositor_effects[0].alpha", 0.95, 1.0)
	cutscene_camera.compositor.compositor_effects[0].alpha = 0.95

func remove_blur() -> void:
	# var tween = create_tween()
	# tween.tween_property(cutscene_camera, "compositor.compositor_effects[0].alpha", 0, 1.0)
	cutscene_camera.compositor.compositor_effects[0].alpha = 0


func _open_eyes() -> void:
	pass

func _cutscene_setup() -> void:
	ui.hide()
	player_canvas.hide()

	player.camera.current = false
	cutscene_camera.current = true

func _cutscene_end() -> void:
	ui.show()
	player_canvas.show()

	player.camera.current = true
	cutscene_camera.current = false
