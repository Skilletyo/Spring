extends Control

@export var hungerValue = 100
@export var healthValue = 100

@onready var hungerTimer = $Hunger/HungerTimer
@onready var hungerLabel = $Hunger/HungerLabel
@onready var healthLabel = $Hunger/HealthLabel
@onready var randomGenerator = RandomNumberGenerator.new()

func _ready():
	pass

func _on_hunger_timer_timeout():
	hungerValue -= 1
	var randomTen = randomGenerator.randf_range(1.0, 10.0)
	hungerTimer.start(randomTen)
	
	checkIfStarving()

func checkIfStarving():
	if hungerValue <= 30:
		$StarvingLabel.show()
		healthValue -= 2

func drawLabels():
	hungerLabel.text = ("Hunger: " + str(hungerValue) + "%")
	healthLabel.text = ("Health: " + str(healthValue) + "%")

func _process(delta):
	drawLabels()
