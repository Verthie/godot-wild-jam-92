extends Node

@export_group("Manager values")
## The amount of oxygen percantage that will be replenished on production
@export_range(50, 100) var oxygen_replenishment_amount: int = 75

@export_group("Node references")
@export var oxygen_maker: Node3D
@export var player: Player
@export var ui: Interface

@onready var timer: Timer = $Timer
@onready var sprint_timer: Timer = $SprintTimer

var warning_triggered: bool = false


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
	if timer.time_left == 20 and !warning_triggered:
		ui.timed_display_prompt("LOW OXYGEN WARNING", 3)
		AudioManager.create_audio(SoundEffect.SoundEffectType.OXYGEN_WARNING_FINAL)
		warning_triggered = true

func set_oxygen_display(state: bool = true) -> void:
	if state:
		ui.oxygen_bar.show()
	else:
		ui.oxygen_bar.hide()

func enable_oxygen_deplete(initial_value: float = timer.wait_time) -> void:
	timer.start(initial_value)

func disable_oxygen_deplete() -> void:
	timer.stop()

func pause_oxygen_deplete(state: bool = true) -> void:
	timer.paused = state

func _on_timer_timeout() -> void:
	player.health_component.damage(player.health_component.max_health)

func _on_oxygen_maker_produced_oxygen() -> void:
	var current_percentage = clamp(timer.time_left + oxygen_replenishment_amount, 0, ui.oxygen_bar.max_value)
	timer.start(current_percentage)
	warning_triggered = false
	AudioManager.create_3d_audio_at_location(oxygen_maker.global_position, SoundEffect.SoundEffectType.OXYGEN_REPLENISH)

func _on_sprint_timer_timeout() -> void:
	var current_percentage = clamp(timer.time_left - ui.oxygen_bar.step + 1, 0, timer.wait_time)
	timer.start(current_percentage)
