
extends Reference

var http_request = preload("http_request.gd")

const FIREBASE_APP_URL = "https://panrun.firebaseio.com"

func _init():
	pass

func create_request(host, ssl_enable=true):
	var request = http_request.new(host)
	request.enable_ssl(ssl_enable)
	return request