extends Node3D

@onready var player: Player = $CharacterController
@onready var try_counter: Label3D = %SeedCount

var tries: int = 0

func _ready() -> void:
	player.enabled_sampler.connect(_on_player_enabled_sampler)
	player.pulled_lever.connect(_on_player_pulled_lever)

	try_counter.hide()

func _on_player_enabled_sampler(tries_amount: int) -> void:
	tries = tries_amount
	%SeedCount.text = str(tries_amount)
	try_counter.show()

func _on_player_pulled_lever() -> void:
	tries -= 1
	%SeedCount.text = str(tries)
