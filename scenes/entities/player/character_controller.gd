# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D
class_name Player

signal talked(text: String)
signal finished_reading

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "left"
## Name of Input Action to move Right.
@export var input_right : String = "right"
## Name of Input Action to move Forward.
@export var input_forward : String = "forward"
## Name of Input Action to move Backward.
@export var input_back : String = "backward"
## Name of Input Action to Jump.
@export var input_jump : String = "jump"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"

@export var interact_distance := 3.0 # how far player can interact

@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var hold_ray = $Head/InteractionRay

@onready var hand_right: Node3D = $Head/HandRight
@onready var hand_left: Node3D = $Head/HandLeft

# Interface
@onready var canvas_layer = $CanvasLayer
@onready var interaction_label = $"CanvasLayer/InteractionLabel"
@onready var crosshair = $"CanvasLayer/CenterContainer/Crosshair"
@onready var journal_ui = $JournalUI
@onready var journal_text = $JournalUI/TextureRect/JournalText
@onready var tape_ui = $TapeUI
@onready var tape_text = $TapeUI/TextureRect/TapeText
@onready var brewery_handbook_ui = $BreweryHandbookUI
@onready var brewery_handbook_text = $BreweryHandbookUI/TextureRect/BreweryHandbookText


var current_ui = null
var ui_open := false

@onready var ui_map = {
	Globals.UITextType.JOURNAL: $JournalUI,
	Globals.UITextType.HANDBOOK: $BreweryHandbookUI,
	Globals.UITextType.TAPE: $TapeUI
}

#--------------

@onready var health_component: HealthComponent = $HealthComponent

@onready var camera: Camera3D = %Camera3D
@onready var fog: MeshInstance3D = %Fog
@onready var psx: ColorRect = %Psx

var left_hand_item = null
var right_hand_item = null
var interactable = null

var mouse_delta := Vector2.ZERO
var walk_time := 0.0

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var can_interact : bool = false
var can_move_camera: bool = true

@export_group("Item Scenes")
@export var moon_seed_item_scene: PackedScene

func _ready() -> void:
	check_input_mappings()
	capture_mouse()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	fog.show()


func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if mouse_captured:
			release_mouse()
			get_viewport().set_input_as_handled()

	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		if !can_move_camera:
			return
		rotate_look(event.relative)

	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

	# Jason 15/4/26 Changed, let's use try_interact() instead of handle_interaction()
	if event.is_action_pressed("interact_left"):
		try_interact("left")

	if event.is_action_pressed("interact_right"):
		try_interact("right")

	# Press E
	if event.is_action_pressed("interact"):
		
		if ui_open:
			if current_ui.typing:
				current_ui.finish_typing()
			else:
				if current_ui.has_next_page():
					current_ui.next_page()
				else:
					close_ui()
		else:
			try_interact("none")

	if Input.is_action_just_pressed("zoom_out"):
		camera.fov = min(camera.fov + 5, 45)

	if Input.is_action_just_pressed("zoom_in"):
		camera.fov = max(camera.fov - 5, 25)

		


func _input(event):
	if event is InputEventMouseMotion:
		mouse_delta = event.relative



func _physics_process(delta: float) -> void:
	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return

	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity

	# Modify speed based on sprinting
	if can_sprint and Input.is_action_pressed(input_sprint):
			move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0
		velocity.z = 0

	# for bobbing of items, keep track of walk time
	if velocity.length() > 0.1:
		walk_time += delta * 6.0
	else:
		walk_time = 0.0

	interactable = get_looked_at_interactable()
	update_interaction_ui()
	update_held_items(delta)
	mouse_delta = Vector2.ZERO


	# Use velocity to actually move
	move_and_slide()


func try_interact(hand: String):

	if interactable:
		interactable.interact(self, hand)


func update_interaction_ui():
	var interactable = get_looked_at_interactable()

	if interactable:
		interaction_label.visible = true

		if interactable.has_method("get_interaction_text"):
			interaction_label.text = interactable.get_interaction_text(self)
		else:
			interaction_label.text = "Press E"

		if crosshair:
			crosshair.modulate = Color.GREEN
	else:
		interaction_label.visible = false

		if crosshair:
			crosshair.modulate = Color.WHITE

# Jason 15/4/26
func get_looked_at_interactable():
	if ui_open:
		return null
	
	if hold_ray.is_colliding():
		var collider = hold_ray.get_collider()
		if is_instance_valid(collider) and collider.has_method("interact"):
			return collider
	return null


## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)


func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
	get_viewport().set_input_as_handled()


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false





# Item helper functions

func give_item_to_hand(scene: PackedScene, hand: String):
	var instance = scene.instantiate()

	var hand_node
	if hand == "left":
		hand_node = hand_left
		left_hand_item = instance
	elif hand == "right":
		hand_node = hand_right
		right_hand_item = instance
	hand_node.add_child(instance)

	# unified transform (how item looks on hand)
	# tweak this for position of handheld items
	# (possibly can change parameters in update_held_items as well if needed)
	instance.position = Vector3(0, 0, 0)
	instance.rotation_degrees = Vector3(20, 30, 0)
	instance.scale = Vector3(0.04, 0.04, 0.04)

	return instance


func get_hand_item(hand: String):
	return left_hand_item if hand == "left" else right_hand_item

func clear_hand_item(hand: String):
	if hand == "left":
		left_hand_item = null
	else:
		right_hand_item = null


func update_held_items(delta):
	var distance = 0.5

	'''
	if hold_ray.is_colliding():
		var collider = hold_ray.get_collider()

		if is_instance_valid(collider) and collider.has_method("interact"):
			distance = 0.03
	'''

	var base_pos = Vector3(0, 0, -distance)

	var current_speed = velocity.length()

	if left_hand_item:
		left_hand_item.set_bob_intensity(current_speed)
		left_hand_item.apply_sway(mouse_delta)
		left_hand_item.set_base_y(base_pos.y)
		left_hand_item.set_base_x(base_pos.x - 0)
		var target = Vector3(base_pos.x - 0, left_hand_item.position.y, base_pos.z + 0.5)
		left_hand_item.position = left_hand_item.position.lerp(target, 0.15)
		# left_hand_item.apply_camera_lag(rotation_diff)
		left_hand_item.set_walk_phase(walk_time)

	if right_hand_item:
		right_hand_item.set_bob_intensity(current_speed)
		right_hand_item.apply_sway(mouse_delta)
		right_hand_item.set_base_y(base_pos.y)
		right_hand_item.set_base_x(base_pos.x + 0)
		var target = Vector3(base_pos.x + 0, right_hand_item.position.y, base_pos.z + 0.5)
		right_hand_item.position = right_hand_item.position.lerp(target, 0.15)
		# right_hand_item.apply_camera_lag(rotation_diff)
		right_hand_item.set_walk_phase(walk_time)

	mouse_delta = Vector2.ZERO

# this is a rough fix for oxygen maker
func spawn_item_by_tag(tag, hand):
	match tag:
		"mist_seed":
			give_item_to_hand(preload("res://scenes/items/Ingredients/mist_seed_item.tscn"), hand)
		"watermelon":
			give_item_to_hand(preload("res://scenes/items/Ingredients/watermelon_item.tscn"), hand)


func set_movement_enabled(state: bool):
	can_move = state


func show_ui(tag: String, type: int):
	var pages = Globals.journal_texts.get(tag, [])
	
	var ui = ui_map.get(type, null)
	if ui == null:
		push_error("UI type not found")
		return
	
	ui.show_pages(pages)
	ui.visible = true
	
	current_ui = ui
	ui_open = true
	set_movement_enabled(false)
	

func close_ui():
	if current_ui:
		current_ui.visible = false
	
	current_ui = null
	ui_open = false
	set_movement_enabled(true)
	finished_reading.emit()

func is_ui_open() -> bool:
	return ui_open
