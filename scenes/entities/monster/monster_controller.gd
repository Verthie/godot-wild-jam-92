extends CharacterBody3D

@export var speed := 3.0
@export var player: Player
@export var chasing_distance := 10.0

@export var gravity := 9.8 # Earth gravity

@export var wander_radius := 10.0
@export var wander_interval := 4.0

@export var idle_probability := 0.4

@export var body_turn_speed := 5.0

var wander_target : Vector3
var wander_timer := 0.0
var is_idle := false
var idle_timer := 0.0


func _physics_process(delta):
	if player == null:
		return

	wander_timer -= delta
	var distance = global_position.distance_to(player.global_position)
	if distance > chasing_distance:
		# --- Idle ---
		idle_timer -= delta

		if is_idle:
			velocity.x = 0
			velocity.z = 0

			if idle_timer <= 0:
				is_idle = false
				wander_target = get_random_wander_point()
				wander_timer = wander_interval

		else:
			# --- Wander ---
			wander_timer -= delta

			if wander_timer <= 0:
				# 30% chance to idle instead of moving
				if randf() < idle_probability:
					is_idle = true
					idle_timer = randf_range(wander_interval * 0.5, wander_interval * 1.5)
				else:
					wander_target = get_random_wander_point()
					wander_timer = randf_range(wander_interval * 0.5, wander_interval * 1.5)
					# Reset wander timer with randomness within a range

			var target = wander_target
			target.y = global_position.y

			var direction = (target - global_position).normalized()

			velocity.x = direction.x * speed * 0.5
			velocity.z = direction.z * speed * 0.5

			# not immediately look at, but rotate its body smoothly
			rotate_towards(target, delta)


	else:
		# --- Chase Player ---
		print("Monster is near!")

		# "target" is the position of the player if standing on the floor
		var target = player.global_position
		target.y = global_position.y

		# Move towards the player
		var direction = (target - global_position).normalized()

		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		look_at(target)

	# Gravity exists at all times for monster
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	move_and_slide()


func get_random_wander_point():
	var random_offset = Vector3(
		randf_range(-wander_radius, wander_radius),
		0,
		randf_range(-wander_radius, wander_radius)
	)
	return global_position + random_offset


# The monster rotates its body smoothly facing the wandering target
func rotate_towards(target: Vector3, delta):
	var direction = (target - global_position)
	direction.y = 0

	var target_angle = atan2(direction.x, direction.z)

	rotation.y = lerp_angle(rotation.y, target_angle, body_turn_speed * delta)
