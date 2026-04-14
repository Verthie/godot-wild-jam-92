extends Node3D

@onready var player: Player = $CharacterController
@onready var try_counter: Label3D = %SeedCount

func _ready() -> void:
	player.enabled_sampler.connect(_on_player_enabled_sampler)
	player.pulled_cure_lever.connect(_on_player_pulled_lever)
	player.died.connect(_on_player_died)

	try_counter.hide()


func _set_seed_amount(amount: int) -> void:
	Globals.seed_amount += amount
	%SeedCount.text = str(Globals.seed_amount)


func _on_player_enabled_sampler(tries_amount: int) -> void:
	_set_seed_amount(tries_amount)
	try_counter.show()

func _on_player_pulled_lever() -> void:
	if Globals.seed_amount == 0:
		return
	_set_seed_amount(-1)

func _on_player_died() -> void:
	_set_seed_amount(-1)
