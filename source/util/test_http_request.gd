
extends Reference

func _start_request(data):
	var host = "panrun.firebaseio.com"
	var path = "/message.json"
	var method = HTTPClient.METHOD_GET
	var headers = ["Accept:text/event-stream","User-Agent:GodotEngine/2.0 (Panrun)"]
	var body = ""
	var request = http_request.new(host)
	request.connect("request_completed", self, "_request_completed")
	request.connect("did_receive_data", self, "_did_receive_data")
	request.keep_open = true
	request.enable_ssl(true)
	request.resume(method, path, body, headers)

func _request_completed(request, response):
	print("status_code: ", response.status_code)

func _did_receive_data(request, data):
	print(data.get_string_from_utf8())


