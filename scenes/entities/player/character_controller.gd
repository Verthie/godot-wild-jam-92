# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D
class_name Player

signal object_focused(tag: String)
signal object_unfocused
signal talked(text: String)
signal enabled_sampler(tries_amount: int)
signal pulled_cure_lever
signal produced_oxygen
signal died

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

@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var interaction_ray: Area3D = $Head/InteractionRay

@onready var hand_right: Node3D = $Head/HandRight
@onready var hand_left: Node3D = $Head/HandLeft

## The amount of interaction areas that currently overlap with the player
# var interact_areas := 0

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var can_interact : bool = false

var left_hand_item: Node3D = null
var right_hand_item: Node3D = null


func _ready() -> void:
	interaction_ray.area_entered.connect(_on_interaction_ray_area_entered)
	interaction_ray.area_exited.connect(_on_interaction_ray_area_exited)
	check_input_mappings()
	capture_mouse()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x


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
		rotate_look(event.relative)

	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

	if !can_interact:
		return

	if event.is_action_pressed("interact_left"):
		handle_interaction("left")
	if event.is_action_pressed("interact_right"):
		handle_interaction("right")

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

	# Use velocity to actually move
	move_and_slide()


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


func handle_interaction(hand: String) -> void:
	var overlapping_areas: Array = interaction_ray.get_overlapping_areas()

	if overlapping_areas.is_empty():
		return

	var interactable: Interactable = overlapping_areas[0].get_parent()

	match interactable.type:
		0: # Ingredient
			if hand == "right" and right_hand_item == null:
				interactable.object_area.monitorable = false
				interactable.reparent(hand_right, false)
				interactable.position = Vector3.ZERO
				right_hand_item = interactable

			if hand == "left" and left_hand_item == null:
				interactable.object_area.monitorable = false
				interactable.reparent(hand_left, false)
				interactable.position = Vector3.ZERO
				left_hand_item = interactable
		1: # Brewing Stand
			# check if the brewing stand has empty slots if not display a prompt that it is full
			var brewing_contents: Array[Node3D] = interactable.node_array

			if brewing_contents.size() == interactable.capacity and (left_hand_item != null or right_hand_item != null):
				talked.emit("The brewing stand seems to be full...")
				return

			# if it has empty slots and player holds an item he puts it inside
			if (hand == "right" and right_hand_item != null and right_hand_item.tag != "moon seed"):
				brewing_contents.append(right_hand_item)
				right_hand_item.reparent(interactable.holder_node, false)
				right_hand_item = null

			elif (hand == "left" and left_hand_item != null and left_hand_item.tag != "moon seed"):
				brewing_contents.append(left_hand_item)
				left_hand_item.reparent(interactable.holder_node, false)
				left_hand_item = null

			elif brewing_contents.size() > 0:
				if (hand == "right" and right_hand_item == null):
					var item = brewing_contents.pop_back()
					item.reparent(hand_right, false)
					right_hand_item = item

				if (hand == "left" and left_hand_item == null):
					var item = brewing_contents.pop_back()
					item.reparent(hand_left, false)
					left_hand_item = item

			print(interactable.tag, " ingredient amount: ", brewing_contents.size())
		2: # Lever
			var brewing_stand: Interactable = interactable.get_parent()

			var brewing_contents: Array[Node3D] = brewing_stand.node_array

			if brewing_contents.size() != brewing_stand.capacity:
				talked.emit("It needs to be full...")
				return

			talked.emit("Brewing comences, ingredients are dissolved...")

			var ingredients_array: Array[String] = []

			for ingredient: Interactable in brewing_contents:
				ingredients_array.append(ingredient.tag)

			print(brewing_stand.tag, " ingredients: ", ingredients_array)

			if brewing_stand.tag == "o2 brewing stand" and ingredients_array == ["watermelon", "mist seed"]:
				print("produced oxygen")
				produced_oxygen.emit()

			brewing_stand.node_array.clear()

			if brewing_stand.tag == "cure brewing stand":
				pulled_cure_lever.emit()

			# TODO display results on the board
		3: # Log
			# TODO display log on screen
			pass
		4: # Bowl
			var bowl_contents: Array[Node3D] = interactable.node_array

			if bowl_contents.size() > 0:
				if (hand == "right" and right_hand_item == null):
					var item = bowl_contents.pop_back()
					item.reparent(hand_right, false)
					right_hand_item = item

				if (hand == "left" and left_hand_item == null):
					var item = bowl_contents.pop_back()
					item.reparent(hand_left, false)
					left_hand_item = item

			elif bowl_contents.size() < interactable.capacity:
				if (hand == "right" and right_hand_item != null):
					bowl_contents.append(right_hand_item)
					right_hand_item.reparent(interactable.holder_node, false)
					right_hand_item.position = Vector3.ZERO
					right_hand_item = null

				if (hand == "left" and left_hand_item != null):
					bowl_contents.append(left_hand_item)
					left_hand_item.reparent(interactable.holder_node, false)
					left_hand_item.position = Vector3.ZERO
					left_hand_item = null
		5: # Trash Can
			if (hand == "right" and right_hand_item != null and right_hand_item.tag != "moon seed"):
				right_hand_item.queue_free()
				right_hand_item = null

			if (hand == "left" and left_hand_item != null and left_hand_item.tag != "moon seed"):
				left_hand_item.queue_free()
				left_hand_item = null
		6: # Sampler
			if (hand == "right" and right_hand_item != null and right_hand_item.tag == "moon seed"):
				right_hand_item.queue_free()
				right_hand_item = null
				enabled_sampler.emit(5)

			if (hand == "left" and left_hand_item != null and left_hand_item.tag == "moon seed"):
				left_hand_item.queue_free()
				left_hand_item = null
				enabled_sampler.emit(5)
		_:
			return

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


## Updates the amount of overlapping areas
# func update_interaction(delta: int) -> void:
# 	interact_areas += delta
# 	interact_areas = max(interact_areas, 0)
# 	can_interact = interact_areas > 0

func die() -> void:
	died.emit()

# BUG issues with the prompt display: whenever 2 or more areas are overlapped with the interaction_ray
func _on_interaction_ray_area_entered(area: Area3D) -> void:
	object_focused.emit(area.get_parent().tag)
	can_interact = true

func _on_interaction_ray_area_exited(_area: Area3D) -> void:
	object_unfocused.emit()
	can_interact = false
