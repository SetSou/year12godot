extends Node3D

@export var Gun_Type : String
@export var Ammo : int
@export var Gun_Ammo : int
@export var Gun_Max : int
@export var Damage : float
#@export var Range : float ?????

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot") and Gun_Ammo > 0:
		for ray in $Rays.get_children():
			ray.rotation_degrees.x = randf_range(-5,5)
			ray.rotation_degrees.y = randf_range(-5,5)
		for ray in $Rays.get_children():
			if ray.is_colliding():
				if ray.get_collider().is_in_group("Enemy"):
					ray.get_collider().take_damage(Damage)
			
