extends Node

@export_group("Manager values")
## The amount of oxygen percantage that will be replenished on production
@export_range(50, 100) var oxygen_replenishment_amount: int = 75

@export_group("Node references")
@export var oxygen_maker: Node3D
@export var player: Player
@export var ui: CanvasLayer

@onready var timer: Timer = $Timer

func _ready() -> void:
	oxygen_maker.produced_oxygen.connect(_on_oxygen_maker_produced_oxygen)
	timer.timeout.connect(_on_timer_timeout)

func _process(_delta) -> void:
	ui.update_oxygen_display(timer.time_left)

func _on_timer_timeout() -> void:
	player.health_component.damage(player.health_component.max_health)
	# TODO reset game state

func _on_oxygen_maker_produced_oxygen() -> void:
	print("produced oxygen")
	var current_percentage = clamp(timer.time_left + 50, 0, 100)
	timer.start(current_percentage)
