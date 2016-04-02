tool 

extends Node2D

const POWERUPS = ["speed.scn", "shield.scn", "lightning.scn", "knife.scn", "shuriken.scn", "heart.scn"]

onready var powerup = get_node("hud/powerup")
onready var powerup_container = powerup.get_node("container")
onready var player_indicator = get_node("hud2/player_indicator")
onready var target_selector = get_node("target_selector")

onready var globals = get_node("/root/globals")

var player_scene = preload("res://source/player/player.scn")

func _ready():
	var map_scene = load("res://source/map/map_2.scn")
	var map = map_scene.instance()
	map.connect("did_collect", self, "_did_collect_powerup")
	add_child(map)
	
	_create_players(4)
	var players = get_tree().get_nodes_in_group("players")
	get_tree().call_group(0, "players", "exempt_from_player_collision", players)
	
	_create_hud_players(players)
	
	powerup_container.get_child(0).queue_free()
	powerup_container.set_color(Color("ffffff"))
	
	target_selector.connect("on_target_select", self, "_on_target_select")
	
	# TEST: Powerup creations
	var speed = globals.powerup_util.create_speed()
	add_child(speed)
	speed.activate()

func _create_players(count):
	for i in range(count):
		var player = _create_player()
		var spacing = 8
		var size = _get_player_size(player)
		var x = 72 + (size.x * i) + (spacing * i)
		var pos = Vector2(x, 0)
		player.set_pos(pos)
		player.set_name(str("player", i + 1))
		player.add_to_group("players")
		if i > 0:
			player.add_to_group("enemies")
			player.remove_child(player.get_node("camera"))
		add_child(player)

func _create_player():
	var player = player_scene.instance()
	player.connect("did_consume_powerup", self, "_did_consume_powerup")
	player.connect("will_throw_shuriken", self, "_will_throw_shuriken")
	player.connect("will_cast_lightning", self, "_will_cast_lightning")
	player.connect("will_stab_by_knife", self, "_will_stab_by_knife")
	return player

func _create_hud_players(players):
	var i = 1
	for player in players:
		var texture = player.get_node("appearance").get_texture()
		var sprite = Sprite.new()
		var spacing = 8
		var x = 144 + (texture.get_size().x * i) + (spacing * i)
		var y = get_viewport().get_rect().size.y - (texture.get_size().y / 2)
		var pos = Vector2(x, y)
		sprite.set_texture(texture)
		sprite.set_pos(pos)
		sprite.add_to_group("hud_players")
		if player.is_main_player():
			sprite.add_to_group("hud_main_player")
		else:
			sprite.add_to_group("hud_enemies")
		get_node("hud").add_child(sprite)
		i += 1

func _did_collect_powerup(type, player):
	if player.is_main_player() and not _has_powerup():
		powerup.powerup = type
		powerup.spawn()
		player.powerup_type = type
		
		if type == 2:
			player_indicator.set_hidden(false)
			var enemy_count = _get_enemies().size()
			_start_targeting(enemy_count)
		elif type == 3:
			player_indicator.set_hidden(false)
			var player_count = _get_players().size()
			_start_targeting(player_count)

func _did_consume_powerup(player, type):
	powerup_container.get_child(0).queue_free()

func _select_lightning_target():
	target_selector.cancel_selecting()
	var target = target_selector.selected_target
	var index = target - 1
	if index >= 0:
		var enemy = _get_enemies()[index]
		enemy.on_lightning_strike()

func _select_knife_target():
	target_selector.cancel_selecting()
	var target = target_selector.selected_target
	var index = target - 1
	if index >= 0:
		var player = _get_players()[index]
		player.on_knife_stab()

func _will_throw_shuriken(player, shuriken):
	get_tree().call_group(0, "players", "exempt_from_shuriken_collision", shuriken)
	shuriken.connect("on_shuriken_contact", self, "_on_shuriken_contact")
	add_child(shuriken)

func _on_shuriken_contact(player):
	player.on_shuriken_hit()

func _will_cast_lightning(player):
	player_indicator.set_hidden(true)
	_select_lightning_target()

func _will_stab_by_knife(player):
	player_indicator.set_hidden(true)
	_select_knife_target()

func _has_powerup():
	return powerup_container.get_child_count() > 0

func _on_target_select(target):
	var index = target - 1
	if index >= 0:
		var players
		if powerup.powerup == 2:
			players = _get_enemies("hud_enemies")
		elif powerup.powerup == 3:
			players = _get_players("hud_players")
		
		if (players != null and 
			players.size() > 0 and 
			index < players.size()):
			var player = players[index]
			var pos = player.get_pos()
			var size = _get_hud_player_size(player)
			_move_player_indicator(pos, size)

func _move_player_indicator(pos, size):
	var x = pos.x - (16 / 2) # 16 is height of triangle
	var y = player_indicator.get_pos().y
	var position = Vector2(x, y)
	player_indicator.set_pos(position)

func _start_targeting(count):
	target_selector.start_selecting(count)

func _get_enemies(group = "enemies"):
	return get_tree().get_nodes_in_group(group)

func _get_players(group = "players"):
	return get_tree().get_nodes_in_group(group)

func _get_hud_player_size(player):
	return player.get_texture().get_size()

func _get_player_size(player):
	return _get_hud_player_size(player.get_node("appearance"))
