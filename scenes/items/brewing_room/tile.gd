extends Node3D

@onready var icon = $Sprite3D

var flipping := false
var flip_progress := 0.0
var target_color := Color.WHITE
var flipped := false



var icon_lookup = {
	"watermelon": preload("res://assets/textures/icons/watermelon.png"),
	"pumpkin": preload("res://assets/textures/icons/pumpkin.png"),
	"carrot": preload("res://assets/textures/icons/carrot.png"),
	"mist_seed": preload("res://assets/textures/icons/mist_seed.png"),
	"mush_seed": preload("res://assets/textures/icons/mush_seed.png"),
	"beetroot": preload("res://assets/textures/icons/beetroot.png"),
	"potato": preload("res://assets/textures/icons/potato.png"),
	
	"moon_seed": preload("res://assets/textures/icons/moon_seed.png")
}



func _ready() -> void:
	icon.visible = false

func set_icon(tag):
	icon.texture = icon_lookup[tag]
	icon.visible = true

func clear():
	icon.visible = false

func appear():
	scale = Vector3.ZERO
	visible = true
	
func flip_to_color(color: Color):
	flipping = true
	target_color = color
	flip_progress = 0.0

func _process(delta):
	scale = scale.lerp(Vector3.ONE, 0.2)
	
	if flipping:
		flip_progress += delta * 2.5
		
		var angle = lerp(0.0, 180.0, flip_progress)
		rotation_degrees.x = angle
		
		# halfway → change color
		if angle > 90 and not flipped:
			set_color(target_color)
			flipped = true
		
		if flip_progress >= 1.0:
			flipping = false
			flipped = false
			rotation_degrees.x = 0

func set_color(color):
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED # 2 sided PlaneMesh
	$".".material_override = mat
