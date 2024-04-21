extends CharacterBody3D

signal interacted_with

var playerIsDead = false

@export var speed = 5.0
@export var runSpeed = 8.0
@export var jumpVelocity = 4.5
@export var mouseSensitivity = 2.0
@export var pullStrength = 100
@export var held_object_rotation_speed = 0.1

@onready var camera = $Node3D/Camera3D
@onready var interactionTimeOut = $InteractionTimer
@onready var eatingSound = $Audio/AudioStreamPlayer
@onready var reelingInSound = $Audio/AudioStreamPlayer2
@onready var catchingSound = $Audio/AudioStreamPlayer3
@onready var walkingSound = $AnimationPlayer

var userInterface = load("res://prefabs/UI.tscn")
var loadUserInterface = userInterface.instantiate()

var waterSplashEmitter = load("res://prefabs/watersplash.tscn")
var loadWaterSplash = waterSplashEmitter.instantiate()

var seenObject = null
var currentTarget = null
var lastTarget = null
var canInteract = false

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
var canReel = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	references.Player = self
	add_child(loadUserInterface)
	
	# Initialize references
	# Load the bob scene
	bobPrefab = preload("res://Prefabs/bob.tscn")
	fishPrefab = preload("res://prefabs/gameobjects/fish/fish_1.tscn")
	# Assuming the rod is a child of the player, get its reference
	rod = $Node3D/Camera3D/Hand3D/FishingRod

func _physics_process(delta):
	
	fishing_sounds()
	playerMovement(delta)
	pickObject()
	interactWithObject()
	move_and_slide()

func playerMovement(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and !playerIsDead:
		velocity.y = jumpVelocity

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and !playerIsDead:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if Input.is_action_pressed("Sprint") and !playerIsDead:
			velocity.x = direction.x * runSpeed
			velocity.z = direction.z * runSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	if Input.is_action_pressed("Sprint"):
		walkingSound.speed_scale = 2
	else:
		walkingSound.speed_scale = 1

	if velocity.x || velocity.z > 100 and is_on_floor():
		walkingSound.play("Walking")
	if !is_on_floor() or velocity.z == 0:
		walkingSound.stop()


func interactWithObject():
	if Input.is_action_pressed("Interact") and !playerIsDead:
		if $Node3D/Camera3D/RayCast3D.is_colliding():
			seenObject = $Node3D/Camera3D/RayCast3D.get_collider()
			if seenObject.is_in_group("Interactable") and canInteract == true:
					seenObject.interacted_with.emit()
					canInteract = false
					interactionTimeOut.start(1)

func pickObject():
	if Input.is_action_pressed("Pickup") and !playerIsDead:
		if $Node3D/Camera3D/RayCast3D.is_colliding():
			seenObject = $Node3D/Camera3D/RayCast3D.get_collider()
			if seenObject.is_in_group("Physics"):
				currentTarget = seenObject
	else:
		currentTarget = null

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

func _input(event):
	if event is InputEventMouseMotion && !playerIsDead:
		rotate_y(-event.relative.x * mouseMath)
		$Node3D.rotate_x(-event.relative.y * mouseMath)
		$Node3D.rotation.x = clamp($Node3D.rotation.x, -1.5, 1.5)
	if Input.is_action_pressed("Crouch"):
			references.CameraPlayer.add_trauma(50)

func _on_interaction_timer_timeout():
	canInteract = true

# Fishing Logic
func _process(delta):
	if Input.is_action_just_pressed("Cast") && bobInstance == null:
		cast()
	if Input.is_action_pressed("ReelIn") && canReel:
		start_reeling()
	if isReeling and bobInstance:
		reel_in(delta)

func cast():
	$ReelTimer.wait_time = randf_range(2.0, 4.0)
	$ReelTimer.start()
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
	
	#Reset color of the bob
	bobInstance.get_child(0).get_active_material(0).albedo_color = Color.RED
	
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

@onready var playingReel = false

func fishing_sounds():
	if isReeling && !playingReel:
		reelingInSound.play()
		playingReel = true
	if !isReeling:
		reelingInSound.stop()
		playingReel = false



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
		var direction_to_bob_after_moving = bobInstance.global_transform.origin - global_transform.origin
		if direction_to_bob_after_moving.length() > direction_to_bob.length():
			reset_fishing()
		# Check if the bob has reached the player's position
		if direction_to_bob.length() < deleteThreshold:
			stop_reeling()
			catch_fish()
			delete_bob()
			canReel = false

func catch_fish():
	if fishInstance:
		if fishInstance.get_parent() != null:
			fishInstance.get_parent().remove_child(fishInstance)
		# Reparent the fish to the player's parent node (or another appropriate node)
		get_parent().add_child(fishInstance)  # Adjust the parent node as needed
		# Set the position of the fish relative to the player's feet
		var player_feet_position = global_transform.origin  # Assuming the player's position is at its feet
		fishInstance.global_transform.origin = player_feet_position + Vector3(0, 2, 0)
		fishInstance.add_to_group("Physics")
		fishInstance.set_linear_velocity(Vector3(0, 0, 0))
		# Perform any additional actions, e.g., increasing player's score
	# Delete the bob
	delete_bob()
	fishInstance = null

func delete_bob():
	if bobInstance:
		bobInstance.remove_child(loadWaterSplash)
		bobInstance.queue_free()
		bobInstance = null

func set_bob_instance(instance):
	bobInstance = instance

func _on_reel_timer_timeout():
	bobInstance.get_child(0).get_active_material(0).albedo_color = Color.GREEN
	bobInstance.add_child(loadWaterSplash)
	canReel = true

func reset_fishing():
	stop_reeling()
	delete_bob()
	canReel = false
	fishInstance = null
