@tool
extends MeshInstance3D
class_name LineRenderer3D

@export_category("Update Render (Editor Only)")
##Pressing this will update the mesh. This include position, properties and materials.
@export var update: bool = true

@export_category("Line Points")
@export var points: Array[Vector3]

@export_category("Line Properties")
@export var startThickness = 0.1
@export var endThickness = 0.1
@export var cornerSmooth = 5
@export var capSmooth = 5
@export var drawCaps = true
@export var drawCorners = true
@export var globalCoords = true
@export var scaleTexture = true

@export_category("Line Material")
@export var lineMaterial: StandardMaterial3D

var geometry: ImmediateMesh
var camera
var cameraOrigin

func _ready():
	pass

func _process(delta):
	
	# This tool script is laggy in editor, users can preview changes by pressing this.
	if update and Engine.is_editor_hint():
		return
	
	if points.size() < 2:
		push_warning('In order for line to render, there needs to be 2 or more points.')
		update = true
		return
		
	update = true
	
	if Engine.is_editor_hint():
		camera = get_editor_camera()
	else:
		camera = get_viewport().get_camera_3d()
	
	if camera == null:
		return
	cameraOrigin = to_local(camera.get_global_transform().origin)
	
	var progressStep = 1.0 / points.size();
	var progress = 0;
	var thickness = lerp(startThickness, endThickness, progress);
	var nextThickness = lerp(startThickness, endThickness, progress + progressStep);
	
	geometry = ImmediateMesh.new()
	
	geometry.clear_surfaces()
	geometry.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(points.size() - 1):
		var A = points[i]
		var B = points[i+1]
	
		if globalCoords:
			A = to_local(A)
			B = to_local(B)
	
		var AB = B - A;
		var orthogonalABStart = (cameraOrigin - ((A + B) / 2)).cross(AB).normalized() * thickness;
		var orthogonalABEnd = (cameraOrigin - ((A + B) / 2)).cross(AB).normalized() * nextThickness;
		
		var AtoABStart = A + orthogonalABStart
		var AfromABStart = A - orthogonalABStart
		var BtoABEnd = B + orthogonalABEnd
		var BfromABEnd = B - orthogonalABEnd
		
		if i == 0:
			if drawCaps:
				cap(A, B, thickness, capSmooth)
		
		if scaleTexture:
			var ABLen = AB.length()
			var ABFloor = floor(ABLen)
			var ABFrac = ABLen - ABFloor
			
			geometry.surface_set_uv(Vector2(ABFloor, 0))
			geometry.surface_add_vertex(AtoABStart)
			geometry.surface_set_uv(Vector2(-ABFrac, 0))
			geometry.surface_add_vertex(BtoABEnd)
			geometry.surface_set_uv(Vector2(ABFloor, 1))
			geometry.surface_add_vertex(AfromABStart)
			geometry.surface_set_uv(Vector2(-ABFrac, 0))
			geometry.surface_add_vertex(BtoABEnd)
			geometry.surface_set_uv(Vector2(-ABFrac, 1))
			geometry.surface_add_vertex(BfromABEnd)
			geometry.surface_set_uv(Vector2(ABFloor, 1))
			geometry.surface_add_vertex(AfromABStart)
		else:
			geometry.surface_set_uv(Vector2(1, 0))
			geometry.surface_add_vertex(AtoABStart)
			geometry.surface_set_uv(Vector2(0, 0))
			geometry.surface_add_vertex(BtoABEnd)
			geometry.surface_set_uv(Vector2(1, 1))
			geometry.surface_add_vertex(AfromABStart)
			geometry.surface_set_uv(Vector2(0, 0))
			geometry.surface_add_vertex(BtoABEnd)
			geometry.surface_set_uv(Vector2(0, 1))
			geometry.surface_add_vertex(BfromABEnd)
			geometry.surface_set_uv(Vector2(1, 1))
			geometry.surface_add_vertex(AfromABStart)
		
		if i == points.size() - 2:
			if drawCaps:
				cap(B, A, nextThickness, capSmooth)
		else:
			if drawCorners:
				var C = points[i+2]
				if globalCoords:
					C = to_local(C)
				
				var BC = C - B;
				var orthogonalBCStart = (cameraOrigin - ((B + C) / 2)).cross(BC).normalized() * nextThickness;
				
				var angleDot = AB.dot(orthogonalBCStart)
				
				if angleDot > 0:
					corner(B, BtoABEnd, B + orthogonalBCStart, cornerSmooth)
				else:
					corner(B, B - orthogonalBCStart, BfromABEnd, cornerSmooth)
		
		progress += progressStep;
		thickness = lerp(startThickness, endThickness, progress);
		nextThickness = lerp(startThickness, endThickness, progress + progressStep);
	
	geometry.surface_end()
	geometry.surface_set_material(0, lineMaterial)
	mesh = geometry

func find_editor_cameras(nodes: Array, cameras: Array) -> void:	
	for child in nodes:
		find_editor_cameras(child.get_children(), cameras)
		if child is Camera3D:
			cameras.push_back(child)

func get_editor_cameras() -> Array[Camera3D]:
	
	# EditorScript as Variant to stop game from crashing when running.
	var ei = (EditorScript as Variant).new().get_editor_interface()
	var cameras: Array[Camera3D]
	find_editor_cameras(ei.get_editor_main_screen().get_children(), cameras)
	return cameras

func get_editor_camera():
	var editor_cameras: Array[Camera3D]
	return get_editor_cameras()[0]

func cap(center, pivot, thickness, smoothing: float):
	var orthogonal = (cameraOrigin - center).cross(center - pivot).normalized() * thickness;
	var axis: Vector3 = (center - cameraOrigin).normalized();
	
	var array = []
	for i in range(smoothing + 1):
		array.append(Vector3(0,0,0))
	array[0] = center + orthogonal;
	array[smoothing] = center - orthogonal;
	
	for i in range(1, smoothing):
		array[i] = center + (orthogonal.rotated(axis, lerp(0.0, PI, float(i / smoothing))));
	
	for i in range(1, smoothing + 1):
		geometry.surface_set_uv(Vector2(0, (i - 1) / smoothing))
		geometry.surface_add_vertex(array[i - 1]);
		geometry.surface_set_uv(Vector2(0, (i - 1) / smoothing))
		geometry.surface_add_vertex(array[i]);
		geometry.surface_set_uv(Vector2(0.5, 0.5))
		geometry.surface_add_vertex(center);
		
func corner(center, start, end, smoothing):
	var array = []
	for i in range(smoothing + 1):
		array.append(Vector3(0,0,0))
	array[0] = start;
	array[smoothing] = end;
	
	var axis = start.cross(end).normalized()
	var offset = start - center
	var angle = offset.angle_to(end - center)
	
	for i in range(1, smoothing):
		array[i] = center + offset.rotated(axis, lerp(0, angle, float(i) / smoothing));
	
	for i in range(1, smoothing + 1):
		geometry.surface_set_uv(Vector2(0, (i - 1) / smoothing))
		geometry.surface_add_vertex(array[i - 1]);
		geometry.surface_set_uv(Vector2(0, (i - 1) / smoothing))
		geometry.surface_add_vertex(array[i]);
		geometry.surface_set_uv(Vector2(0.5, 0.5))
		geometry.surface_add_vertex(center);
