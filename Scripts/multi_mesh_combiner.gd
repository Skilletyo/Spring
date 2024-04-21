@tool
extends MultiMeshInstance3D

@export_category("Debug")
@export var Convert: bool:
	set(value):
		convert_meshes()
@export var MeshToCopy: Mesh

func convert_meshes():
	multimesh.mesh = MeshToCopy
	var children:Array = $"..".get_children(true)
	multimesh.instance_count = children.size() - 1
	#print(children.size())
	var i = 0
	for child in children:
		print(child)
		if child == self:
			continue
			#print("self")
		multimesh.set_instance_transform(i,child.global_transform)
		child.visible = false
		i+=1
	print("Converted")
	global_position = Vector3.ZERO
	global_scale(Vector3.ONE)
	global_rotation = Vector3.ZERO
