extends Control

@export var hungerValue = 100
@export var healthValue = 100
@export var moneyValue = 0

@onready var hungerTimer = $Hunger/HungerTimer
@onready var hungerLabel = $Hunger/HungerLabel
@onready var healthLabel = $Hunger/HealthLabel
@onready var moneyLabel = $Money/MoneyLabel
@onready var backGround = $ColorRect

@onready var randomGenerator = RandomNumberGenerator.new()

func _ready():
	references.UI = self

func _on_hunger_timer_timeout():
	hungerValue -= 1
	var randomTen = randomGenerator.randf_range(1.0, 10.0)
	hungerTimer.start(randomTen)
	
	checkIfStarving()

func checkIfStarving():
	if hungerValue <= 30:
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
	hungerLabel.text = ("Food: " + str(hungerValue) + "%")
	healthLabel.text = ("Health: " + str(healthValue) + "%")
	moneyLabel.text = ("Sacrifices: " + str(moneyValue))

@onready var deathMessageShown = false

func gameOver():
	if healthValue == 0 and !deathMessageShown:
		add_child(loadGameOver)
		references.Player.playerIsDead = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		hungerLabel.hide()
		healthLabel.hide()
		moneyLabel.hide()
		backGround.hide()
		deathMessageShown = true

@onready var mouseIsShown = false

func _input(_event):
	if Input.is_action_just_pressed("Escape") and !mouseIsShown:
		mouseIsShown = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif Input.is_action_just_pressed("Escape") and mouseIsShown:
		mouseIsShown = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


var gameOverScreen = load("res://prefabs/gameover_screen.tscn")
var loadGameOver = gameOverScreen.instantiate()

func _process(_delta):
	gameOver()
	clampValues()
	drawLabels()
