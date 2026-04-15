extends Node3D

# Set tags separately for each ingredient
# (ingredient reference) in inspector
@export var tag := ""

var bob_strength := 0.002
var time := 0.0

var base_y := 0.0   # ← NEW
var base_x := 0.0

var sway_offset := Vector3.ZERO
var sway_target := Vector3.ZERO
var lag_rotation := Vector3.ZERO
var walk_phase := 0.0

func set_walk_phase(t):
	walk_phase = t

func set_bob_intensity(speed):
	var target = 0.0
	
	if speed > 0.1:
		target = 0.002 + speed * 0.001
	
	bob_strength = lerp(bob_strength, target, 0.1)
	
func apply_sway(mouse_delta):
	sway_target.x = -mouse_delta.x * 0.0004
	sway_target.y = -mouse_delta.y * 0.0004

func set_base_y(y):
	base_y = y
	
func set_base_x(x):
	base_x = x

func _process(delta):
	time += delta
	
	# bob
	var bob = sin(walk_phase) * bob_strength
	
	# smooth sway
	sway_offset = sway_offset.lerp(sway_target, 0.1)
	sway_target = sway_target.lerp(Vector3.ZERO, 0.1)
	
	position.y = base_y + bob + sway_offset.y
	position.x = base_x + sway_offset.x
	
	# rotation sway
	rotation_degrees.z = sway_offset.x * 15
	rotation_degrees.x = sway_offset.y * 15
	
	# smooth camera lag
	lag_rotation = lag_rotation.lerp(Vector3.ZERO, 0.1)

	rotation_degrees.x += lag_rotation.x * 50
	rotation_degrees.y += lag_rotation.y * 50
	rotation_degrees.z += lag_rotation.z * 50

func apply_camera_lag(rotation_diff):
	var euler = rotation_diff.get_euler()
	
	lag_rotation.x += euler.x
	lag_rotation.y += euler.y
	lag_rotation.z += euler.z
