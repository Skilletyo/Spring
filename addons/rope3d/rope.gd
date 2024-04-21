extends Node3D

const RopeScene: PackedScene = preload("res://addons/rope3d/Rope3D.tscn")

@onready var start_point = $RootNode/RopeStartPoint
@onready var end_point = $RootNode/RopeEndPoint


func _ready():
	var rope = RopeScene.instantiate()
	rope.start_point = start_point
	rope.end_point = end_point
	rope.rope_length = 2.5
	rope.resolution = 4.0
	rope.radius = 0.1
	
	var IsValidRope = rope.can_make()
	print(IsValidRope)
	if IsValidRope:
		add_child(rope)
		rope.make()
	
