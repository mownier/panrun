tool 

extends Node2D

onready var powerup_on_stack = get_node("hud/powerup")
onready var powerup_container = get_node("hud/powerup/container")
onready var player_indicator = get_node("hud2/player_indicator")
onready var target_selector = get_node("target_selector")

onready var globals = get_node("/root/globals")
onready var powerup_util = globals.powerup_util
onready var game_id = globals.game_id
onready var connected_players = globals.connected_players
onready var lobby_id = globals.selected_lobby

var player_scene = preload("res://source/player/player.scn")
var firebase
var event_source

func _ready():
	var map_name = globals.selected_map
	var map_path = str("res://source/map/", map_name)
	var map_scene = load(map_path)
	var map = map_scene.instance()
	map.connect("did_collect", self, "_did_collect_powerup")
	add_child(map)
	
	var main_player_username = globals.user["username"]
	_create_players(connected_players, main_player_username)
	var players = get_tree().get_nodes_in_group("players")
	get_tree().call_group(0, "players", "exempt_from_player_collision", players)
	
	_create_hud_players(players)
	
	powerup_container.get_child(0).queue_free()
	powerup_container.set_color(Color("ffffff"))
	
	target_selector.connect("on_target_select", self, "_on_target_select")
	
	_create_firebase()
	_listen_world_actions()

func _create_players(players, main_player_username):
	var i = 0
	for key in players:
		var user = players[key]
		var username = user["username"]
		var player = _create_player()
		var spacing = 8
		var size = _get_player_size(player)
		var x = 100 + (size.x * i) + (spacing * i)
		var pos = Vector2(x, 0)
		var name =_get_player_name(username)
		player.set_pos(pos)
		player.set_name(name)
		player.add_to_group("players")
		if username == main_player_username:
			player.set_main_player(true)
			_set_player_connect(player)
		else:
			player.set_main_player(false)
			player.add_to_group("enemies")
			player.remove_child(player.get_node("camera"))
		add_child(player)
		i += 1

func _create_player():
	var player = player_scene.instance()
	player.connect("did_consume_powerup", self, "_did_consume_powerup")
	player.connect("will_throw_shuriken", self, "_will_throw_shuriken")
	player.connect("will_cast_lightning", self, "_will_cast_lightning")
	player.connect("will_stab_by_knife", self, "_will_stab_by_knife")
	return player

func _set_player_connect(player):
	player.connect("on_jump", self, "_on_jump")
	player.connect("on_finish_jump", self, "_on_finish_jump")
	player.connect("on_move_left", self, "_on_move_left")
	player.connect("on_move_right", self, "_on_move_right")
	player.connect("on_stop", self, "_on_stop")

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
		powerup_on_stack.powerup = type
		powerup_on_stack.spawn()
		
		if type == 2:
			player_indicator.set_hidden(false)
			var enemy_count = _get_enemies().size()
			_start_targeting(enemy_count)
		elif type == 3:
			player_indicator.set_hidden(false)
			var player_count = _get_players().size()
			_start_targeting(player_count)
		
		var player_powerup = powerup_util.create_powerup(type)
		if player_powerup != null:
			player.add_powerup(player_powerup)

func _did_consume_powerup(player, type):
	if player.is_main_player():
		powerup_container.get_child(0).queue_free()
		var status = str("consume,", powerup_util.POWERUP_TYPE[type])
		_send_powerup_info(player.get_name(), status)

func _select_lightning_target(lightning):
	target_selector.cancel_selecting()
	var target = target_selector.selected_target
	var index = target - 1
	var enemies = _get_enemies()
	if index >= 0 and index < enemies.size():
		var enemy = enemies[index]
		var damaged = enemy.on_lightning_strike(lightning)
		if damaged:
			var status = str("hit,lightning")
			_send_powerup_info(enemy.get_name(), status)

func _select_knife_target(knife):
	target_selector.cancel_selecting()
	var target = target_selector.selected_target
	var index = target - 1
	var players = _get_players()
	if index >= 0 and index < players.size():
		var player = players[index]
		var damaged = player.on_knife_stab(knife)
		if damaged:
			var status = str("hit,knife")
			_send_powerup_info(player.get_name(), status)

func _will_throw_shuriken(player, item):
	get_tree().call_group(0, "players", "exempt_from_shuriken_collision", item)
	item.connect("on_shuriken_item_hit", self, "_on_shuriken_item_hit")
	add_child(item)

func _on_shuriken_item_hit(player, item):
	var shuriken = powerup_util.create_shuriken()
	var damaged = player.on_shuriken_hit(shuriken)
	if damaged:
		var status = str("hit,shuriken")
		_send_powerup_info(player.get_name(), status)

func _will_cast_lightning(player):
	player_indicator.set_hidden(true)
	var lightning = powerup_util.create_lightning()
	_select_lightning_target(lightning)

func _will_stab_by_knife(player):
	player_indicator.set_hidden(true)
	var knife = powerup_util.create_knife()
	_select_knife_target(knife)

func _has_powerup():
	return powerup_container.get_child_count() > 0

func _on_target_select(target):
	var index = target - 1
	if index >= 0:
		var players
		if powerup_on_stack.powerup == 2:
			players = _get_enemies("hud_enemies")
		elif powerup_on_stack.powerup == 3:
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

func _get_player_name(username):
	return str("player_", username)

func _create_firebase():
	var url = globals.request_util.FIREBASE_APP_URL
	firebase = load("res://source/util/firebase.gd").new(url)
	firebase.connect("firebase_on_receive_stream", self, "_firebase_on_receive_stream")
	firebase.connect("firebase_on_finish_listening", self, "_firebase_on_finish_listening")
	firebase.set_thread_pool(globals.pool)

func _listen_world_actions():
	var path = str("/lobby/", lobby_id, "/", game_id)
	event_source = firebase.listen(path)

func _firebase_on_receive_stream(id, event, data):
	_process_stream_data(data)

func _firebase_on_finish_listening():
	# TODO: exit game
	pass

func _process_stream_data(data):
	if data.strip_edges() != "null":
		var info = {}
		info.parse_json(data)
		_process_receive_info(info)

func _process_receive_info(info):
	var path = info["path"]
	print("path: ", path)
	if path != null or path != "null":
		var paths = path.split("/", false)
		if paths.size() == 1:
			var player_name = paths[0]
			var action_info = info["data"]
			var action = action_info.keys()[0]
			var action_value = action_info[action]
			
			if (player_name != str("player_", globals.user["username"]) or
				action_value.begins_with("hit")):
				print("did process player: ", player_name)
				if action_info.size() == 1:
					call_deferred("_process_player_action", player_name, action, action_value)

func _process_player_action(name, action, action_value):
	print("process other player: ", name, " > ", action, " > ", action_value)
	var player = get_node(name)
	if action == "move":
		if action_value == "left":
			player.set_action(player.ACTION_MOVE_LEFT)
		elif action_value == "right":
			player.set_action(player.ACTION_MOVE_RIGHT)
		else:
			player.set_action(player.ACTION_STOP)
	elif action == "jumping":
		player.should_jump(action_value)
	elif action == "powerup":
		var powerup_info = action_value.split(",", false)
		if powerup_info.size() > 1:
			var powerup_action = powerup_info[0] 
			var powerup_name = powerup_info[1]
			if powerup_action == "consume":
				var key = powerup_name.to_upper()
				var type = powerup_util.POWERUP[key]
				var powerup = powerup_util.create_powerup(type)
				player.use_powerup(powerup)
			elif powerup_action == "hit":
				if powerup_name == "shuriken":
					var shuriken = powerup_util.create_shuriken()
					player.on_shuriken_hit(shuriken)
					print("process on_shuriken_hit")
				elif powerup_name == "knife":
					var knife = powerup_util.create_knife()
					player.on_knife_stab(knife)
					print("process on_knife_stab")
				elif powerup_name == "lightning":
					var lightning = powerup_util.create_lightning()
					var damaged = player.on_lightning_strike(lightning)
					print("process on_lightning_strike")
					if damaged:
						print("player damaged...")
					else:
						print("player not damaged...")

func _get_player_firebase_path(name):
	var path =  str("/lobby/", lobby_id, "/", game_id, "/", name)
	return path

func _on_jump(player):
	_send_jumping_info(player.get_name(), true)

func _on_finish_jump(player):
	_send_jumping_info(player.get_name(), false)

func _send_jumping_info(player_name, is_jumping):
	var path = _get_player_firebase_path(player_name)
	var data = {"jumping": is_jumping}
	firebase.patch(path, data.to_json())

func _on_move_left(player):
	_send_move_info(player.get_name(), "left")

func _on_move_right(player):
	_send_move_info(player.get_name(), "right")

func _on_stop(player):
	_send_move_info(player.get_name(), "stop")

func _send_move_info(player_name, move):
	var path = _get_player_firebase_path(player_name)
	var data = {"move": move}
	firebase.patch(path, data.to_json())
	print("Should send move info: ", move)

func _send_powerup_info(player_name, status):
	var path = _get_player_firebase_path(player_name)
	var id = OS.get_unix_time()
	var data = {"powerup": str(status, ",", id)}
	firebase.patch(path, data.to_json())
	print("Should send powerup info: ", status)