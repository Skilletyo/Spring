extends Control

@export var hungerValue = 100
@export var healthValue = 100

@onready var hungerTimer = $Hunger/HungerTimer
@onready var hungerLabel = $Hunger/HungerLabel
@onready var healthLabel = $Hunger/HealthLabel

@onready var randomGenerator = RandomNumberGenerator.new()

func _ready():
	References.UI = self

func _on_hunger_timer_timeout():
	hungerValue -= 1
	var randomTen = randomGenerator.randf_range(1.0, 10.0)
	hungerTimer.start(randomTen)
	
	checkIfStarving()

func checkIfStarving():
	if hungerValue <= 30:
		$Hunger/StarvingLabel.show()
		healthValue -= 2

func clampValues():
	if hungerValue > 100:
		hungerValue = 100
	if hungerValue < 0:
		hungerValue = 0
	if healthValue > 100:
		healthValue = 100
	if healthValue < 0:
		healthValue = 0

func drawLabels():
	hungerLabel.text = ("Hunger: " + str(hungerValue) + "%")
	healthLabel.text = ("Health: " + str(healthValue) + "%")

func _process(delta):
	clampValues()
	drawLabels()
