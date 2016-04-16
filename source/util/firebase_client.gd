
extends HTTPRequest

var listening = false
var buffer = RawArray()

func _ready():
	connect("request_completed", self, "_on_request_completed")
	connect("did_receive_data", self, "_did_receive_data")
	set_continuous(true)

func start_listening(url):
	if not listening:
		listening = true
		_listen(url)

func stop_listening():
	listening = false
	cancel_request()

func _start_request(url):
	var req_url = str(url, "?auth=lijNNCbQPUMwoDkZUc2lDhgs5sX4CzG8ItiR6UrQ")
	var header = ["Accept:text/event-stream"]
	request(url, header)

func _listen(url):
	_start_request(url)

func _on_request_completed(result, status, header, body):
	var text = str("result: ", result, ", status: ", status, ", body: ", body, ", size: ", body.size()) 
	print(text)

func _did_receive_data(data):
	buffer.push_back(data[0])
	var events = _extract_events()
	_parse_events(events)

func _extract_events():
	var size = buffer.size()
	if (size > 1 and
		buffer[size - 1] == 10 and
		buffer[size - 2] == 10):
		var events = buffer.get_string_from_utf8().split("\n\n", false)
		buffer.resize(0)
		return events
	else:
		return StringArray()

func _parse_events(events):
	if events.size() < 1:
		return
	
	for event_string in events:
		var event = _parse_event(event_string)
		print(event)

func _parse_event(event_string):
	var event = Dictionary()
	for line in event_string.split("\n", false):
		var colon_index = line.find(":")
		var key = line.left(colon_index)
		var value = line.right(colon_index + 1)
		event[key] = value
	return event

func _exit_tree():
	stop_listening()