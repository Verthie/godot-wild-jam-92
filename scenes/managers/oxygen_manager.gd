extends Node

@export_group("Manager values")
## The amount of oxygen percantage that will be replenished on production
@export_range(50, 100) var oxygen_replenishment_amount: int = 75

@export_group("Node references")
@export var oxygen_maker: Node3D
@export var player: Player
@export var ui: CanvasLayer

@onready var timer: Timer = $Timer
@onready var sprint_timer: Timer = $SprintTimer

var oxygen_deplete_enabled: bool = false

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("sprint"):
		sprint_timer.start()
	if Input.is_action_just_released("sprint"):
		sprint_timer.stop()

func _ready() -> void:
	oxygen_maker.produced_oxygen.connect(_on_oxygen_maker_produced_oxygen)
	timer.timeout.connect(_on_timer_timeout)
	sprint_timer.timeout.connect(_on_sprint_timer_timeout)

func _process(_delta) -> void:
	ui.update_oxygen_display(timer.time_left)

func enable_oxygen_deplete() -> void:
	timer.start()

func disable_oxygen_deplete() -> void:
	timer.stop()

func _on_timer_timeout() -> void:
	player.health_component.damage(player.health_component.max_health)

func _on_oxygen_maker_produced_oxygen() -> void:
	var current_percentage = clamp(timer.time_left + 50, 0, 100)
	timer.start(current_percentage)

func _on_sprint_timer_timeout() -> void:
	var current_percentage = clamp(timer.time_left - 1, 0, 100)
	timer.start(current_percentage)
