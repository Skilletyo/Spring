extends CharacterBody3D

signal interacted_with

@export var speed = 5.0
@export var runSpeed = 8.0
@export var jumpVelocity = 4.5
@export var mouseSensitivity = 2.0
@export var pullStrength = 100
@export var held_object_rotation_speed = 0.1

@onready var camera = $Node3D/Camera3D

var userInterface = load("res://Prefabs/UI.tscn")
var loadUserInterface = userInterface.instantiate()

#Stuff for the pickup system.

var seenObject = null
var currentTarget = null
var lastTarget = null

var mouseMath = (mouseSensitivity) / 1000

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Fishing variables
var bobPrefab # Reference to the bob scene
var castForce = 25 # Adjust this to control the force of the cast
var rod # Reference to the rod node

var bobInstance = null # Reference to the bob instance
var fishInstance # Reference to the attached fish instance
var fishPrefab
var reelSpeed = 10.0 # Adjust this value to control the speed of reeling
var deleteThreshold = 1.0 # Adjust this value to set the threshold distance for deleting the bob
var isReeling = false # Flag to track if the player is reeling in

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	#Loads the user interface
	References.Player = self
	
	add_child(loadUserInterface)
	
# Initialize references
	# Load the bob scene
	bobPrefab = preload("res://Prefabs/bob.tscn")
	fishPrefab = preload("res://Prefabs/fish.tscn")
	# Assuming the rod is a child of the player, get its reference
	rod = $Node3D/Camera3D/Hand3D/FishingRod

func _physics_process(delta):

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_pressed("Pickup"):
		if $Node3D/Camera3D/RayCast3D.is_colliding():
			seenObject = $Node3D/Camera3D/RayCast3D.get_collider()
			if seenObject.is_in_group("Physics"):
				currentTarget = seenObject
	else:
		currentTarget = null

	if Input.is_action_pressed("Interact"):
		if $Node3D/Camera3D/RayCast3D.is_colliding():
			seenObject = $Node3D/Camera3D/RayCast3D.get_collider()
			if seenObject.is_in_group("Interactable"):
				seenObject.interacted_with.emit()


	if currentTarget != null:
		currentTarget.linear_damp = 10
		currentTarget.angular_damp = 10
		currentTarget.can_sleep = false
		var moveToPosition = $Node3D/Camera3D/Hand3D.global_position - currentTarget.global_position
		currentTarget.apply_force(moveToPosition * pullStrength)
		# Lerp rotation on 3 axies
		currentTarget.global_rotation.x = lerp_angle(currentTarget.global_rotation.x, camera.global_rotation.x, held_object_rotation_speed)
		currentTarget.global_rotation.y = lerp_angle(currentTarget.global_rotation.y, camera.global_rotation.y, held_object_rotation_speed)
		currentTarget.global_rotation.z = lerp_angle(currentTarget.global_rotation.z, camera.global_rotation.z, held_object_rotation_speed)
		lastTarget = currentTarget

	if currentTarget == null && lastTarget != null:
		lastTarget.can_sleep = true
		lastTarget.linear_damp = 0
		lastTarget.linear_damp = 0


	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jumpVelocity

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if Input.is_action_pressed("Sprint"):
			velocity.x = direction.x * runSpeed
			velocity.z = direction.z * runSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouseMath)
		$Node3D.rotate_x(-event.relative.y * mouseMath)
		$Node3D.rotation.x = clamp($Node3D.rotation.x, -1.5, 1.5)

# Fishing Logic
func _process(delta):
	if Input.is_action_just_pressed("Cast") && bobInstance == null:
		cast()
	if Input.is_action_pressed("ReelIn"):
		start_reeling()
	if isReeling and bobInstance:
		reel_in(delta)

func cast():
	# Instantiate the bob scene
	var bob = bobPrefab.instantiate()
	get_parent().add_child(bob) # Add the bob to the player's parent node
	
	# Set the bob's initial position relative to the player's forward direction
	var spawnDistance = 2.0 # Adjust this value to set the distance from the player
	var spawnOffset = global_transform.basis.x.normalized() * 0.5 # Adjust the offset to move the bob to the right
	var spawnPosition = global_transform.origin + global_transform.basis.z.normalized() * spawnDistance + spawnOffset
	bob.global_transform.origin = spawnPosition
	
	# Store reference to the bob instance
	set_bob_instance(bob)

	# Get the direction the rod is facing
	var direction = -global_transform.basis.z.normalized()
	
	# Calculate the straight-line force
	var straightForce = direction * castForce
	
	# Calculate the upward force based on the angle of the rod
	var rodUpwardAngle = clamp(global_transform.basis.y.angle_to(Vector3.UP), 0, PI/2) # Angle between player's upward direction and global upward direction
	var upwardForce = Vector3(0, sin(rodUpwardAngle), cos(rodUpwardAngle)) * castForce * 0.5 # Apply half of the force upward
	
	# Combine the straight and upward forces
	var totalForce = straightForce + upwardForce
	
	# Apply the combined force to the bob
	bob.apply_central_impulse(totalForce)


func start_reeling():
	isReeling = true
	if bobInstance and not fishInstance:
		attach_fish()

func stop_reeling():
	isReeling = false

func attach_fish():
	# Spawn fish and attach it to the bob
	var fish = fishPrefab.instantiate()
	bobInstance.add_child(fish)
	fishInstance = fish

func reel_in(delta):
	if bobInstance:
		var direction_to_bob = bobInstance.global_transform.origin - global_transform.origin
		bobInstance.translate(-direction_to_bob.normalized() * reelSpeed * delta)
		
		# Check if the bob has reached the player's position
		if direction_to_bob.length() < deleteThreshold:
			stop_reeling()
			catch_fish()
			delete_bob()

func catch_fish():
	if fishInstance:
		if fishInstance.get_parent() != null:
			fishInstance.get_parent().remove_child(fishInstance)
		# Reparent the fish to another node or the player
		# For example, reparent to the player's parent node
		get_parent().add_child(fishInstance)
		# Perform any additional actions, e.g., increasing player's score
		fishInstance.global_transform.origin = Vector3(0, 1, 0)  # Adjust the position as needed
	# Delete the bob
	fishInstance = null

func delete_bob():
	if bobInstance:
		bobInstance.queue_free()
		bobInstance = null

func set_bob_instance(instance):
	bobInstance = instance


