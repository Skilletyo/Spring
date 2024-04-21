extends Area3D

@onready var marker = $Marker3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	if body.is_in_group("Player"):
		teleport_player()


func teleport_player():
	references.Player.global_position = marker.global_position
	references.Player.global_rotation = marker.global_rotation
	$AudioStreamPlayer.play()
