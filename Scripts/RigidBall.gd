extends RigidBody3D

signal interacted_with

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_interacted_with():
	print("Nom")
	References.UI.hungerValue += 10
