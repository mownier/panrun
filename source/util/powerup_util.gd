
extends Node

const POWERUP = {
	SPEED = 0,
	SHIELD = 1,
	LIGHTNING = 2,
	KNIFE = 3,
	SHURIKEN = 4,
	HEART = 5
}
const DIR = "res://source/powerup/models/"

func _ready():
	pass

func create_speed():
	var powerup = create_powerup("speed.gd")
	powerup.type = POWERUP["SPEED"]
	return powerup

func create_shield():
	var powerup = create_powerup("shield.gd")
	powerup.type = POWERUP["SHIELD"]
	return powerup

func create_lightning():
	var powerup = create_powerup("lightning.gd")
	powerup.type = POWERUP["LIGHTNING"]
	return powerup

func create_knife():
	var powerup = create_powerup("knife.gd")
	powerup.type = POWERUP["KNIFE"]
	return powerup

func create_shuriken():
	var powerup = create_powerup("shuriken.gd")
	powerup.type = POWERUP["SHURIKEN"]
	return powerup

func create_heart():
	var powerup = create_heart("heart.gd")
	powerup.type = POWERUP["HEART"]
	return powerup

func create_powerup(script):
	var path = str(DIR, script)
	var powerup = load(path).new()
	return powerup
