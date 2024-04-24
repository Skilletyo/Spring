extends Area3D

@export var ending_screen: PackedScene

# DONT DO THIS THIS IS BAD CODE
@export var end_animation: AnimationPlayer
@onready var thump_sound = $ThumpSound


# Uncomment for debugging
#func _ready():
	#game_completed()


func _on_body_entered(body):
	if body.is_in_group("Food"):
		references.UI.moneyValue += 1
		$AudioStreamPlayer3D.play()
		body.set_collision_layer_value(2, false)
		body.set_collision_mask_value(1, false)
		body.hide()
		references.CameraPlayer.add_trauma(10)
		print("Fish deleted")
		if references.UI.moneyValue >= 5:
			game_completed()


func game_completed():
	await get_tree().create_timer(0.1).timeout
	end_animation.play("end_game")
	
	# Make sound and shake screen 1 time per second for 20 seconds
	for i in 20:
		var trauma_strength = (20 - i) * 0.1
		references.CameraPlayer.add_trauma(trauma_strength)
		thump_sound.play()
		await get_tree().create_timer(1).timeout
	
	# Display credits
	await get_tree().create_timer(2).timeout
	var ending = ending_screen.instantiate()
	add_child(ending)
	references.UI.visible = false
	references.Player.set_physics_process(false)
	
