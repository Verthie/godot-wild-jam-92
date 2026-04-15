extends CharacterBody3D

@export var speed := 5.0
@export var mouse_sensitivity := 0.002

var gravity := 9.8
var jump_velocity := 4.5

@onready var camera = $Camera3D
@export var interact_distance := 3.0

var y_velocity := 0.0

var left_hand_item = null
var right_hand_item = null

@onready var left_hand = $"Camera3D/Left Hand"
@onready var right_hand = $"Camera3D/Right Hand"

@onready var hold_ray = $"Camera3D/Item Ray"

var mouse_delta := Vector2.ZERO


var prev_camera_basis : Basis
var rotation_diff

var walk_time := 0.0

@onready var interaction_label = $"../CanvasLayer/InteractionLabel"
@onready var crosshair = $"../CanvasLayer/CenterContainer/Crosshair"
var current_interactable = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	prev_camera_basis = camera.global_transform.basis

func _input(event):
	if event is InputEventMouseMotion:
		# For bobbing items
		mouse_delta = event.relative
		
		# Rotate player left/right
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate camera up/down
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		
		# Clamp vertical look
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	print(left_hand_item)
	print(left_hand_item.has_method("set_bob_intensity"))
	
	current_interactable = get_looked_at_interactable()
	update_interaction_ui()
	
	if Input.is_action_just_pressed("interact"):
		try_interact("none")

	if Input.is_action_just_pressed("left_click"):
		try_interact("left")

	if Input.is_action_just_pressed("right_click"):
		try_interact("right")
	
	
	var direction = Vector3.ZERO
	
	# Movement input
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_back"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x

	direction = direction.normalized()

	# Apply horizontal movement
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# Gravity
	if not is_on_floor():
		y_velocity -= gravity * delta
	else:
		y_velocity = 0
		
		if Input.is_action_just_pressed("jump"):
			y_velocity = jump_velocity

	velocity.y = y_velocity

	move_and_slide()
	
	# For item bobbing of handheld items
	update_held_items(delta)
	
	var current_basis = camera.global_transform.basis
	rotation_diff = prev_camera_basis.inverse() * current_basis
	prev_camera_basis = current_basis
	
	if velocity.length() > 0.1:
		walk_time += delta * 6.0
	else:
		walk_time = 0.0



func try_interact(hand):
	if current_interactable:
		current_interactable.interact(self, hand)


func update_interaction_ui():
	var interactable = get_looked_at_interactable()
	
	if interactable:
		interaction_label.visible = true
		
		if interactable.has_method("get_interaction_text"):
			interaction_label.text = interactable.get_interaction_text(self)
		else:
			interaction_label.text = "Press E"
		
		# optional: crosshair highlight
		if crosshair:
			crosshair.modulate = Color.GREEN
	else:
		interaction_label.visible = false
		
		if crosshair:
			crosshair.modulate = Color.WHITE


func get_looked_at_interactable():
	var from = camera.global_transform.origin
	var to = from + camera.global_transform.basis.z * -interact_distance
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		
		if collider and collider.has_method("interact"):
			return collider
	
	return null



func update_held_items(delta):
	var distance = 0.5
	
	if hold_ray.is_colliding():
		distance = 0.3
	
	var base_pos = Vector3(0, -0.2, -distance)
	
	var current_speed = velocity.length()
	
	if left_hand_item:
		left_hand_item.set_bob_intensity(current_speed)
		left_hand_item.apply_sway(mouse_delta)
		left_hand_item.set_base_y(base_pos.y)
		left_hand_item.set_base_x(base_pos.x - 0.3)
		var target = Vector3(base_pos.x - 0.2, left_hand_item.position.y, base_pos.z)
		left_hand_item.position = left_hand_item.position.lerp(target, 0.15)
		# left_hand_item.apply_camera_lag(rotation_diff)
		left_hand_item.set_walk_phase(walk_time)
		
	
	if right_hand_item:
		right_hand_item.set_bob_intensity(current_speed)
		right_hand_item.apply_sway(mouse_delta)
		right_hand_item.set_base_y(base_pos.y)
		right_hand_item.set_base_x(base_pos.x + 0.3)
		var target = Vector3(base_pos.x + 0.2, right_hand_item.position.y, base_pos.z)
		right_hand_item.position = right_hand_item.position.lerp(target, 0.15)
		# right_hand_item.apply_camera_lag(rotation_diff)
		right_hand_item.set_walk_phase(walk_time)
	
	mouse_delta = Vector2.ZERO


func give_item_to_hand(scene: PackedScene, hand: String):
	var instance = scene.instantiate()
	
	var hand_node
	if hand == "left":
		hand_node = left_hand
		left_hand_item = instance
	elif hand == "right":
		hand_node = right_hand
		right_hand_item = instance
	hand_node.add_child(instance)
	
	# unified transform (how item looks on hand)
	instance.position = Vector3(0, -0.2, -0.5)
	instance.rotation_degrees = Vector3(20, 30, 0)
	instance.scale = Vector3(0.5, 0.5, 0.5)
	
	return instance


func get_hand_item(hand: String):
	return left_hand_item if hand == "left" else right_hand_item
	
func clear_hand_item(hand: String):
	if hand == "left":
		left_hand_item = null
	else:
		right_hand_item = null

func show_message(message: String):
	pass
