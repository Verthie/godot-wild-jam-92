extends Node

@export var health_component: HealthComponent

func _ready():
	health_component.died.connect(on_died)

func on_died():
	if owner == null || not owner is CharacterBody3D:
		return

	print("died, bleh xo")
