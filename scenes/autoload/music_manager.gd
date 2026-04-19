extends Node

@export var tracks: Array[MusicTrack] = []
@export var music_bus_name: StringName = &"Music"
@export var lowpass_effect_index: int = 0

class ManagedPlayer:
	var player: AudioStreamPlayer
	var track: MusicTrack
	var target_volume_db: float = 0.0
	var active_tween: Tween = null

	func _init(parent: Node, t: MusicTrack) -> void:
		track = t
		target_volume_db = t.volume
		player = AudioStreamPlayer.new()
		player.bus = t.bus
		player.volume_db = -80.0
		parent.add_child(player)

	func cleanup() -> void:
		if active_tween:
			active_tween.kill()
			active_tween = null
		player.queue_free()


var _active: Dictionary[MusicTrack.MusicType, ManagedPlayer] = {}
var _catalogue: Dictionary[MusicTrack.MusicType, MusicTrack] = {}

var _pre_duck_volume_db: float = 0.0
var _is_ducked: bool = false
var _duck_tween: Tween = null

var _lowpass_tween: Tween = null

func _ready() -> void:
	# Build catalogues
	for track in tracks:
		_catalogue[track.type] = track
	
	# Jason: for pausing movement/oxygen etc when reading
	# making sure get_tree().paused does not pause this node along
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)

func play_music(type: MusicTrack.MusicType, fade_in_time: float = 1.0) -> void:
	if _active.has(type):
		return  # already playing — do nothing

	var track: MusicTrack = _catalogue.get(type)
	if track == null:
		push_warning("MusicManager: no MusicTrack registered for type %d" % type)
		return

	var mp: ManagedPlayer = ManagedPlayer.new(self, track)
	_active[type] = mp

	mp.player.stream = track.audio_stream
	mp.player.pitch_scale = track.pitch_scale
	mp.player.play()
	mp.player.finished.connect(_on_player_finished.bind(type))

	_fade_player_to(mp, track.volume, fade_in_time)

func crossfade(from_type: MusicTrack.MusicType, to_type: MusicTrack.MusicType, duration: float = 2.0) -> void:
	if _active.has(from_type):
		stop_music(from_type, duration)

	var mp: ManagedPlayer

	if _active.has(to_type):
		mp = _active[to_type]
		_fade_player_to(mp, mp.track.volume, duration)
		return

	var track: MusicTrack = _catalogue.get(to_type)
	if track == null:
		push_warning("MusicManager: no MusicTrack registered for type %d" % to_type)
		return

	mp = ManagedPlayer.new(self, track)
	_active[to_type] = mp
	mp.player.stream = track.audio_stream
	mp.player.volume_db = -80.0
	mp.player.play()
	mp.player.finished.connect(_on_player_finished.bind(to_type))

	_fade_player_to(mp, track.volume, duration)

func stop_music(type: MusicTrack.MusicType, fade_out_time: float = 1.0) -> void:
	if not _active.has(type):
		return

	var mp: ManagedPlayer = _active[type]
	_active.erase(type)

	_fade_player_to(mp, -80.0, fade_out_time, true)


func stop_all(fade_out_time: float = 1.0) -> void:
	for type in _active.keys():
		stop_music(type, fade_out_time)

func set_lowpass_cutoff(target_hz: float, duration: float) -> void:
	var effect: AudioEffectLowPassFilter = _get_lowpass_effect()
	if effect == null:
		return

	if _lowpass_tween:
		_lowpass_tween.kill()

	_lowpass_tween = create_tween()
	_lowpass_tween.tween_method(
		func(hz: float) -> void: effect.cutoff_hz = hz,
		effect.cutoff_hz,
		clamp(target_hz, 20.0, 20000.0),
		duration
	)

func clear_lowpass(duration: float) -> void:
	set_lowpass_cutoff(20000.0, duration)

func duck(amount_db: float, duration: float) -> Tween:
	if _duck_tween:
		_duck_tween.kill()

	var bus_idx: int = AudioServer.get_bus_index(music_bus_name)

	if not _is_ducked:
		_pre_duck_volume_db = AudioServer.get_bus_volume_db(bus_idx)
		_is_ducked = true

	var current_db: float = AudioServer.get_bus_volume_db(bus_idx)
	var target_db: float = _pre_duck_volume_db + amount_db

	_duck_tween = create_tween()
	_duck_tween.tween_method(
		func(db: float) -> void: AudioServer.set_bus_volume_db(bus_idx, db),
		current_db,
		target_db,
		duration
	)
	return _duck_tween

func unduck(duration: float) -> void:
	if not _is_ducked:
		return
	if _duck_tween:
		_duck_tween.kill()

	var bus_idx: int = AudioServer.get_bus_index(music_bus_name)
	var current_db: float = AudioServer.get_bus_volume_db(bus_idx)

	_duck_tween = create_tween()
	_duck_tween.tween_method(
		func(db: float) -> void: AudioServer.set_bus_volume_db(bus_idx, db),
		current_db,
		_pre_duck_volume_db,
		duration
	)
	await _duck_tween.finished
	_is_ducked = false


func tween_track_volume(type: MusicTrack.MusicType, target_db: float, duration: float) -> Tween:
	var mp: ManagedPlayer = _active.get(type)
	if mp == null:
		return null
	mp.target_volume_db = target_db
	return _fade_player_to(mp, target_db, duration)

func tween_track_pitch(type: MusicTrack.MusicType, target_pitch: float, duration: float) -> Tween:
	var mp: ManagedPlayer = _active.get(type)
	if mp == null:
		return
	if mp.active_tween:
		mp.active_tween.kill()
	mp.active_tween = create_tween()
	mp.active_tween.tween_property(mp.player, "pitch_scale", target_pitch, duration)
	return mp.active_tween

func get_track_pitch(type: MusicTrack.MusicType) -> float:
	var mp: ManagedPlayer = _active.get(type)
	return mp.player.pitch_scale if mp else 1.0

func is_playing(type: MusicTrack.MusicType) -> bool:
	return _active.has(type)

func _fade_player_to(
	mp: ManagedPlayer,
	target_db: float,
	duration: float,
	cleanup: bool = false) -> Tween:

	if mp.active_tween:
		mp.active_tween.kill()

	var t: Tween = create_tween()
	mp.active_tween = t
	t.tween_property(mp.player, "volume_db", target_db, duration)

	if cleanup:
		t.tween_callback(mp.cleanup)

	return t

func _get_any_playback_position() -> float:
	for mp in _active.values():
		if mp.player.playing:
			return mp.player.get_playback_position()
	return 0.0

func _get_lowpass_effect() -> AudioEffectLowPassFilter:
	var bus_idx: int = AudioServer.get_bus_index(music_bus_name)
	if bus_idx < 0:
		push_warning("MusicManager: bus '%s' not found" % music_bus_name)
		return null

	var effect: AudioEffect = AudioServer.get_bus_effect(bus_idx, lowpass_effect_index)
	if effect == null or not (effect is AudioEffectLowPassFilter):
		push_warning("MusicManager: effect at index %d on bus '%s' is not an AudioEffectLowPassFilter" % [lowpass_effect_index, music_bus_name])
		return null

	return effect as AudioEffectLowPassFilter

func _on_player_finished(type: MusicTrack.MusicType) -> void:
	var mp: ManagedPlayer = _active.get(type)
	if mp == null:
		return  # was stopped and cleaned up before the signal fired

	var loop_start: float = mp.track.loop_start_seconds

	if loop_start > 0.0:
		mp.player.play(loop_start)
	else:
		mp.player.play()
