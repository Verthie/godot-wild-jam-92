extends CanvasLayer
class_name Interface

@onready var bottom_prompt: Label = %BottomPrompt
@onready var oxygen_bar: ProgressBar = $OxygenBar
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	bottom_prompt.hide()

func update_oxygen_display(value: float) -> void:
	oxygen_bar.value = value

func display_prompt(text: String):
	bottom_prompt.text = text
	bottom_prompt.show()

func hide_prompt():
	bottom_prompt.hide()

func timed_display_prompt(text: String, seconds: float) -> void:
	display_prompt(text)
	await get_tree().create_timer(seconds).timeout
	hide_prompt()

func fade_out_screen(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, duration)
	await tween.finished

func fade_in_screen(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, duration)
	await tween.finished
