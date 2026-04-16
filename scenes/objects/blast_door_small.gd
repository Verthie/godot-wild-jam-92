extends Node3D

@onready var player_detector: Area3D = $PlayerDetector
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	player_detector.body_entered.connect(_on_body_entered)
	player_detector.body_exited.connect(_on_body_exited)


func _on_body_entered(_body: Node3D) -> void:
	AudioManager.create_3d_audio_at_location(global_position, SoundEffect.SoundEffectType.DOOR_OPEN)
	animation_player.play("Door_move")

func _on_body_exited(_body: Node3D) -> void:
	AudioManager.create_3d_audio_at_location(global_position, SoundEffect.SoundEffectType.DOOR_CLOSE)
	animation_player.play_backwards("Door_move")
