
extends "base_trigger.gd"

const SHURIKEN_IMMUNITY_DURATION = 2 # 2 seconds
const SHURIKEN_LINEAR_VELOCITY_X = 1300
const SHURIKEN_HIT_DURATION = 2 # 2 seconds

func activate(player):
	var shuriken_item = _create_item(player.get_pos(), player.move_direction)
	player.emit_signal("will_throw_shuriken", player, shuriken_item)
	player.shuriken_immunity = SHURIKEN_IMMUNITY_DURATION
	player.activate_powerup(SHURIKEN_IMMUNITY_DURATION)

func hit(player):
	player.shuriken_hit = SHURIKEN_HIT_DURATION
	player.activate_powerup(SHURIKEN_HIT_DURATION)

func _create_item(player_position, player_direction):
	var item = load("res://source/powerup/shuriken_item.scn").instance()
	var pos = Vector2(player_position.x, player_position.y - 4)
	var x_dir = SHURIKEN_LINEAR_VELOCITY_X
	if player_direction == 0:
		x_dir = -x_dir
	item.set_pos(pos)
	item.set_linear_velocity(Vector2(x_dir, 0))
	return item