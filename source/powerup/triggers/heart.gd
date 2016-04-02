
extends "base_trigger.gd"

const POWERUP_HEART_DURATION = 20 # 20 seconds

func activate(player):
	player.heart.set_hidden(false)
	player.activate_powerup(POWERUP_HEART_DURATION)