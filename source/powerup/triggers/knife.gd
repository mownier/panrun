
extends "base_trigger.gd"

const KNIFE_STAB_DURATION = 2 # 2 seconds

func activate(player):
	player.emit_signal("will_stab_by_knife", player)

func stab(player):
	player.knife_stab = KNIFE_STAB_DURATION
	player.activate_powerup(KNIFE_STAB_DURATION)