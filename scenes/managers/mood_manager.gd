extends Node

@export var player: Player
@export var exterior_area: Area3D
@export var interior_area: Area3D

@export var cutscene_area: Area3D

@export_range(0.0, 0.1) var max_jitter_value: float = 0.05
@export_range(0.0, 0.1) var max_chrome_abberation: float = 0.1
@export_range(0.0, 2) var min_pitch_scale: float = 0.20
@export_range(0.0, 2) var max_pitch_scale: float = 1.0

@onready var phase_one_timer: Timer = $PhaseOneTimer
@onready var phase_two_timer: Timer = $PhaseTwoTimer

const PLAYER_NUM_COMPANION := 1  # MusicManager slot used by monster

var phase_one_sounds: Array[SoundEffect.SoundEffectType] = [SoundEffect.SoundEffectType.NEAR_PLAYER_1, SoundEffect.SoundEffectType.NEAR_PLAYER_2, SoundEffect.SoundEffectType.NEAR_PLAYER_3, SoundEffect.SoundEffectType.NEAR_PLAYER_4, SoundEffect.SoundEffectType.NEAR_PLAYER_5]

var phase_two_sounds: Array[SoundEffect.SoundEffectType] = [SoundEffect.SoundEffectType.SCREAM_1, SoundEffect.SoundEffectType.SCREAM_2, SoundEffect.SoundEffectType.SCREAM_3, SoundEffect.SoundEffectType.SCREAM_4, SoundEffect.SoundEffectType.SCREAM_5, ]

var ending_sounds: Array[SoundEffect.SoundEffectType] = [
	SoundEffect.SoundEffectType.NEAR_PLAYER_3,
	SoundEffect.SoundEffectType.NEAR_PLAYER_5,
	SoundEffect.SoundEffectType.MONSTER_APPEARS,
]

var monster_distance_to_player: float = 1000.0
var monster_has_been_active: bool = false
var current_phase: int = 1
var scream_combo: int = 0
var chase_just_finished: bool = false

var psx_material

var last_random_sound: SoundEffect.SoundEffectType
var normal_volume_db: float = 0.0

var phase_one_active: bool = false
var dip_tween: Tween = null

var monster: Monster

func _ready() -> void:
	cutscene_area.body_entered.connect(_on_first_cutscene_area_player_entered)
	phase_one_timer.timeout.connect(_on_phase_one_timer_timeout)
	phase_two_timer.timeout.connect(_on_phase_two_timer_timeout)
	interior_area.body_entered.connect(_on_interior_area_body_entered)
	exterior_area.body_entered.connect(_on_exterior_area_body_entered)

func _process(_delta) -> void:
	if player == null or monster == null:
		return

	monster_distance_to_player = monster.global_position.distance_to(player.global_position)

	# print(monster_distance_to_player)

	var chase_distance_percantage: float = clamp(1 - ((monster_distance_to_player - 0.8) / 3.2), 0, 1)

	# changing jitter based on distance
	# start value - 0.001, end value - 0.05
	var jitter_value = clamp((chase_distance_percantage * max_jitter_value), 0.001, max_jitter_value)

	# changing chrome abberation based on distance
	# start value - 0, end value - 0.1
	var chrome_abberation_value = clamp((chase_distance_percantage * max_chrome_abberation), 0, max_chrome_abberation)

	player.psx.material.set_shader_parameter("jitter_amount", jitter_value)
	player.psx.material.set_shader_parameter("chromatic_aberration_strength", chrome_abberation_value)


func produce_random_sound(timer: Timer, sounds: Array[SoundEffect.SoundEffectType]) -> void:
	var random_interval = (randi() % 3 + 1) * 3 # 3, 6, 9
	timer.wait_time = random_interval

	if chase_just_finished:
		chase_just_finished = false
		return

	scream_combo += 1

	var random_sound: SoundEffect.SoundEffectType = sounds.pick_random()

	while random_sound == last_random_sound:
		random_sound = sounds.pick_random()

	AudioManager.create_3d_audio_at_location(monster.global_position, random_sound)
	last_random_sound = random_sound

	timer.start()

func _on_first_cutscene_area_player_entered(_body: Node3D) -> void:
	await get_tree().process_frame
	monster = get_tree().get_first_node_in_group("monster")

func _on_monster_entered_phase(phase_number: int) -> void:
	match phase_number:
		1:
			_enter_phase_one()
		2:
			_enter_phase_two()
		3:
			pass
		_:
			_reset()


func _enter_phase_one() -> void:
	current_phase = 1
	scream_combo = 0

	phase_two_timer.stop()
	phase_one_timer.wait_time = 1
	phase_one_timer.start()

	if !monster_has_been_active:
		return
	if phase_one_active: # Don't restart if the dip-and-recover is already running
		return

	phase_one_active = true
	monster_has_been_active = false
	chase_just_finished = true

	MusicManager.stop_music(MusicTrack.MusicType.MONSTER_CLOSE_PROXIMITY, 3.0)

	if !phase_one_timer.is_stopped():
		phase_two_timer.stop()

	AudioManager.create_3d_audio_at_location(monster.global_position, ending_sounds.pick_random())

	dip_tween = MusicManager.duck(-30.0, 4.0)
	MusicManager.tween_track_pitch(MusicTrack.MusicType.CHASE, min_pitch_scale, 3.0)
	await dip_tween.finished
	dip_tween = null
	# MusicManager.duck(-30.0, 4.0)
	# MusicManager.tween_track_pitch(MusicTrack.MusicType.CHASE, min_pitch_scale, 3.0)

	# await get_tree().create_timer(4.0).timeout

	# If the player walked near the monster during the dip, abort the recovery
	if current_phase == 2:
		phase_one_active = false
		return

	await get_tree().create_timer(1.5).timeout

	# Check again after the pause
	if current_phase == 2:
		phase_one_active = false
		return

	MusicManager.unduck(3.0)

	phase_one_active = false

func _enter_phase_two() -> void:
	current_phase = 2
	# Entering chase — immediately abort any ongoing phase zero dip/recover
	if phase_one_active:
		if dip_tween and dip_tween.is_valid():
			dip_tween.kill()
			dip_tween = null
		MusicManager.unduck(0.5)
		phase_one_active = false

	phase_one_timer.stop()

	if monster_has_been_active:
		return

	monster_has_been_active = true
	chase_just_finished = false

	MusicManager.play_music(MusicTrack.MusicType.MONSTER_CLOSE_PROXIMITY, 0.5)
	AudioManager.create_3d_audio_at_location(monster.global_position, SoundEffect.SoundEffectType.MONSTER_APPEARS)

	var new_pitch: float = clamp(
		MusicManager.get_track_pitch(MusicTrack.MusicType.CHASE) + 0.60,
		min_pitch_scale,
		max_pitch_scale
	)
	MusicManager.tween_track_pitch(MusicTrack.MusicType.CHASE, new_pitch, 2.0)

	phase_two_timer.wait_time = 1
	phase_two_timer.start()

func _reset() -> void:
	current_phase = 1
	scream_combo = 0
	phase_one_timer.stop()
	phase_two_timer.stop()


func _on_phase_one_timer_timeout() -> void:
	if monster_distance_to_player > 4 and monster_distance_to_player < 7:
		produce_random_sound(phase_one_timer, phase_one_sounds)

func _on_phase_two_timer_timeout() -> void:
	if chase_just_finished:
		chase_just_finished = false
		return
	if monster_distance_to_player < 4:
		produce_random_sound(phase_two_timer, phase_two_sounds)

		var new_pitch: float
		if monster_distance_to_player < 2.25:
			new_pitch = max_pitch_scale
		else:
			new_pitch = clamp(
				MusicManager.get_track_pitch(MusicTrack.MusicType.CHASE) + 0.30,
				min_pitch_scale,
				max_pitch_scale
			)

		MusicManager.tween_track_pitch(MusicTrack.MusicType.CHASE, new_pitch, 1.0)

func _on_interior_area_body_entered(body: Node3D) -> void:
	if body is not Player:
		return

	# TODO ADD THE CROSSFADE TO INTERIOR THEME

	MusicManager.set_lowpass_cutoff(800.0, 1.0)

func _on_exterior_area_body_entered(body: Node3D) -> void:
	if body is not Player:
		return

	MusicManager.clear_lowpass(1.0)

	# TODO CHANGE TO CROSSFADE ONCE THE MUSIC IS ADDED AT BEGINNING OF THE LEVEL
	MusicManager.play_music(MusicTrack.MusicType.CHASE)
