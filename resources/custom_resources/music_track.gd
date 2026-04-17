extends Resource
class_name MusicTrack

enum MusicType {
	CHASE,
	MONSTER_CLOSE_PROXIMITY,
	TAPE,
	INTERIOR,
	INTRO,
	OUTRO
}

@export var type: MusicType
@export var audio_stream: AudioStream
@export var bpm: float = 120.0
@export var pitch_scale: float = 1.0
@export var beats_per_bar: int = 4
@export var loop_start_seconds: float = 0.0  # 0 = no intro, loop from start
@export_range(-40, 20) var volume: int = 0
@export var bus: StringName = &"Music"
