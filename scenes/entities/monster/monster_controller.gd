extends CharacterBody3D
class_name Monster

signal entered_phase(phase_number: int)

@export var chase_enabled: bool = false

@export var speed := 0.9
@export var panic_speed := 1.1 # Phase 3 panic chase speed

@export var player: Player
@export var chasing_distance := 10.0
@export var panic_distance := 1.0

@export var gravity := 9.8 # Earth gravity

@export var wander_radius := 5.0
var wander_reach_threshold := 1.5

var body_turn_speed := 5.0

@onready var monster_region = $"../MonsterRegion"
@onready var indoor_region = $"../IndoorRegion"

var wander_target : Vector3
var has_target := false

# Prevents getting stuck in one place
var stuck_timer := 0.0
var last_position: Vector3
var stuck_time_threshold := 2.0
var min_movement := 0.002

var current_phase: int = 1


func _ready() -> void:
	print(monster_region)
	print(indoor_region)

	last_position = global_position


func _physics_process(delta):
	if !chase_enabled:
		return

	if player == null:
		player = get_tree().get_first_node_in_group("player")

	var distance = global_position.distance_to(player.global_position)
	# print(distance)

	## --- PHASE DECISION ---
	if is_player_indoor():
		set_phase(1)
		#print("Phase 1")

	elif current_phase == 2 and distance < panic_distance:
		set_phase(3)
		#print("Phase 3")

	elif can_see_player():
		set_phase(2)
		#print("Phase 2")

	else:
		set_phase(1)
		#print("Phase 1")


	match current_phase:
		1: wander(delta)
		2: chase(delta, false) # normal chase
		3: chase(delta, true)  # panic chase


	# Gravity exists at all times for monster
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	move_and_slide()

	# Check if stuck
	var moved_dist = global_position.distance_to(last_position)

	if moved_dist < min_movement:
		stuck_timer += delta
	else:
		stuck_timer = 0.0

	last_position = global_position

	# if stuck → change to new target
	if stuck_timer > stuck_time_threshold:
		# print("stuck")
		has_target = false
		stuck_timer = 0.0


func set_phase(new_phase: int):
	if current_phase != new_phase:
		current_phase = new_phase
		entered_phase.emit(current_phase)

func can_see_player() -> bool:
	if player == null:
		return false

	# --- distance check ---
	var distance = global_position.distance_to(player.global_position)
	if distance > chasing_distance:
		return false

	# --- indoor check ---
	if is_player_indoor():
		return false

	# --- line of sight check ---
	var space = get_world_3d().direct_space_state

	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 1.0,
		player.global_position + Vector3.UP * 1.0
	)

	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result = space.intersect_ray(query)

	if result.is_empty():
		return true

	return result.collider == player



func get_smart_wander_point():
	var best_point = global_position
	var best_score = -INF

	for i in range(36):
		var angle = randf() * TAU

		# Prefer far distances
		var dist = randf_range(wander_radius * 0.7, wander_radius * 1.8)

		var candidate = global_position + Vector3(
			cos(angle) * dist, 0, sin(angle) * dist
		)

		# Reject if outside allowed region
		if not is_inside_monster_region(candidate):
			continue

		# Reject if inside house
		if is_inside_indoor(candidate):
			continue

		# Reject if path is blocked by house)
		if not has_clear_path(candidate):
			continue

		# Scoring: prefer far movement
		var score = global_position.distance_to(candidate)

		if score > best_score:
			best_score = score
			best_point = candidate

	if best_score == -INF:
		# print("can't find far point")
		return global_position + Vector3(
			randf_range(-5, 5), 0, randf_range(-5, 5)
		)

	# print("Far point: ", best_point)
	return best_point



func is_player_indoor() -> bool:
	var space = get_world_3d().direct_space_state

	var query = PhysicsPointQueryParameters3D.new()
	query.position = player.global_position
	query.collide_with_areas = true

	var result = space.intersect_point(query)

	for r in result:
		if r.collider == indoor_region or indoor_region.is_ancestor_of(r.collider):
			return true

	return false




func has_clear_path(target: Vector3) -> bool:
	var space = get_world_3d().direct_space_state

	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.5,
		target + Vector3.UP * 0.5
	)

	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result = space.intersect_ray(query)

	return result.is_empty()


func is_inside_monster_region(pos: Vector3) -> bool:
	var space = get_world_3d().direct_space_state

	var query = PhysicsPointQueryParameters3D.new()
	query.position = pos
	query.collide_with_areas = true

	var result = space.intersect_point(query)

	for r in result:
		if r.collider == monster_region:
			return true

	return false


func is_inside_indoor(pos: Vector3) -> bool:
	var space = get_world_3d().direct_space_state

	var query = PhysicsPointQueryParameters3D.new()
	query.position = pos
	query.collide_with_areas = true

	var result = space.intersect_point(query)

	for r in result:
		if r.collider == indoor_region or indoor_region.is_ancestor_of(r.collider):
			return true

	return false



# The monster rotates its body smoothly facing the wandering target
func rotate_towards(target: Vector3, delta):
	var direction = (target - global_position)
	direction.y = 0

	var target_angle = atan2(direction.x, direction.z)

	rotation.y = lerp_angle(rotation.y, target_angle, body_turn_speed * delta)


func wander(delta):
	# --- Wander ---
	if not has_target:
		wander_target = get_smart_wander_point()
		has_target = true

	var target = wander_target
	target.y = global_position.y

	var distance = global_position.distance_to(target)

	# reached target → pick new
	if distance < wander_reach_threshold:
		has_target = false
		return

	# move toward target
	var direction = (target - global_position).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	rotate_towards(target, delta)


func chase(delta, is_panic: bool):
	# --- Chase Player ---
	# "target" is the position of the player if standing on the floor
	var target = player.global_position
	target.y = global_position.y

	var direction = (target - global_position).normalized()

	if is_panic:
		velocity.x = direction.x * panic_speed
		velocity.z = direction.z * panic_speed
	else:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

	rotate_towards(target, delta)
