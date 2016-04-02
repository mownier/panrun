
extends "base_trigger.gd"

const LIGHTNING_SHOCK_DURATION = 2 # 2 seconds

func activate(player):
	player.emit_signal("will_cast_lightning", player)

func shock(player):
	player.lightning_shock = LIGHTNING_SHOCK_DURATION
	player.activate_powerup(LIGHTNING_SHOCK_DURATION)