extends Resource
class_name SoundEffect

enum SoundEffectType{
	DEATH,
	NEAR_PLAYER_1,
	NEAR_PLAYER_2,
	NEAR_PLAYER_3,
	NEAR_PLAYER_4,
	NEAR_PLAYER_5,
	MONSTER_APPEARS,
	SCREAM_1,
	SCREAM_2,
	SCREAM_3,
	SCREAM_4,
	SCREAM_5,
	SELECT,
	START,
	RETURN,
	SLIDER,
	HOVER,
	BREWERY_ACTIVATE_LONG,
	BREWERY_ACTIVATE,
	BREWERY_CORRECT,
	BREWERY_WRONG,
	INSERT_INGREDIENT,
	DOOR_OPEN,
	DOOR_CLOSE,
	JOURNAL_OPEN,
	JOURNAL_CLOSE,
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
