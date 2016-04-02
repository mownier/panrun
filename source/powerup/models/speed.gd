
extends "base_powerup.gd"

const DURATION = 10 # 10 seconds
const SPEED = 1200 # 1200 pix/sec

func _ready():
	var name = str("speed_", self)
	set_name(name)

func activate(player):
	player.powerup_speed = SPEED
	player.activate_powerup(DURATION)