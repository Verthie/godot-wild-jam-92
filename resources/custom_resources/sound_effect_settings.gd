extends Resource
class_name SoundEffect

# TODO Add sound effects
enum SoundEffectType{
	DOOR = 0,
	MONSTER_GROWL = 1
}

@export_range(0, 10) var limit: int = 5
@export var type: SoundEffectType
@export var sound_effect: AudioStream
@export_range(-40, 20) var volume: int = 0
@export_range(0.0, 4.0, .01) var pitch_scale: float = 1.0
@export_range(0.0, 1.0, .01) var pitch_randomness: float = 0.0
## Maximum distance from which audio is still hearable.
@export var max_distance: float = 2000.0

var audio_count: int = 0

func change_audio_count(amount: int) -> void:
	audio_count = max(0, audio_count + amount)

func has_open_limit() -> bool:
	return audio_count < limit

func on_audio_finished() -> void:
	change_audio_count(-1)
