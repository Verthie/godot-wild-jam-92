extends Node

@export var player: Player

@onready var timer: Timer = $Timer

func _ready() -> void:
	player.produced_oxygen.connect(_on_player_produced_oxygen)
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	player.die()

func _on_player_produced_oxygen() -> void:
	timer.start()
