extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	references.Globals = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#func lazyRemove():
#	set_collision_layer_value(2, false)
#	set_collision_mask_value(1, false)
#	hide()
