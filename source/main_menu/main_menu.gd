
extends Node

onready var create_lobby = get_node("lobby/create_lobby")
onready var enter_lobby = get_node("details/enter_lobby")
onready var lobby_list = get_node("lobby/lobby_list")
onready var lobby_details = get_node("details/lobby_details")
onready var refresh_lobby = get_node("lobby/refresh_lobby")

onready var globals = get_node("/root/globals")
onready var request_util = globals.request_util
onready var player_util = globals.player_util

var selected_lobby
var firebase
var refreshing = false
var entering = false

func _ready():
	create_lobby.connect("pressed", self, "_on_create_lobby")
	enter_lobby.connect("pressed", self, "_on_enter_lobby")
	refresh_lobby.connect("pressed", self, "_on_refresh_lobby")
	lobby_list.connect("item_selected", self, "_on_item_selected")
	
	var url = request_util.FIREBASE_APP_URL
	firebase = load("res://source/util/firebase.gd").new(url)
	firebase.connect("firebase_on_success", self, "_fb_on_success")
	firebase.connect("firebase_on_error", self, "_fb_on_error")
	firebase.set_thread_pool(globals.pool)
		
	_on_refresh_lobby()

func _fb_on_success(response):
	var info = Dictionary()
	var json = response.body.get_string_from_utf8()
	if json != "null":
		info.parse_json(json)
		if not refreshing:
			var key = info.keys()[0]
			if not entering:
				selected_lobby = info[key]
				globals.created_lobby = true
			else:
				globals.created_lobby = false
				entering = false
			_goto_lobby()
		else:
			refreshing = false
			_refresh_lobby_list(info)
	else:
		if refreshing:
			refreshing = false
		if entering:
			entering = false 

func _fb_on_error(response):
	print("Error: ", response)

func _on_refresh_lobby():
	refreshing = true
	firebase.get("/lobby")

func _on_create_lobby():
	var user = globals.user
	var username = user["username"]
	user["creator"] = true
	var id = OS.get_unix_time()
	var lobby_id = str("lobby_", username, "_", id)
	var data = {lobby_id: {"id": lobby_id, "players": {username: user}}}
	var json = data.to_json()
	firebase.patch("/lobby", json)

func _on_enter_lobby():
	entering = true
	var lobby_id = selected_lobby["id"]
	var path = str("/lobby/", lobby_id, "/players")
	var user = globals.user
	var username = user["username"]
	user["creator"] = false
	var data = {username: user}
	var json = data.to_json()
	firebase.patch(path, json)

func _goto_lobby():
	globals.selected_lobby = selected_lobby["id"]
	globals.goto_lobby()

func _refresh_lobby_list(info):
	if info.size() < 1:
		return
	
	lobby_list.clear()
	
	for key in info:
		var lobby = info[key]
		var name = lobby["id"]
		lobby_list.add_item(name)
		var count = lobby_list.get_item_count()
		lobby_list.set_item_metadata(count - 1, lobby)

func _on_item_selected(index):
	lobby_details.set_text("")
	var lobby = lobby_list.get_item_metadata(index)
	var id = lobby["id"]
	var players = lobby["players"]
	var connected = players.size()
	var text = str("id: ", id, "\n")
	text += str("connected: ", connected)
	for player in players:
		text += str("\n", player)
	lobby_details.set_text(text)
	selected_lobby = lobby
	enter_lobby.set_disabled(false)