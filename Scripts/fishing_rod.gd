extends Node3D

var lure = preload("res://Prefabs/fishing_lure.tscn")

func _process(delta):
	if Input.is_action_pressed("ui_accept"):
		var lureInstance = lure.instantiate()
		add_child(lureInstance)
		lureInstance.apply_central_force(Vector3(20, 20, 20))
