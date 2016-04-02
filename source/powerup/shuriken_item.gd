
extends RigidBody2D

signal on_shuriken_item_hit(player, item)

func _ready():
	get_node("timer").connect("timeout", self, "_on_timeout")
	get_node("area").connect("body_enter", self, "_on_contact")

func _on_timeout():
	queue_free()

func _on_contact(body):
	if body.get_name().begins_with("player"):
		emit_signal("on_shuriken_item_hit", body, self)