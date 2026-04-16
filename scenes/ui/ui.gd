extends CanvasLayer

# @export var player: Player

@onready var player_speech: Label = %PlayerSpeech
@onready var oxygen_bar: ProgressBar = $OxygenBar

func _ready() -> void:
	# player.talked.connect(_on_player_talked)
	player_speech.hide()

func update_oxygen_display(value: float) -> void:
	oxygen_bar.value = value

func _on_player_talked(text: String) -> void:
	player_speech.text = text
	player_speech.show()
	await get_tree().create_timer(2.0).timeout
	player_speech.hide()
