
extends KinematicBody2D

signal did_consume_powerup(player, type)
signal will_throw_shuriken(player, shuriken)
signal will_cast_lightning(player)
signal will_stab_by_knife(player)

const GRAVITY = 500
const WALK_SPEED_MIN = 10
const WALK_SPEED_MAX = 500

const STOP_FORCE = 1400
const WALK_FORCE = 600
const JUMP_SPEED = 500
const AIRBORNE_TIME_MAX = 0.2
const FLOOR_ANGLE_TOLERANCE = 30

const SLIDE_TOP_MIN_DISTANCE = 1
const SLIDE_TOP_VELOCITY = 1

const GHOST_OPACITY = 0.5
const GHOST_DURATION = 4 # 4 seconds

const LIGHTNING_SHOCK_DURATION = 2 # 2 seconds
const KNIFE_STAB_DURATION = 2 # 2 seconds
const POWERUP_SPEED_DURATION = 10 # 10 seconds
const POWERUP_SPEED = 1200 # 1300 pix/sec
const POWERUP_HEART_DURATION = 20 # 20 seconds
const POWERUP_SHIELD_DURATION = 10 # 10 seconds 
const SHURIKEN_IMMUNITY_DURATION = 2 # 2 seconds
const SHURIKEN_LINEAR_VELOCITY_X = 1300
const SHURIKEN_HIT_DURATION = 2 # 2 seconds

var velocity = Vector2()
var jumping = false
var prev_jump_pressed = false
var airborne_time = 0

var powerup_speed = 0
var powerup_type = -1
var move_direction = 1 # 0 if left, 1 if right
var shuriken_immunity = 0 # 0 seconds
var shuriken_hit = 0 # 0 seconds
var ghost_duration = 0 # 0 seconds
var lightning_shock = 0 # Lightning shock in seconds
var knife_stab = 0 # Knife stab in seconds

const POWERUP_LIMIT = 1

onready var powerup_timer = get_node("powerup_timer")
onready var ghost_timer = get_node("ghost_timer")

func _ready():
	powerup_timer.connect("timeout", self, "_on_powerup_timeout")
	ghost_timer.connect("timeout", self, "_on_ghost_timeout")
	set_fixed_process(true)
	set_process_input(true)

func _input(event):
	if _has_powerup() and event.is_action_pressed("powerup"):
		powerup_timer.stop()
		_on_powerup_timeout()
		_consume_powerup()

func _fixed_process(delta):
#	_motion_1(delta)
	_motion_2(delta)

func is_main_player():
	return get_name() == "player1"

func _consume_powerup():
	if powerup_type == 0:
		activate_speed()
	elif powerup_type == 1:
		activate_shield()
	elif powerup_type == 2:
		activate_lightning()
	elif powerup_type == 3:
		activate_knife()
	elif powerup_type == 4:
		activate_shuriken()
	elif powerup_type == 5:
		activate_heart()
	emit_signal("did_consume_powerup", self, powerup_type)
	powerup_type = -1

func _has_powerup():
	return powerup_type > -1

func has_powerups():
	return get_powerups().size() > 0

func add_powerup(powerup):
	if get_powerups().size() < POWERUP_LIMIT:
		powerup.add_to_group("player_powerups")
		add_child(powerup)

func get_powerups():
	return get_tree().get_nodes_in_group("player_powerups")

func activate_powerup(duration):
	powerup_timer.set_wait_time(duration)
	powerup_timer.start()

func activate_speed():
	powerup_speed = POWERUP_SPEED
	activate_powerup(POWERUP_SPEED_DURATION)

func activate_shield():
	get_node("shield").set_hidden(false)
	activate_powerup(POWERUP_SHIELD_DURATION)

func activate_lightning():
	emit_signal("will_cast_lightning", self)

func activate_shuriken():
	var shuriken = load("res://source/powerup/shuriken_item.scn").instance()
	var pos = Vector2(get_pos().x, get_pos().y - 4)
	var x_dir = SHURIKEN_LINEAR_VELOCITY_X
	if move_direction == 0:
		x_dir = -x_dir
	shuriken.set_pos(pos)
	shuriken.set_linear_velocity(Vector2(x_dir, 0))
	emit_signal("will_throw_shuriken", self, shuriken)
	shuriken_immunity = SHURIKEN_IMMUNITY_DURATION
	activate_powerup(shuriken_immunity)

func activate_knife():
	emit_signal("will_stab_by_knife", self)

func activate_heart():
	get_node("heart").set_hidden(false)
	activate_powerup(POWERUP_HEART_DURATION)

func activate_ghost():
	set_opacity(GHOST_OPACITY)
	ghost_duration = GHOST_DURATION
	ghost_timer.set_wait_time(ghost_duration)
	ghost_timer.start()

func has_active_shield():
	return not get_node("shield").is_hidden()

func has_active_heart():
	return not get_node("heart").is_hidden()

func has_shuriken_immunity():
	return shuriken_immunity > 0

func is_ghost():
	return ghost_duration > 0

func has_immunity():
	return (is_ghost() or
		has_active_shield() or
		has_active_heart())

func has_hit_by_shuriken():
	return shuriken_hit > 0

func has_acquired_lightning_shock():
	return lightning_shock > 0

func has_stabbed_with_knife():
	return knife_stab > 0

func deactivate_heart():
	powerup_timer.stop()
	get_node("heart").set_hidden(true)

func on_shuriken_hit():
	if not has_immunity() and not has_shuriken_immunity():
		activate_ghost()
		shuriken_hit = SHURIKEN_HIT_DURATION
		activate_powerup(shuriken_hit)
	else:
		if has_active_heart():
			deactivate_heart()

func on_lightning_strike():
	if not has_immunity() and not has_acquired_lightning_shock():
		activate_ghost()
		lightning_shock = LIGHTNING_SHOCK_DURATION
		activate_powerup(lightning_shock)
	else:
		if has_active_heart():
			deactivate_heart()

func on_knife_stab():
	if not has_immunity() and not has_stabbed_with_knife():
		activate_ghost()
		knife_stab = KNIFE_STAB_DURATION
		activate_powerup(knife_stab)
	else:
		if has_active_heart():
			deactivate_heart()

func brute_force_stop():
	return (has_acquired_lightning_shock() or 
		has_stabbed_with_knife() or 
		has_hit_by_shuriken())

func exempt_from_shuriken_collision(shuriken):
	shuriken.add_collision_exception_with(self)

func exempt_from_player_collision(objects):
	for object in objects:
		if object != self:
			add_collision_exception_with(object)

func _on_powerup_timeout():
	powerup_speed = 0
	shuriken_immunity = 0
	lightning_shock = 0
	knife_stab = 0
	shuriken_hit = 0
	
	get_node("shield").set_hidden(true)
	get_node("heart").set_hidden(true)

func _on_ghost_timeout():
	set_opacity(1)
	ghost_duration = 0

func _motion_2(delta):
	var force = Vector2(0, GRAVITY)
	
	var did_press_left = not brute_force_stop() and is_main_player() and Input.is_action_pressed("ui_left")
	var did_press_right = not brute_force_stop() and is_main_player() and Input.is_action_pressed("ui_right")
	var did_press_jump = not brute_force_stop() and is_main_player() and Input.is_action_pressed("jump") 
	
	var stop = true
	
	var speed_min = max(WALK_SPEED_MIN, powerup_speed)
	var speed_max = max(WALK_SPEED_MAX, powerup_speed)
	
	if (did_press_left):
		if (velocity.x < speed_min and velocity.x > -speed_max):
			force.x -= WALK_FORCE
			stop = false
			move_direction = 0
	elif (did_press_right):
		if (velocity.x > -speed_min and velocity.x < speed_max):
			force.x += WALK_FORCE
			stop = false
			move_direction = 1
	
	if (stop):
		var walk_direction = sign(velocity.x)
		var walk_distance = abs(velocity.x)
		walk_distance = max(0, walk_distance - (STOP_FORCE * delta))
		velocity.x = walk_direction * walk_distance
	
	velocity += force * delta
	var motion = velocity * delta
	motion = move(motion)
	
	var floor_velocity = Vector2()
	
	if (is_colliding()):
		var normal = get_collision_normal()
		if (rad2deg(acos(normal.dot(Vector2(0, -1)))) < FLOOR_ANGLE_TOLERANCE):
			airborne_time = 0
			floor_velocity = get_collider_velocity()
		if (airborne_time == 0 and force.x == 0 and get_travel().length() < SLIDE_TOP_MIN_DISTANCE and abs(velocity.x) < SLIDE_TOP_VELOCITY and get_collider_velocity() == Vector2()):
			revert_motion()
			velocity.y = 0
		else:
			motion = normal.slide(motion)
			velocity = normal.slide(velocity)
			move(motion)
	
	if (floor_velocity != Vector2()):
		move(floor_velocity * delta)
	
	if (jumping and velocity.y > 0):
		jumping = false
	
	if (airborne_time < AIRBORNE_TIME_MAX and did_press_jump and not prev_jump_pressed and not jumping):
		velocity.y = -JUMP_SPEED
		jumping = true
	
	airborne_time += delta
	prev_jump_pressed = did_press_jump

func _motion_1(delta):
	velocity.y += delta * GRAVITY
	if (Input.is_action_pressed("ui_left")):
		velocity.x = min(WALK_SPEED_MIN, velocity.x - WALK_SPEED_MIN)
	elif (Input.is_action_pressed("ui_right")):
		velocity.x = max(WALK_SPEED_MAX, velocity.x + WALK_SPEED_MIN)
	else:
		velocity.x = 0
	var motion = velocity * delta
	motion = move(motion)
	if (is_colliding()):
		var normal = get_collision_normal()
		motion = normal.slide(motion)
		velocity = normal.slide(velocity)
		move(motion)