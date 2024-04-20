extends RigidBody3D

signal interacted_with


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_interacted_with():
	references.UI.hungerValue += 25
	references.Player.eatingSound.play()
