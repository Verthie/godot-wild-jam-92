extends Node

const MONSTER_SCENE = preload("res://scenes/entities/monster/monster_controller.tscn")

@export var ui: Interface
@export var player: Player
@export var cutscene_camera: Camera3D
@export var animation_player: AnimationPlayer
@export var oxygen_manager: Node
@export var tape_1: StaticBody3D
@export var exit_door: Node3D
@export var mist_seed: Node3D
@export var oxygen_maker: Node3D

@export var cutscene_area_exterior: Area3D
@export var cutscene_area_base: Area3D

@export var play_cutscenes: bool = true
@export var player_initial_location: Vector3 = Vector3(6.994, 2.384, 8.536)
@export var player_initial_rotation: Vector3 = Vector3(0, 38.2, 0)

var player_camera: Camera3D
var player_canvas: CanvasLayer
var monster: Monster = null
var in_cutscene: bool = false

# Jason:
var second_cutscene_done := false

func _ready() -> void:
	# add black screen for the blink
	await get_tree().process_frame

	player.set_movement_enabled(false)
	player.canvas_layer.hide()

	in_cutscene = true

	oxygen_manager.set_oxygen_display(false)
	oxygen_manager.disable_oxygen_deplete()

	cutscene_area_exterior.body_entered.connect(_on_first_cutscene_area_player_entered)
	cutscene_area_base.body_entered.connect(_on_second_cutscene_area_player_entered)

	player_camera = player.camera
	player_canvas = player.canvas_layer

	if !play_cutscenes:
		ui.fade_out_screen(2.0)
		player_camera.current = true
		cutscene_camera.current = false
		return

	player.global_position = player_initial_location
	player.rotation_degrees = player_initial_rotation
	cutscene_camera.show()

	_cutscene_setup()

	await _open_eyes()

	animation_player.play("wake_up_camurai")
	await animation_player.animation_finished

	player.canvas_layer.show()
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

# player triggers the cutscene near the base
func _on_first_cutscene_area_player_entered(_body: Node3D) -> void:
	monster = MONSTER_SCENE.instantiate()
	monster.chasing_distance = 50.0
	get_tree().current_scene.add_child(monster)
	monster.global_position = Vector3(-3.518, 0.0, 6.298)

	AudioManager.create_3d_audio_at_location(monster.global_position, SoundEffect.SoundEffectType.MONSTER_APPEARS)

	cutscene_area_exterior.set_deferred("monitoring", false)
	cutscene_area_exterior.queue_free()

	cutscene_camera.rotation = player.rotation
	cutscene_camera.global_position = player.global_position
	cutscene_camera.global_position.y += 0.194

	player.set_movement_enabled(false)

	_switch_camera()

	const ANIMATION_DURATION: float = 1

	var previous_transform: Transform3D = cutscene_camera.global_transform

	var target_transform: Transform3D = cutscene_camera.global_transform.looking_at(
		monster.global_transform.origin,
		Vector3.UP
	)

	await get_tree().create_timer(0.5).timeout
	turn_to_target(cutscene_camera, ANIMATION_DURATION, target_transform)
	await get_tree().create_timer(ANIMATION_DURATION * 2).timeout

	# monster starts glowing and runnning towards the player

	monster.chase_enabled = true
	monster.speed = 0.5

	ui.display_prompt("Hold Shift to sprint")

	await turn_to_target(cutscene_camera, 1, previous_transform)

	_switch_camera(false)
	player.set_movement_enabled(true)

	monster.speed = 0.7

	await get_tree().create_timer(1.0).timeout
	AudioManager.create_3d_audio_at_location(monster.global_position, SoundEffect.SoundEffectType.SCREAM_2)

	await get_tree().create_timer(4.0).timeout

	monster.speed = 1.3

	# if player is caught we spawn him at the beginning of the path


# player reached the base
func _on_second_cutscene_area_player_entered(_body: Node3D) -> void:
	exit_door.enabled = false
	exit_door.animation_player.play_backwards("Door_move")
	cutscene_area_base.set_deferred("monitoring", false)
	cutscene_area_base.queue_free()

	monster.speed = 0.9
	monster.chasing_distance = 4.0

	await get_tree().create_timer(0.5).timeout

	player.set_movement_enabled(false)
	ui.display_prompt("What was that?")

	await _wait_for_input(["interact", "interact_left", "interact_right"])
	ui.display_prompt("I managed to get away, but...")

	await _wait_for_input(["interact", "interact_left", "interact_right"])
	ui.display_prompt("the harsh atmosphere made me\nlose some oxygen")

	await _wait_for_input(["interact", "interact_left", "interact_right"])

	ui.hide_prompt()

	oxygen_manager.set_oxygen_display(true)
	oxygen_manager.enable_oxygen_deplete(82)
	oxygen_manager.pause_oxygen_deplete()

	ui.display_prompt("I should be able to\nreplenish it though")
	await _wait_for_input(["interact", "interact_left", "interact_right"])

	ui.display_prompt("But first I need to insert this\nmoon seed into the sampler")
	await _wait_for_input(["interact", "interact_left", "interact_right"])

	MusicManager.crossfade(MusicTrack.MusicType.CHASE, MusicTrack.MusicType.INTERIOR)

	oxygen_manager.pause_oxygen_deplete(false)

	player.set_movement_enabled(true)

	await EventBus.sampler_enabled

	player.set_movement_enabled(false)

	oxygen_manager.pause_oxygen_deplete()
	ui.display_prompt("Ok, now I need to take\nthese two ingredients on the counter")

	player.set_movement_enabled(true)

	await EventBus.taken_item

	oxygen_manager.pause_oxygen_deplete(false)
	player.set_movement_enabled(true)

	ui.display_prompt("I have to put them\nin the oxygen dispenser")

	await oxygen_maker.produced_oxygen

	await ui.timed_display_prompt("Uff, I bought myself some time", 3.0)

	player.set_movement_enabled(false)
	oxygen_manager.pause_oxygen_deplete()

	ui.display_prompt("I should quickly look for some\ninformation...anything that could help me")
	await _wait_for_input(["interact", "interact_left", "interact_right"])
	ui.display_prompt("Oxygen is scarce\nand time is running out...")
	await _wait_for_input(["interact", "interact_left", "interact_right"])

	oxygen_manager.pause_oxygen_deplete(false)
	player.set_movement_enabled(true)
	ui.hide_prompt()
	exit_door.enabled = true

	# Jason:
	second_cutscene_done = true


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

func turn_to_target(camera: Camera3D, duration: float, target_transform) -> void:
	var tween = create_tween()
	tween.tween_property(
		camera,
		"global_transform",
		target_transform,
		duration
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	await tween.finished


func _open_eyes() -> void:
	await ui.fade_out_screen(2.0)
	await get_tree().create_timer(2.0).timeout
	await ui.fade_in_screen(0.5)
	await ui.fade_out_screen(2.5)


func _cutscene_setup() -> void:
	player_canvas.hide()

	_switch_camera()

func _cutscene_end() -> void:
	player_canvas.show()

	_switch_camera(false)

func _switch_camera(to_cutscene_camera: bool = true) -> void:
	player.can_move_camera = !to_cutscene_camera
	player.camera.current = !to_cutscene_camera
	cutscene_camera.current = to_cutscene_camera


func _wait_for_input(actions: Array[StringName]) -> StringName:
	while true:
		for action in actions:
			if Input.is_action_just_pressed(action):
				await get_tree().process_frame
				return action
		await get_tree().process_frame
	return ""
