tool

extends Node2D

signal did_collect(what, player)

export(int, "Speed", "Shield", "Lightning", "Knife", "Shuriken", "Heart") var powerup = 0
export var randomized = true

onready var powerup_util = get_node("/root/globals").powerup_util
onready var powerup_scenes = powerup_util.POWERUP_SCENES

func _ready():
	get_node("container").set_color(Color("00000000"))
	get_node("timer").connect("timeout", self, "_on_timeout")
	spawn()

func spawn():
	if randomized:
		_display_powerup(_get_index())
	else:
		_display_powerup(powerup)

func _display_powerup(index):
	var selected = _select_powerup(index)
	selected.connect("did_collect", self, "_did_collect")
	get_node("container").add_child(selected)

func _select_powerup(index):
	var path = str("res://source/powerup/", powerup_scenes[index])
	var instance = load(path).instance()
	return instance

func _get_index():
	randomize()
	var index = randi() % powerup_scenes.size()
	return index

func _did_collect(what, player):
	emit_signal("did_collect", what, player)
	_start_timer()

func _start_timer():
	get_node("timer").start()

func _on_timeout():
	spawn()