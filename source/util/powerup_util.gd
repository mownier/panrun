
extends Node

const POWERUP = {
	SPEED = 0,
	SHIELD = 1,
	LIGHTNING = 2,
	KNIFE = 3,
	SHURIKEN = 4,
	HEART = 5
}
const POWERUP_SCENES = [
	"speed.scn",
	"shield.scn",
	"lightning.scn",
	"knife.scn",
	"shuriken.scn",
	"heart.scn"
]
const POWERUP_TYPE = [
	"speed",
	"shield",
	"lightning",
	"knife",
	"shuriken",
	"heart"
]
const DIR = "res://source/powerup/triggers/"

func _ready():
	pass

func create_speed():
	return create_powerup(POWERUP["SPEED"])

func create_shield():
	return create_powerup(POWERUP["SHIELD"])

func create_lightning():
	return create_powerup(POWERUP["LIGHTNING"])

func create_knife():
	return create_powerup(POWERUP["KNIFE"])

func create_shuriken():
	return create_powerup(POWERUP["SHURIKEN"])

func create_heart():
	return create_powerup(POWERUP["HEART"])

func create_powerup(type):
	var script = _get_script(type)
	var path = str(DIR, script)
	var powerup = load(path).new()
	powerup.type = type
	return powerup

func _get_script(type):
	if type == POWERUP["SPEED"]:
		return "speed.gd"
	elif type == POWERUP["SHIELD"]:
		return "shield.gd"
	elif type == POWERUP["LIGHTNING"]:
		return "lightning.gd"
	elif type == POWERUP["KNIFE"]:
		return "knife.gd"
	elif type == POWERUP["SHURIKEN"]:
		return "shuriken.gd"
	elif type == POWERUP["HEART"]:
		return "heart.gd"
