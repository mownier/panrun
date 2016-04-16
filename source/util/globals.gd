
extends Node

onready var powerup_util = load("res://source/util/powerup_util.gd").new()
onready var request_util = load("res://source/util/request_util.gd").new()
onready var player_util = load("res://source/util/player_util.gd").new()

var connected_players = Dictionary()
var selected_map
var selected_lobby
var user
var game_id
var pool = load("res://source/util/thread_pool.gd").new()
var created_lobby = false

func _init():
	pool.start()

func _ready():
	pass

func goto_main_menu():
	get_tree().change_scene("res://source/main_menu/main_menu.scn")

func goto_lobby():
	get_tree().change_scene("res://source/lobby/lobby.scn")

func start_game():
	get_tree().change_scene("res://source/map/world.scn")

func save_user():
	pass