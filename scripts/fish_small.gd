extends RigidBody3D

signal interacted_with

@onready var collisionObject = $CollisionShape3D

func _on_interacted_with():
	references.UI.hungerValue += 25
	references.Player.eatingSound.play()
	set_collision_layer_value(2, false)
	set_collision_mask_value(1, false)
	hide()
