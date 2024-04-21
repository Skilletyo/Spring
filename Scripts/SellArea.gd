extends Area3D

func _on_body_entered(body):
	if body.is_in_group("Food"):
		references.UI.moneyValue += 1
		$AudioStreamPlayer3D.play()
		body.queue_free()
		print("Fish deleted")
