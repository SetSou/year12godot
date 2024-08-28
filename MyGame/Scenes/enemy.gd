extends CharacterBody3D

@export var health : int

func take_damage(Damage):
	health -= Damage
	print(health)
	if health <= 0:
		self.queue_free()
