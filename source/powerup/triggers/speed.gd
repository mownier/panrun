
extends "base_trigger.gd"

const DURATION = 10 # 10 seconds
const SPEED = 1200 # 1200 pix/sec

func activate(player):
	player.powerup_speed = SPEED
	player.activate_powerup(DURATION)