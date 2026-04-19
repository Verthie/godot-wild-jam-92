extends Node

const MONSTER_SCENE = preload("res://scenes/entities/monster/monster_controller.tscn")

@export var ui: Interface
@export var player: Player
@export var cutscene_camera: Camera3D
@export var animation_player: AnimationPlayer
@export var oxygen_manager: Node
@export var tape_1: StaticBody3D

@export var cutscene_area: Area3D

@export var play_cutscenes: bool = true
@export var player_initial_location: Vector3 = Vector3(6.998, 2.577, 8.535)
@export var player_initial_rotation: Vector3 = Vector3(0, 75.9, 0)

var player_camera: Camera3D
var player_canvas: CanvasLayer
var monster: Monster = null

func _ready() -> void:
	# add black screen for the blink
	await get_tree().process_frame

	cutscene_area.body_entered.connect(_on_first_cutscene_area_player_entered)

	player_camera = player.camera
	player_canvas = player.canvas_layer

	if !play_cutscenes:
		ui.fade_out_screen(2.0)
		player_camera.current = true
		cutscene_camera.current = false
		return

	player.global_position = player_initial_location
	player.rotation_degrees = player_initial_rotation

	_cutscene_setup()

	await ui.fade_out_screen(2.0)
	await get_tree().create_timer(2.0).timeout
	await ui.fade_in_screen(0.5)
	await ui.fade_out_screen(2.5)

	_open_eyes()

	animation_player.play("wake_up_camurai")
	await animation_player.animation_finished

	await get_tree().create_timer(0.2).timeout

	ui.display_prompt("Press LMB to pick up the tape")

	var player_input = await _wait_for_input(["interact_left"])

	print("playing pick_up_animation: ", player_input)

	animation_player.play("pick_up_camera")
	await animation_player.animation_finished

	ui.display_prompt("Press E to play the tape")
	await _wait_for_input(["interact"])

	ui.hide_prompt()

	tape_1.fyi_ui_should_never_be_tied_to_the_player_there_is_no_way_to_call_it_from_other_nodes_and_i_need_to_use_this_hacky_solution(player)

	await player.finished_reading

	tape_1.queue_free()

	animation_player.play("go_back_to_default")
	await animation_player.animation_finished	

	_cutscene_end()

	oxygen_manager.enable_oxygen_deplete()

# player triggers the cutscene near the base
func _on_first_cutscene_area_player_entered(_body: Node3D) -> void:
	print("FUCK")

	# monster needs to be far but its speed should be fast so that the player can't outrun him with sprint and doesn't break the sequence if they don't go to the base
	# so we need to temporarily modify it's speed, and chase distance
	monster = MONSTER_SCENE.instantiate()
	monster.chasing_distance = 50.0
	get_tree().current_scene.add_child(monster)

	monster.global_position = Vector3(-3.518, 0.0, 6.298) # spawn_point

	AudioManager.create_3d_audio_at_location(monster.global_position, SoundEffect.SoundEffectType.MONSTER_APPEARS)

	# turns camera behind him
	# animation_player.play(turn_behind)

	# await get_tree().create_timer(HALF_LENGTH_OF_THE_ANIMATION).timeout

	# in the middle of animation starts chasing
	# monster starts glowing and runnning towards the player
	monster.chase_enabled = true

	# player quickly turns back
	# animation_player.play(turn_back)
	# await animation_player.animation_finished

	# display prompt on sprinting
	ui.display_prompt("Hold Shift to sprint")

	# after a second force play a monster scream
	await get_tree().create_timer(1.0).timeout
	AudioManager.create_3d_audio_at_location(monster.global_position, SoundEffect.SoundEffectType.SCREAM_2)

	# if player is caught we spawn him at the beginning of the path



# player reached the base
func _on_second_cutscene_area_player_entered() -> void:
	ui.hide_prompt()
	# enable base lockdown
	pass


func apply_blur() -> void:
	# var tween = create_tween()
	# tween.tween_property(cutscene_camera, "compositor.compositor_effects[0].alpha", 0.95, 1.0)
	cutscene_camera.compositor.compositor_effects[0].enabled = true
	cutscene_camera.compositor.compositor_effects[0].alpha = 0.95

func remove_blur() -> void:
	# var tween = create_tween()
	# tween.tween_property(cutscene_camera, "compositor.compositor_effects[0].alpha", 0, 1.0)
	cutscene_camera.compositor.compositor_effects[0].enabled = false
	cutscene_camera.compositor.compositor_effects[0].alpha = 0


func _open_eyes() -> void:
	pass

func _cutscene_setup() -> void:
	ui.oxygen_bar.hide()
	player_canvas.hide()

	player.can_move_camera = false
	player.camera.current = false
	cutscene_camera.current = true

func _cutscene_end() -> void:
	ui.oxygen_bar.show()
	player_canvas.show()

	player.can_move_camera = true
	player.camera.current = true
	cutscene_camera.current = false

func _wait_for_input(actions: Array[StringName]) -> StringName:
	while true:
		for action in actions:
			if Input.is_action_just_pressed(action):
				await get_tree().process_frame
				return action
		await get_tree().process_frame
	return ""
