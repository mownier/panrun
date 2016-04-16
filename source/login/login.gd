
extends Node

onready var username = get_node("username")
onready var signin = get_node("signin")

onready var request_util = get_node("/root/globals").request_util
onready var globals = get_node("/root/globals")

var firebase

func _ready():
	signin.connect("pressed", self, "_on_signin")
	
	var url = request_util.FIREBASE_APP_URL
	firebase = load("res://source/util/firebase.gd").new(url)
	firebase.connect("firebase_on_success", self, "_fb_on_success")
	firebase.connect("firebase_on_error", self, "_fb_on_error")
	firebase.set_thread_pool(globals.pool)

func _on_signin():
	var user_uname = username.get_text()
	if not user_uname.empty():
		var path = _get_user_path(str("/", user_uname))
		firebase.get(path)

func _fb_on_success(response):
	var response_string = response.body.get_string_from_utf8()
	if response_string == "null":
		var user_uname = username.get_text()
		if not user_uname.empty():
			var path = _get_user_path()
			var data = _get_default_user_info(user_uname)
			firebase.patch(path, data)
	else:
		var user = Dictionary()
		user.parse_json(response_string)
		globals.user = user
		globals.goto_main_menu()

func _fb_on_error(response):
	print(response.body.get_string_from_utf8())

func _get_user_path(username=""):
	var path = str("/user", username)
	return path

func _get_default_user_info(username):
	var info = {username: {"username": username, "points": 0}}
	return info.to_json()