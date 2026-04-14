extends Node3D

@export var tag: String = "seed"

@onready var range_area: Area3D = $RangeArea

func _ready() -> void:
	if range_area == null:
		return

	range_area.body_entered.connect(_on_body_entered_area)
	range_area.body_exited.connect(_on_body_exited_area)

func _on_body_entered_area(body: Node3D) -> void:
	if body is Player:
		var player: Player = body
		player.update_interaction(1)
		# print("player in range")

func _on_body_exited_area(body: Node3D) -> void:
	if body is Player:
		var player: Player = body
		player.update_interaction(-1)
		# print("player not in range")
