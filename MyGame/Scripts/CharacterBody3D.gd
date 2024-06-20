extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 7.0
const CROUCH_SPEED = 3.0
const CROUCH_SPRINT_SPEED = 4.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003

const BOB_FREQ = 2
const BOB_AMP = 0.08
var t_bob = 0.0
var wall_normal
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5
var default_height = 1.5
var crouch_height = 0.5
var gravity = 9.8
@export var wall_time = 0
@onready var head = $Head
@onready var camera = $Head/Camera
@onready var capsule = $Collision
@onready var right_wall_cast = $Head/RightWallCast
@onready var left_wall_cast = $Head/LeftWallCast

@export var state = "normal"

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$CrouchAnimation.play("RESET")
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(70))
	
func wall_run():
	if Input.is_action_pressed("forwards"):
		if is_on_wall() and right_wall_cast.is_colliding():
			velocity.y /= 1.15
		if is_on_wall() and left_wall_cast.is_colliding():
			velocity.y /= 1.15
	if Input.is_action_pressed("jump"):
		if is_on_wall():
			velocity.y = 4.5
	
func _physics_process(delta):
	speed = WALK_SPEED
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# Handle crouch.
	if Input.is_action_pressed("crouch") and state != "sprinting":
		if state != "crouching":
			enter_crouch_state()
	else:
		enter_normal_state()
		
	# Handle sprint.
	if Input.is_action_pressed("sprint") and not Input.is_action_pressed("crouch"):
		enter_sprint_state()
	if state == "crouching":
		speed = CROUCH_SPEED
	
	
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
	wall_run()
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
	var prev_state = state
	state = "crouching"
	speed = CROUCH_SPEED
	$CrouchAnimation.play("crouch")
	

func enter_sprint_state():
	#print("entering sprint state")
	var prev_state = state
	if prev_state == "crouching":
		$CrouchAnimation.play_backwards("crouch")
	state = "sprinting"
	speed = SPRINT_SPEED

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
