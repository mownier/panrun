
extends Node2D

signal did_collect(what, player)

func _ready():
	get_node("powerup1").connect("did_collect", self, "_did_collect")
	get_node("powerup2").connect("did_collect", self, "_did_collect")
	get_node("powerup3").connect("did_collect", self, "_did_collect")
	get_node("powerup4").connect("did_collect", self, "_did_collect")
	pass

func _did_collect(what, player):
	emit_signal("did_collect", what, player)