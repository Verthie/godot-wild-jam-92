extends Node3D

@onready var icon = $Sprite3D

var flipping := false
var flip_progress := 0.0
var target_color := Color.WHITE
var flipped := false




func _ready() -> void:
	icon.visible = false

func set_icon(tag):
	icon.texture = Globals.icon_lookup[tag]
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
