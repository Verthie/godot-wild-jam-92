extends Resource
class_name MusicTrack

enum MusicType {
	CHASE,
	MONSTER_CLOSE_PROXIMITY,
	TAPE
}

@export var type: MusicType
@export var audio_stream: AudioStream
@export_range(-40, 20) var volume: int = 0
