extends CharacterBody3D

var speed
var gravity = 9.8
var jumped = false
var wall = true
var dead = false
const WALK_SPEED = 4.0
const SPRINT_SPEED = 9.0
const CROUCH_SPEED = 3.0
const WALLRUN_SPEED = 10.0
const JUMP_VELOCITY = 5.2
const SENSITIVITY = 0.003

const BOB_FREQ = 2  # Head bobbing frequency
const BOB_AMP = 0.08  # Head bobbing amplitude
var t_bob = 0.0  # Time for head bobbing

const BASE_FOV = 75.0  # Base field of view
const FOV_CHANGE = 1.5  # FOV change when moving
@onready var head = $Head
@onready var camera = $Head/Camera
@onready var capsule = $Collision
@onready var right_wall_cast = $Head/RightWallCast
@onready var left_wall_cast = $Head/LeftWallCast
@onready var right_long_cast = $Head/RightLongCast
@onready var left_long_cast = $Head/LeftLongCast
@onready var guns = $Head/Camera/Weapons

@export var state = "normal"

#capture the mouse and reset crouch animation
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$CrouchAnimation.play("RESET")
	
# Handle mouse movement for looking around
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(70))
	
# Wall run mechanic, checks if player can wall run and handles jumping from walls
func wall_run(direction):
	if Input.is_action_pressed("forwards"):
		# Wall run on right wall
		if is_on_wall() and right_wall_cast.is_colliding() and velocity.y < 0:
			enter_wall_state()
			gravity = 1
			wall = true
			
		# Wall run on left wall
		if is_on_wall() and left_wall_cast.is_colliding() and velocity.y < 0:
			#print("gravity lower")
			enter_wall_state()
			gravity = 1
			wall = true
	# Wall jump 
	if Input.is_action_just_pressed("jump") and jumped == false and not is_on_floor():
		if is_on_wall():
			# Jump from left wall
			if left_wall_cast.is_colliding():
				velocity = head.transform.basis *  Vector3.RIGHT * 6 + direction
				velocity.y += 4
				jumped = true
			# Jump from right wall
			if right_wall_cast.is_colliding():
				velocity = head.transform.basis *  Vector3.LEFT * 6 + direction
				velocity.y += 4
				jumped = true
	
	# Adjust velocity when wall running
	if is_on_wall() and wall == false:
		velocity.y /= 5
		wall = true
	# Reset wall running state when jumping
	if jumped == true:
		wall = false

# Process input to exit the game and handle death state
func _process(delta):
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	if dead:
		return

# Main physics process for movement, gravity, and state transitions
func _physics_process(delta):
	if dead == true:
		return
	
	# Set speed based on current state
	if state == "normal":
		speed = WALK_SPEED
	if state == "sprinting":
		speed = SPRINT_SPEED
	if state == "crouching":
		speed = CROUCH_SPEED
		
	# Apply gravity if not on the ground
	if not is_on_floor():
		velocity.y -= gravity * delta
		if not is_on_wall() and jumped == false:
			gravity = 9.8
	# Reset gravity and jump states when on the ground
	else:
		if jumped == true:
			jumped = false
			gravity = 9.8
	
	# Checks if the player has jumped of a wall and lets them jump from another wall
	if not is_on_wall():
		if jumped == false and state != "crouching":
			enter_normal_state()
		if is_on_floor():
			jumped = false
		if jumped == true:
			if not right_long_cast.is_colliding() and not left_long_cast.is_colliding():
				jumped = false
		gravity = 9.8
	
	# Handle jumping
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# Handle dashing (not implemented)
	#if Input.is_action_pressed("dash"):
		
	# Handle crouching
	if Input.is_action_pressed("crouch") and state != "sprinting":
		if state != "crouching":
			enter_crouch_state()
	else:
		enter_normal_state()
	
	# Reset gravity after jumping
	if jumped == true:
		gravity = 9.8
	
	# Handle sprinting
	if Input.is_action_pressed("sprint") and state != ("crouching"):
		enter_sprint_state()

	
	
	# Move player based on input direction
	var input_dir = Input.get_vector("left", "right", "forwards", "backwards")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	# Handle movement on ground
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	# Handle movement in the air
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	# Handle head bobbing effect
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# Adjust field of view based on speed
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	# Call wall run mechanic
	wall_run(direction)
	move_and_slide()

# change to normal walking state
func enter_normal_state():
	#print("entering normal state")
	if !$CrouchCeilingDetection.is_colliding():
		var prev_state = state
		if prev_state == "crouching":
			$CrouchAnimation.play_backwards("crouch")
		state = "normal"
		speed = WALK_SPEED

# change to crouch state
func enter_crouch_state():
	#print("entering crouch state")
	state = "crouching"
	speed = CROUCH_SPEED
	$CrouchAnimation.play("crouch")
	await $CrouchAnimation.animation_finished
	
# change to sprint state
func enter_sprint_state():
	#print("entering sprint state")
	var prev_state = state
	if prev_state == "crouching":
		$CrouchAnimation.play_backwards("crouch")
	if prev_state != "wallrunning":
		state = "sprinting"
		speed = SPRINT_SPEED
		
# change to wallrunning state
func enter_wall_state():
	#print("entering wall state")
	state = "wallrunning"
	speed = WALLRUN_SPEED

# Handle head bobbing effect for camera
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

# Kill the player and display the death screen
func kill():
	dead = true
	$CanvasLayer/Deathscreen.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# Reload the current scene when restart button is pressed
func _on_button_pressed():
	get_tree().reload_current_scene()
