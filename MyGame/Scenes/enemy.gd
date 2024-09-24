extends CharacterBody3D

var gravity = 9.8
@export var health : int

func take_damage(Damage):
	health -= Damage
	print(health)
	if health <= 0:
		self.queue_free()
func _process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
