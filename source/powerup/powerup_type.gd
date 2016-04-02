
extends Sprite

export(int, "Speed", "Shield", "Lightning", "Knife", "Shuriken", "Heart") var powerup = 0

signal did_collect(what, body)

func _ready():
	get_node("area").connect("body_enter", self, "_on_collect")

func _on_collect(body):
	if body.get_name().begins_with("player"):
		emit_signal("did_collect", powerup, body)
		queue_free()
