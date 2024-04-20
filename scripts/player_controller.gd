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

var userInterface = load("res://prefabs/UI.tscn")
var loadUserInterface = userInterface.instantiate()

var seenObject = null
var currentTarget = null
var lastTarget = null
var canInteract = false

var mouseMath = (mouseSensitivity) / 1000

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	references.Player = self
	add_child(loadUserInterface)

func _physics_process(delta):
	
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

func interactWithObject():
	if Input.is_action_pressed("Interact") and !playerIsDead:
		print("Interact pressed")
		if $Node3D/Camera3D/RayCast3D.is_colliding():
			seenObject = $Node3D/Camera3D/RayCast3D.get_collider()
			print("Got collider")
			if seenObject.is_in_group("Interactable") and canInteract == true:
					seenObject.interacted_with.emit()
					canInteract = false
					interactionTimeOut.start(1)
					print("Sent interaction signal")

func pickObject():
	if Input.is_action_pressed("Pickup") and !playerIsDead:
		if $Node3D/Camera3D/RayCast3D.is_colliding():
			seenObject = $Node3D/Camera3D/RayCast3D.get_collider()
			if seenObject.is_in_group("Physics"):
				currentTarget = seenObject
				print("Applying force...")
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

func _on_interaction_timer_timeout():
	canInteract = true