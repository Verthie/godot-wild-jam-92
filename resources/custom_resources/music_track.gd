extends Resource
class_name MusicTrack

enum MusicType {
	GAME
}

@export var type: MusicType
@export var audio_stream: AudioStream
@export_range(-40, 20) var volume: int = 0
