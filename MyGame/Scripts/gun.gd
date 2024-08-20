extends Node3D

@export var Gun_Type : String
@export var Ammo : int
@export var Gun_Ammo : int
@export var Gun_Max : int
@export var Damage : float
#@export var Range : float ?????

func _process(delta: float) -> void:
	if Gun_Type == "Shotgun":
		if Input.is_action_pressed("shoot") and Gun_Ammo > 0:
			$CanvasLayer/AnimatedSprite2D.play("shoot")
			for ray in $Rays.get_children():
				ray.rotation_degrees.x = randf_range(-7,7)
				ray.rotation_degrees.y = randf_range(-5,5)
			for ray in $Rays.get_children():
				if ray.is_colliding():
					if ray.get_collider().is_in_group("Enemy"):
						ray.get_collider().take_damage(Damage)
			anim_fin()
	elif Gun_Type == "M16":
		if Input.is_action_just_pressed("shoot") and Gun_Ammo > 0:
			$CanvasLayer/AnimatedSprite2D.play("shoot")
			if $RayCast3D.is_colliding():
				if $RayCast3D.get_collider().is_in_group("Enemy"):
					$RayCast3D.get_collider().take_damage(Damage)
			anim_fin()
func anim_fin():
	await $CanvasLayer/AnimatedSprite2D.animation_finished
	$CanvasLayer/AnimatedSprite2D.play("idle")
