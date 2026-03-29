extends SceneTree

const TEST_ROOT := "res://tests"
const TEST_SUFFIX := "_test.gd"

var _failures: Array[String] = []
var _test_count := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var test_files := _collect_test_files(TEST_ROOT)
	if test_files.is_empty():
		print("No test files found under %s." % TEST_ROOT)
		quit(1)
		return

	for test_file in test_files:
		_run_test_file(test_file)

	var passed := _test_count - _failures.size()
	print("")
	print("Ran %d tests across %d files: %d passed, %d failed." % [
		_test_count,
		test_files.size(),
		passed,
		_failures.size(),
	])

	if not _failures.is_empty():
		print("")
		for failure in _failures:
			print(failure)
		quit(1)
		return

	quit(0)

func _collect_test_files(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return files

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue

		var full_path := dir_path.path_join(entry)
		if dir.current_is_dir():
			files.append_array(_collect_test_files(full_path))
		elif entry.ends_with(TEST_SUFFIX):
			files.append(full_path)

		entry = dir.get_next()

	dir.list_dir_end()
	files.sort()
	return files

func _run_test_file(test_path: String) -> void:
	var script := load(test_path)
	if script == null:
		_failures.append("[ERROR] %s could not be loaded." % test_path)
		return

	var test_case = script.new()
	if not test_case.has_method("set_context") or not test_case.has_method("begin_test") or not test_case.has_method("get_failures"):
		_failures.append("[ERROR] %s must extend res://tests/support/test_case.gd." % test_path)
		return

	var methods := _discover_test_methods(test_case)
	if methods.is_empty():
		_failures.append("[ERROR] %s does not define any test_ methods." % test_path)
		return

	for method_name in methods:
		_run_single_test(test_path, script, method_name)

func _discover_test_methods(test_case: Object) -> Array[String]:
	var methods: Array[String] = []
	for method_info in test_case.get_method_list():
		var method_name := String(method_info["name"])
		if method_name.begins_with("test_"):
			methods.append(method_name)

	methods.sort()
	return methods

func _run_single_test(test_path: String, script: Script, method_name: String) -> void:
	_test_count += 1
	var test_case = script.new()

	var sandbox := Node.new()
	sandbox.name = "Sandbox"
	root.add_child(sandbox)

	test_case.set_context(self, sandbox)
	test_case.begin_test(method_name)
	test_case.before_each()
	test_case.call(method_name)
	test_case.after_each()

	var failures: Array[String] = test_case.get_failures()
	if failures.is_empty():
		print("[PASS] %s :: %s" % [test_path, method_name])
	else:
		for failure in failures:
			_failures.append("[FAIL] %s :: %s :: %s" % [test_path, method_name, failure])
		print("[FAIL] %s :: %s" % [test_path, method_name])

	sandbox.free()
