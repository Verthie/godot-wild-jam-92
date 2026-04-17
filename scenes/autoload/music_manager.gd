extends Node

signal finished_playing

@export var music_tracks: Array[MusicTrack] ## All available music tracks

@onready var current_player: AudioStreamPlayer = $CurrentPlayer
@onready var fading_player: AudioStreamPlayer = $FadingPlayer
@onready var companion_player: AudioStreamPlayer = $CompanionPlayer
@onready var companion_fading_player: AudioStreamPlayer = $CompanionFadingPlayer

var music_dict: Dictionary = {}
var chosen_player: AudioStreamPlayer
var chosen_fading_player: AudioStreamPlayer

func _ready() -> void:
	current_player.bus = "Music"
	fading_player.bus = "Music"
	companion_player.bus = "Music"

	# Build dictionary
	for track: MusicTrack in music_tracks:
		music_dict[track.type] = track

func _process(_delta) -> void:
	if not current_player.playing:
		finished_playing.emit()

func play_music(type: MusicTrack.MusicType, player_num: int = 0, fade_duration: float = 1.0, fade_in: bool = true) -> void:
	if not music_dict.has(type):
		push_error("MusicManager: Track not found for type ", type)
		return

	var track: MusicTrack = music_dict[type]

	if player_num == 0:
		chosen_player = current_player
		chosen_fading_player = fading_player
	else:
		chosen_player = companion_player
		chosen_fading_player = companion_fading_player

	# If same track is playing, do nothing
	# if chosen_player.stream == track.audio_stream and chosen_player.playing:
		# return

	# Crossfade if music is already playing
	if chosen_player.playing:
		_crossfade_to(chosen_player, chosen_fading_player, track, fade_duration)
	else:
		if fade_in:
			_play_track_with_fade_in(chosen_player, track, fade_duration)
		else:
			_play_track(chosen_player, track)

func _crossfade_to(player: AudioStreamPlayer, player_fader: AudioStreamPlayer,  new_track: MusicTrack, duration: float) -> void:
	# Swap players
	var temp = player
	player = player_fader
	player_fader = temp

	# Start new track
	_play_track(player, new_track)
	player.volume_db = -80

	# Create fade tween
	var tween = create_tween().set_parallel(true)
	tween.tween_property(player, "volume_db", new_track.volume, duration)
	tween.tween_property(player_fader, "volume_db", -80, duration)
	tween.chain().tween_callback(player_fader.stop)

func _play_track(player: AudioStreamPlayer, track: MusicTrack) -> void:
	player.stream = track.audio_stream
	player.volume_db = track.volume
	player.play()

func _play_track_with_fade_in(player: AudioStreamPlayer, track: MusicTrack, fade_duration: float) -> void:
	player.stream = track.audio_stream
	player.volume_db = -80
	player.play()
	var tween = create_tween()
	tween.tween_property(player, "volume_db", track.volume, fade_duration)

func stop_music(player_num: int = 0, fade_duration: float = 1.0) -> void:
	if player_num == 0:
		chosen_player = current_player
	else:
		chosen_player = companion_player

	if not chosen_player.playing:
		return

	if fade_duration > 0:
		var tween = create_tween()
		tween.tween_property(chosen_player, "volume_db", -80, fade_duration)
		tween.tween_callback(chosen_player.stop)
	else:
		chosen_player.stop()

func set_music_volume(volume_db: float, player_num: int = 0) -> void:
	if player_num == 0:
		chosen_player = current_player
	else:
		chosen_player = companion_player

	if chosen_player.playing:
		chosen_player.volume_db = volume_db
