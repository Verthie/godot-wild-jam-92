extends Node

@export var monster: Monster
@export var player: Player
@export var exterior_area: Area3D
@export var interior_area: Area3D
@export var exterior_music_on: bool = false

@export_range(0.0, 0.1) var max_jitter_value: float = 0.05
@export_range(0.0, 0.1) var max_chrome_abberation: float = 0.1
@export_range(0.0, 2) var min_pitch_scale: float = 0.20
@export_range(0.0, 2) var max_pitch_scale: float = 1.0

@onready var phase_one_timer: Timer = $PhaseOneTimer
@onready var phase_two_timer: Timer = $PhaseTwoTimer

var phase_one_sounds: Array[SoundEffect.SoundEffectType] = [SoundEffect.SoundEffectType.NEAR_PLAYER_1, SoundEffect.SoundEffectType.NEAR_PLAYER_2, SoundEffect.SoundEffectType.NEAR_PLAYER_3, SoundEffect.SoundEffectType.NEAR_PLAYER_4, SoundEffect.SoundEffectType.NEAR_PLAYER_5]

var phase_two_sounds: Array[SoundEffect.SoundEffectType] = [SoundEffect.SoundEffectType.SCREAM_1, SoundEffect.SoundEffectType.SCREAM_2, SoundEffect.SoundEffectType.SCREAM_3, SoundEffect.SoundEffectType.SCREAM_4, SoundEffect.SoundEffectType.SCREAM_5, ]

var monster_distance_to_player: float = 1000.0
var monster_has_been_active: bool = false
var current_phase: int = 1
var scream_combo: int = 0
var chase_just_finished: bool = false

var psx_material

var last_random_sound: SoundEffect.SoundEffectType
var music_player: AudioStreamPlayer

var normal_volume_db: float = 0.0

var transition_tween: Tween = null
var phase_one_active: bool = false


func _ready() -> void:
	monster.entered_phase.connect(_on_monster_entered_phase)
	phase_one_timer.timeout.connect(_on_phase_one_timer_timeout)
	phase_two_timer.timeout.connect(_on_phase_two_timer_timeout)
	interior_area.body_entered.connect(_on_interior_area_body_entered)
	exterior_area.body_entered.connect(_on_exterior_area_body_entered)
	music_player = MusicManager.current_player
	normal_volume_db = music_player.volume_db

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


func _on_monster_entered_phase(phase_number: int) -> void:
	match phase_number:
		1:
			current_phase = 1
			scream_combo = 0
			if !phase_two_timer.is_stopped():
				phase_two_timer.stop()

			phase_one_timer.wait_time = 1
			phase_one_timer.start()

			if !monster_has_been_active:
				return

			# Don't restart if the dip-and-recover is already running
			if phase_one_active:
				return

			phase_one_active = true
			monster_has_been_active = false
			chase_just_finished = true

			if transition_tween:
				transition_tween.kill()
				transition_tween = null

			MusicManager.stop_music(1, 3.0)

			if !phase_one_timer.is_stopped():
				phase_two_timer.stop()

			var ending_sound_array: Array[SoundEffect.SoundEffectType] = [phase_one_sounds[2], phase_one_sounds[4], SoundEffect.SoundEffectType.MONSTER_APPEARS]
			var random_ending_sound = (randi() % 3)
			AudioManager.create_3d_audio_at_location(monster.global_position, ending_sound_array[random_ending_sound])

			transition_tween = create_tween().set_parallel()
			transition_tween.tween_property(music_player, "volume_db", normal_volume_db - 30.0, 4.0)
			transition_tween.tween_property(music_player, "pitch_scale", min_pitch_scale, 3.0)

			await transition_tween.finished

			# If the player walked near the monster during the dip, abort the recovery
			if current_phase == 2:
				phase_one_active = false
				return

			await get_tree().create_timer(1.5).timeout

			# Check again after the pause
			if current_phase == 2:
				phase_one_active = false
				return

			transition_tween = create_tween()
			transition_tween.tween_property(music_player, "volume_db", normal_volume_db, 3.0)

			await transition_tween.finished

			phase_one_active = false
		2:
			current_phase = 2
			# Entering chase — immediately abort any ongoing phase zero dip/recover
			if phase_one_active:
				phase_one_active = false
				if transition_tween:
					transition_tween.kill()
					transition_tween = null
				# Snap pitch back toward normal so the chase ramp starts from a sane value
				music_player.volume_db = normal_volume_db

			if !phase_one_timer.is_stopped():
				phase_one_timer.stop()

			if monster_has_been_active:
				return

			monster_has_been_active = true

			MusicManager.play_music(MusicTrack.MusicType.MONSTER_CLOSE_PROXIMITY, 1)

			AudioManager.create_3d_audio_at_location(monster.global_position, SoundEffect.SoundEffectType.MONSTER_APPEARS)
			var pitch_scale_value = clamp(music_player.pitch_scale + 0.60, min_pitch_scale, max_pitch_scale)
			var tween = create_tween()
			tween.tween_property(music_player, "pitch_scale", pitch_scale_value, 2.0)

			phase_two_timer.wait_time = 1
			phase_two_timer.start()
		3:
			pass
		_:
			current_phase = 1
			scream_combo = 0

			if !phase_one_timer.is_stopped():
				phase_one_timer.stop()


func _on_phase_one_timer_timeout() -> void:
	if monster_distance_to_player > 4 and monster_distance_to_player < 7:
		produce_random_sound(phase_one_timer, phase_one_sounds)

func _on_phase_two_timer_timeout() -> void:
	if chase_just_finished:
		chase_just_finished = false
		phase_two_timer.stop()
		return
	if monster_distance_to_player < 4:
		produce_random_sound(phase_two_timer, phase_two_sounds)
		if monster_distance_to_player < 2.25:
			var tween = create_tween()
			tween.tween_property(music_player, "pitch_scale", max_pitch_scale, 1.0)
		else:
			var pitch_scale_value = clamp(music_player.pitch_scale + 0.30, min_pitch_scale, max_pitch_scale)
			var tween = create_tween()
			tween.tween_property(music_player, "pitch_scale", pitch_scale_value, 1.0)

func _on_interior_area_body_entered(body: Node3D) -> void:
	if body is not Player:
		return

func _on_exterior_area_body_entered(body: Node3D) -> void:
	if body is not Player:
		return

	# if exterior_music_on:
		# MusicManager.pla
	else:
		MusicManager.play_music(MusicTrack.MusicType.CHASE)
