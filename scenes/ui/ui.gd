extends CanvasLayer

@export var player: Player

@onready var label: Label = $Label
@onready var player_speech: Label = %PlayerSpeech

func _ready() -> void:
	player.talked.connect(_on_player_talked)
	player.object_focused.connect(_on_player_object_focused)
	player.object_unfocused.connect(_on_player_object_unfocused)
	label.hide()
	player_speech.hide()


func _on_player_object_focused(tag: String) -> void:
	label.show()
	label.text = tag

func _on_player_object_unfocused() -> void:
	label.hide()

func _on_player_talked(text: String) -> void:
	player_speech.text = text
	player_speech.show()
	await get_tree().create_timer(2.0).timeout
	player_speech.hide()
