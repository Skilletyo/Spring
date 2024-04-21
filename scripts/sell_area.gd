extends Area3D

# DONT DO THIS THIS IS BAD CODE
@onready var end_animation = $"../../EndGameAnimation"
@export var ending_screen: PackedScene

#func _ready():
	#game_completed()

func _on_body_entered(body):
	if body.is_in_group("Food"):
		references.UI.moneyValue += 2
		$AudioStreamPlayer3D.play()
		body.set_collision_layer_value(2, false)
		body.set_collision_mask_value(1, false)
		body.hide()
		references.CameraPlayer.add_trauma(10)
		print("Fish deleted")
		if references.UI.moneyValue >= 10:
			game_completed()
			
func game_completed():
	await get_tree().create_timer(0.1).timeout
	end_animation.play("end_game")
	for i in 20:
		references.CameraPlayer.add_trauma((20 - i) * 0.1)
		$Thump.play()
		await get_tree().create_timer(1).timeout
	#await get_tree().create_timer(20).timeout
	await get_tree().create_timer(2).timeout
	var item = ending_screen.instantiate()
	add_child(item)
	
