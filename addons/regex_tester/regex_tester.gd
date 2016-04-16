tool
extends EditorPlugin

var plugin

func _enter_tree():
	plugin = load("regex_tester_dialog.scn").new()