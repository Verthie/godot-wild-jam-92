extends CanvasLayer

@onready var label: Label = $Label

func _ready() -> void:
	EventBus.object_focused.connect(_on_object_focused)
	EventBus.object_unfocused.connect(_on_object_unfocused)
	label.hide()


func _on_object_focused(tag: String) -> void:
	label.show()
	label.text = tag

func _on_object_unfocused() -> void:
	label.hide()
