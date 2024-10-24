extends CharacterBody3D

@onready var navigation = $NavigationAgent3D
@onready var raycast = $RayCast3D
@onready var mesh = $enemy
@onready var sprite_3d = $Model/AnimatedSprite3D

@export var SPEED : int = 2
@export var HEALTH : int = 100
@export var shoot_range : int = 17
@export var min_shoot_time : float = 0
@export var max_shoot_time : float = 2
@export var attack_range : int = 2

@onready var player : CharacterBody3D = get_tree().get_first_node_in_group("player")
var dead = false

#enum STATES {
	#moving,
	#idle_shoot,
	#idle,
	#shooting
#}
#var current_state = STATES.idle
#var spotted_player = false

func _ready():
	for i in get_parent().get_parent().get_children():
		if i.is_in_group("player"):
			navigation.target_position = i.global_position
			player = i


#func move(delta):
	#if spotted_player:
		#set_state(STATES.moving)
		#navigation.target_position = player.global_position
		#velocity = (navigation.get_next_path_position() - self.global_position).normalized() * (SPEED * 30) * delta
	#else:
		#set_state(STATES.idle)
#
#
#func set_state(state, override=false):
	#if not current_state == STATES.shooting or override:
		#current_state = state
#

func _physics_process(delta):
	if dead:
		return
	if player == null:
		return
		
	var dir = player.global_position - global_position
	dir.y = 0.0
	dir = dir.normalized()
	
	velocity = dir * SPEED
	#raycast.global_position = global_position
	#raycast.target_position = player.global_position - global_position
	#

	#if raycast.is_colliding() and is_instance_valid(raycast.get_collider()):
		#if raycast.get_collider().is_in_group("player"):
			#spotted_player = true
			#$Aim.look_at(raycast.get_collider().global_position, Vector3.UP, true)
			#if raycast.global_transform.origin.distance_to(raycast.get_collision_point()) < shoot_range:
				#velocity = Vector3(0, 0, 0)
				#set_state(STATES.idle_shoot)
			#else:
				#move(delta)
		#else:
			#move(delta)
	#else:
		#move(delta)
	attack()
	move_and_slide()


#func _process(delta):
	#pass
	#match current_state:
		#STATES.idle_shoot:
			#$enemy/AnimationPlayer.play("idle")
		#STATES.idle:
			#$enemy/AnimationPlayer.play("idle")
		#STATES.moving:
			#$enemy/AnimationPlayer.play("walk")
		#STATES.shooting:
			#$enemy/AnimationPlayer.play("shoot")
	#if abs(velocity) > Vector3(1, 1, 1):
		#if not $Footsteps.playing:
			#$Footsteps.play()
	#else:
		#$Footsteps.stop()
#
func attack():
	var dist_to_player = global_position.distance_to(player.global_position)
	if dist_to_player > attack_range:
		return
		
	var eye_line = Vector3.UP * 1.5
	var query = PhysicsRayQueryParameters3D.create(global_position+eye_line, player.global_position+eye_line, 1)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	print("Hehe")
	if result.is_empty():
		print("HELP")
		player.kill()

func take_damage(Damage):
	HEALTH -= Damage
	print(HEALTH)
	if HEALTH <= 0:
		kill()

func kill():
	dead = true
	$Death.play
	sprite_3d.play("death")
	$CollisionShape3D.disabled = true
