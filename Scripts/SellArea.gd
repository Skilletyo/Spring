extends Area3D

# DONT DO THIS THIS IS BAD CODE
@onready var end_animation = $"../../EndGameAnimation"
@export var ending_screen: PackedScene

func _on_body_entered(body):
	if body.is_in_group("Food"):
		references.UI.moneyValue += 1
		$AudioStreamPlayer3D.play()
		body.queue_free()
		print("Fish deleted")
		if references.UI.moneyValue >= 10:
			game_completed()
			
func game_completed():
	end_animation.play("end_game")
	await get_tree().create_timer(22).timeout
	var item = ending_screen.instantiate()
	add_child(item)
	
	
	
