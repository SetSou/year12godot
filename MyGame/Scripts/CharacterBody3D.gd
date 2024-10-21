extends CharacterBody3D

var speed
var gravity = 9.8
var jumped = false
var wall = true
const WALK_SPEED = 4.0
const SPRINT_SPEED = 9.0
const CROUCH_SPEED = 3.0
const WALLRUN_SPEED = 10.0
const JUMP_VELOCITY = 4.8
const SENSITIVITY = 0.003

const BOB_FREQ = 2
const BOB_AMP = 0.08
var t_bob = 0.0

const BASE_FOV = 75.0
const FOV_CHANGE = 1.5
@onready var head = $Head
@onready var camera = $Head/Camera
@onready var capsule = $Collision
@onready var right_wall_cast = $Head/RightWallCast
@onready var left_wall_cast = $Head/LeftWallCast
@onready var right_long_cast = $Head/RightLongCast
@onready var left_long_cast = $Head/LeftLongCast

@export var state = "normal"

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$CrouchAnimation.play("RESET")
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(70))
	
func wall_run(direction):
	if Input.is_action_pressed("forwards"):
		if is_on_wall() and right_wall_cast.is_colliding() and velocity.y < 0:
			#print("gravity lower")
			enter_wall_state()
			gravity = 1
			wall = true
			#camera.rotate_z(0.1)
			#camera.rotation.z = clamp(camera.rotation.z, deg_to_rad(0), deg_to_rad(10))
	
		if is_on_wall() and left_wall_cast.is_colliding() and velocity.y < 0:
			#print("gravity lower")
			enter_wall_state()
			gravity = 1
			wall = true
			
	if Input.is_action_just_pressed("jump") and jumped == false and not is_on_floor():
		if is_on_wall():
			if left_wall_cast.is_colliding():
				velocity = head.transform.basis *  Vector3.RIGHT * 6 + direction
				velocity.y += 4
				jumped = true
			if right_wall_cast.is_colliding():
				velocity = head.transform.basis *  Vector3.LEFT * 6 + direction
				velocity.y += 4
				jumped = true
	if is_on_wall() and wall == false:
		velocity.y /= 5
		wall = true
		
	if jumped == true:
		wall = false
func _physics_process(delta):
	#print(wall)
	if state == "normal":
		speed = WALK_SPEED
	if state == "sprinting":
		speed = SPRINT_SPEED
	if state == "crouching":
		speed = CROUCH_SPEED
	# Add the gravity
	#print(jumped)
	if not is_on_floor():
		velocity.y -= gravity * delta
		if not is_on_wall() and jumped == false:
			gravity = 9.8
	else:
		if jumped == true:
			jumped = false
			gravity = 9.8
	if not is_on_wall():
		#print("gravity normal")
		if jumped == false and state != "crouching":
			enter_normal_state()
		if is_on_floor():
			jumped = false
		if jumped == true:
			if not right_long_cast.is_colliding() and not left_long_cast.is_colliding():
				jumped = false
		gravity = 9.8
	
	# Handle jump.
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# Handle DASH?????
	if Input.is_action_pressed("dash"):
		velocity.x = JUMP_VELOCITY
	# Handle crouch.
	if Input.is_action_pressed("crouch") and state != "sprinting":
		if state != "crouching":
			enter_crouch_state()
	else:
		enter_normal_state()
	
	if jumped == true:
		gravity = 9.8
	# Handle sprint.
	if Input.is_action_pressed("sprint") and state != ("crouching"):
		enter_sprint_state()

	
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forwards", "backwards")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	wall_run(direction)
	move_and_slide()
	

func enter_normal_state():
	#print("entering normal state")
	if !$CrouchCeilingDetection.is_colliding():
		var prev_state = state
		if prev_state == "crouching":
			$CrouchAnimation.play_backwards("crouch")
		state = "normal"
		speed = WALK_SPEED

func enter_crouch_state():
	#print("entering crouch state")
	state = "crouching"
	speed = CROUCH_SPEED
	$CrouchAnimation.play("crouch")
	await $CrouchAnimation.animation_finished
	

func enter_sprint_state():
	#print("entering sprint state")
	var prev_state = state
	if prev_state == "crouching":
		$CrouchAnimation.play_backwards("crouch")
	if prev_state != "wallrunning":
		state = "sprinting"
		speed = SPRINT_SPEED

func enter_wall_state():
	#print("entering wall state")
	state = "wallrunning"
	speed = WALLRUN_SPEED


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
