extends RigidBody3D

signal interacted_with

@onready var musicPlayer = $AudioStreamPlayer3D
var isPlaying = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


	
func _on_interacted_with():
	if musicPlayer.playing:
		musicPlayer.stop()
	else:
		musicPlayer.play()
	
