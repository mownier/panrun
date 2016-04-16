
extends Node

var regex = RegEx.new()

onready var test_button = get_node("test_button")
onready var input = get_node("input")
onready var list = get_node("list")
onready var test_string = get_node("test_string")

func _ready():
	test_button.connect("pressed", self, "_on_test")

func _on_test():
	var pattern = input.get_text()
	pattern = pattern.replace("\n", "")
	pattern = pattern.replace(" ", "")
	_update_regex(pattern)
	_update_list()

func _update_regex(pattern):
	regex.clear()
	regex.compile(pattern)

func _update_list():
	list.clear()
	if not regex.is_valid():
		list.add_item("Invalid regex pattern")
	elif regex.get_capture_count() == 0:
		list.add_item("Nothing captured")
	else:
		var text = test_string.get_text()
		regex.find(text)
		for captured in regex.get_captures():
			if captured.empty():
				list.add_item("empty")
			else:
				list.add_item(captured)