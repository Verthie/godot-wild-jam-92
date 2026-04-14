extends CanvasLayer

@export var player: Player
@export var oxygen_manager: Node

@onready var label: Label = $Label
@onready var player_speech: Label = %PlayerSpeech
@onready var oxygen_bar: ProgressBar = $OxygenBar

func _ready() -> void:
	player.talked.connect(_on_player_talked)
	player.object_focused.connect(_on_player_object_focused)
	player.object_unfocused.connect(_on_player_object_unfocused)
	player.died.connect(_on_player_died)
	label.hide()
	player_speech.hide()

func _process(_delta: float) -> void:
	var timer: Timer = oxygen_manager.get_node("Timer")
	oxygen_bar.value = timer.time_left


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

func _on_player_died() -> void:
	print("player died")
