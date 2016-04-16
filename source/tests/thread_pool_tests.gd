
extends "test_base.gd"

var thread_pool = preload("res://source/util/thread_pool.gd")
var thread_pool_task = preload("res://source/util/thread_pool_task.gd")
var thread_pool_worker = preload("res://source/util/thread_pool_worker.gd")

var workers = Array()
var pools = Array()

var source

func _ready():
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("powerup"):
		source.stop()

func _exit_tree():
	for pool in pools:
		pool.terminate()

func should_execute_test(method):
	return method == "test_worker_should_stop_working_when_task_object_is_closed"
#	return method == "test_adding_tasks_while_pool_is_busy"
#	return method == "test_thread_pool_with_multi_tasks"
#	return method == "test_thread_pool"
#	return method == "test_thread_pool_worker"
#	return true

func test_thread_pool_creation():
	var worker_count = 3
	var pool = thread_pool.new(worker_count)
	assert_true(pool.has_waiting_workers(), "No workers are created.")

func test_thread_pool_task_should_be_executed():
	var task = _create_short_task()
	task.execute()
	assert_true(task.get_object().get_foo() == "hello", "foo is not hello")

func test_long_thread_pool_task():
	var task = _create_long_task()
	task.execute()
	assert_true(task.get_object().get_foo() == "bar", "foo is not bar")

func test_thread_pool_worker():
	var task = _create_long_task()
	var worker = thread_pool_worker.new(Thread.new())
	var expectation = WorkerExpectation.new(self, "test_thread_pool_worker", "worker_expectation")
	add_expectation(expectation)
	worker.connect("worker_on_finish", expectation, "worker_on_finish")
	workers.push_back(worker)
	worker.execute(task)

func test_thread_pool():
	_run_thread_pool(1, 1, "test_thread_pool", "sing_task_pool")

func test_thread_pool_with_multi_tasks():
	_run_thread_pool(10, 5, "test_thread_pool_with_multi_tasks", "multi_task_pool")

func test_adding_tasks_while_pool_is_busy():
	var pool = _run_thread_pool(10, 10, "test_adding_tasks_while_pool_is_busy", "busy_pool")
	_add_pool_tasks(pool, 10)

func test_worker_should_stop_working_when_task_object_is_closed():
	var pool = MockThreadPool.new(1)
	var expectation = ThreadPoolExpectation.new(self, "test_worker_should_stop_working_when_task_object_is_closed", "task_object_closed")
	add_expectation(expectation)
	pool.connect("mockthreadpool_on_finish", expectation, "mockthreadpool_on_finish")
	pools.push_back(pool)
	pool.start()
	var object = MockObject.new()
	source = object.listen(pool)

func _run_thread_pool(task_count, worker_count, method, expectation_name):
	var pool = MockThreadPool.new(worker_count)
	_add_pool_tasks(pool, task_count)
	
	var expectation = ThreadPoolExpectation.new(self, method, expectation_name)
	add_expectation(expectation)
	
	pool.connect("mockthreadpool_on_finish", expectation, "mockthreadpool_on_finish")
	pools.push_back(pool)
	pool.start()
	return pool

func _add_pool_tasks(pool, task_count):
	for i in range(task_count):
		var task = _create_long_task()
		pool.add_task(task)

func _create_short_task(method="set_foo", args=["hello"]):
	var object = MockObject.new()
	var task = thread_pool_task.new(object, method, args)
	return task

func _create_long_task(method="long_task", delay=2000, args=["bar", delay]):
	var object = MockObject.new()
	var task = thread_pool_task.new(object, method, args)
	return task

class WorkerExpectation extends "res://source/tests/test_expectation.gd":
	
	func _init(suite, method, name).(suite, method, name):
		pass
	
	func worker_on_finish(worker):
		test_suite.current_method = test_method
		test_suite.assert_true(worker.is_done(), "Worker is not done")
		emit_signal("on_finish", self)
		test_suite.workers.erase(worker)

class ThreadPoolExpectation extends "res://source/tests/test_expectation.gd":
	
	func _init(suite, method, name).(suite, method, name):
		pass
	
	func mockthreadpool_on_finish(pool):
		test_suite.current_method = test_method
		test_suite.assert_true(pool.fail_message == null, pool.fail_message)
		test_suite.assert_true(pool.has_waiting_workers(), "Expected that there are waiting workers")
		test_suite.assert_false(pool.has_working_workers(), "Expected that there are no working workers")
		test_suite.assert_false(pool.has_tasks(), "Expected that that there are no tasks")
		test_suite.assert_true(pool.finished_tasks == pool.task_count, "Finished tasks != task count")
		emit_signal("on_finish", self)
		pool.terminate()
		test_suite.pools.erase(pool)

class MockThreadPool extends "res://source/util/thread_pool.gd":
	
	signal mockthreadpool_on_finish(pool)
	
	var finished_tasks = 0
	var task_count = 0
	var fail_message
	
	func _init(worker_count).(worker_count):
		pass
	
	func add_task(task):
		mutex.lock()
		task_count += 1
		mutex.unlock()
		.add_task(task)
	
	func _on_finish_working(worker):
		._on_finish_working(worker)
		mutex.lock()
		finished_tasks += 1
		var object = worker.get_task().get_object()
		if object.has_method("get_foo"):
			var foo = object.get_foo()
			if foo != "bar" and foo != "foo":
				fail_message = "Worker did not set foo to bar."
		elif object.has_method("get_request"):
			var request = object.get_request()
			if not request.closed:
				fail_message = "Worker's task is not closed."
		mutex.unlock()
		
		if is_idle():
			terminate()
			emit_signal("mockthreadpool_on_finish", self)

class MockHTTPRequest extends Reference:
	
	var closed = true
	
	func close():
		closed = true
	
	func start_listening():
		closed = false
		print("listening")
		while not closed:
			pass
		print("stop listening")

class MockEventSource extends Reference:
	
	var http_request = MockHTTPRequest.new()
	
	func get_request():
		return http_request
	
	func stop():
		http_request.close()
	
	func start():
		http_request.start_listening()

class MockObject extends Reference:
	
	var foo = "foo"
	
	func _init():
		pass
	
	func set_foo(what):
		foo = what
	
	func get_foo():
		return foo
	
	func long_task(foo, delay=2000):
		set_foo(foo)
		OS.delay_msec(delay)
	
	func listen(pool):
		var source = MockEventSource.new()
		var task = load("res://source/util/thread_pool_task.gd").new(source, "start")
		pool.add_task(task)
		return source