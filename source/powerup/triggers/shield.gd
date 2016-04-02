
extends "base_trigger.gd"

const DURATION = 10 # 10 seconds

func activate(player):
	player.shield.set_hidden(false)
	player.activate_powerup(DURATION)