extends Node3D

@export var player: Node3D

@export var respawnPoint: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player.global_position.y < -10:
		player.global_position = respawnPoint.global_position
	
