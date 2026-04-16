extends Node3D

var sound_effect_dict: Dictionary = {}

@export var sound_effects: Array[SoundEffect] ## Stores all possible SoundEffects that can be played.

func _ready() -> void:
	for sound_effect: SoundEffect in sound_effects:
		# print("Registering:", sound_effect.type)
		sound_effect_dict[sound_effect.type] = sound_effect

func create_3d_audio_at_location(location: Vector3, type: SoundEffect.SoundEffectType) -> void:
	if sound_effect_dict.has(type):
		var sound_effect_setting: SoundEffect = sound_effect_dict[type]
		if sound_effect_setting.has_open_limit():
			sound_effect_setting.change_audio_count(1)
			var new_3d_audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
			add_child(new_3d_audio)

			new_3d_audio.position = location
			new_3d_audio.bus = "Sfx"
			new_3d_audio.stream = sound_effect_setting.sound_effect
			new_3d_audio.volume_db = sound_effect_setting.volume
			new_3d_audio.pitch_scale = sound_effect_setting.pitch_scale
			new_3d_audio.pitch_scale += randf_range(-sound_effect_setting.pitch_randomness, sound_effect_setting.pitch_randomness)
			new_3d_audio.max_distance = sound_effect_setting.max_distance
			new_3d_audio.finished.connect(sound_effect_setting.on_audio_finished)
			new_3d_audio.finished.connect(new_3d_audio.queue_free)

			new_3d_audio.play()
	else:
		push_error("Audio Manager failed to find setting for type ", type)

func create_audio(type: SoundEffect.SoundEffectType) -> void:
	if sound_effect_dict.has(type):
		var sound_effect_setting: SoundEffect = sound_effect_dict[type]
		if sound_effect_setting.has_open_limit():
			sound_effect_setting.change_audio_count(1)
			var new_audio: AudioStreamPlayer = AudioStreamPlayer.new()
			add_child(new_audio)

			new_audio.bus = "Sfx"
			new_audio.stream = sound_effect_setting.sound_effect
			new_audio.volume_db = sound_effect_setting.volume
			new_audio.pitch_scale = sound_effect_setting.pitch_scale
			new_audio.pitch_scale += randf_range(-sound_effect_setting.pitch_randomness, sound_effect_setting.pitch_randomness)
			new_audio.finished.connect(sound_effect_setting.on_audio_finished)
			new_audio.finished.connect(new_audio.queue_free)

			new_audio.play()
	else:
		push_error("Audio Manager failed to find setting for type ", type)
