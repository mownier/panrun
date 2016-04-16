
extends Node

onready var start_label = get_node("start_label")
onready var start = get_node("start_label/start")
onready var list = get_node("start_label/player_list")
onready var globals = get_node("/root/globals")
onready var map = get_node("map_label/map")
onready var lobby_id = globals.selected_lobby
onready var request_util = globals.request_util

var game_map
var game_id
var event_source
var firebase
var connected_players = Dictionary()

func _ready():
	start.connect("pressed", self, "_on_initiate_game")
	globals.connected_players.clear()
	if not globals.created_lobby:
		start.set_hidden(true)
		map.get_parent().set_hidden(true)
	_create_firebase()
	_listen_lobby()

func _on_initiate_game():
	_initiate_game()

func _create_firebase():
	var url = request_util.FIREBASE_APP_URL
	firebase = load("res://source/util/firebase.gd").new(url)
	firebase.connect("firebase_on_error", self, "_firebase_on_error")
	firebase.connect("firebase_on_receive_stream", self, "_firebase_on_receive_stream")
	firebase.connect("firebase_on_finish_listening", self, "_firebase_on_finish_listening")
	firebase.set_thread_pool(globals.pool)

func _listen_lobby():
	var path = str("/lobby/", lobby_id)
	event_source = firebase.listen(path)

func _initiate_game():
	game_id = str("game_", OS.get_unix_time())
	var info = _create_game_player_info()
	var path = str("/lobby/", lobby_id)
	var data = {game_id: info}
	firebase.patch(path, data.to_json())

func _create_game_player_info():
	var info = {}
	for key in connected_players:
		var player = connected_players[key]
		var username = player["username"]
		var name = str("player_", username)
		var default = _create_default_player_info()
		info[name] = default
	info["map"] = map.get_item_text(map.get_selected())
	return info

func _create_default_player_info():
	return {"move": "none", "powerup": "none", "jumping": false}

func _will_goto_world(selected_map):
#	game_map = selected_map
#	event_source.stop()
	_goto_world(selected_map)

func _goto_world(selected_map):
	globals.selected_map = selected_map
	globals.game_id = game_id
	globals.connected_players = connected_players
	globals.start_game()

func _firebase_on_error(response):
	print("error: ", response.error)

func _firebase_on_receive_stream(id, event, data):
	var json = data.strip_edges()
	if json != "null":
		var info = Dictionary()
		info.parse_json(json)
		var delete = event == "delete"
		var path = info["path"]
		var event_data = info["data"]
		if path == "/":
			if event_data.has("players"):
				var players = event_data["players"]
				call_deferred("_refresh_list", players, delete)
			else:
				for key in event_data:
					if key.begins_with("game_"):
						game_id = key
						break
				if game_id != null and not game_id.empty():
					var game_info = event_data[game_id]
					var selected_map = game_info["map"]
					call_deferred("_will_goto_world", selected_map)
		elif path == "/players":
			call_deferred("_refresh_list", event_data, delete)

func _firebase_on_finish_listening():
#	_goto_world(game_map)
	pass

func _refresh_list(players, delete=false):
	list.clear()
	for key in players:
		var player = players[key]
		if not delete:
			connected_players[key] = player
		else:
			connected_players.erase(key)
	for key in connected_players:
		var player = connected_players[key]
		var username = player["username"]
		list.add_item(username, null, false)