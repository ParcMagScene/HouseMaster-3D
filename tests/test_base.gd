extends RefCounted

## Base class for all test scripts — HouseMaster 3D

var _passed := 0
var _failed := 0
var _failures: Array[String] = []
var _current_test := ""


func run_tests() -> Dictionary:
	_passed = 0
	_failed = 0
	_failures.clear()
	
	var methods := get_method_list()
	for method in methods:
		if method["name"].begins_with("test_"):
			_current_test = method["name"]
			_run_single_test(method["name"])
	
	return {"passed": _passed, "failed": _failed, "failures": _failures}


func _run_single_test(method_name: String) -> void:
	var success := true
	call(method_name)


func assert_true(condition: bool, message: String = "") -> void:
	if condition:
		_passed += 1
		print("  ✅ %s %s" % [_current_test, ("— " + message) if message != "" else ""])
	else:
		_failed += 1
		_failures.append(_current_test)
		print("  ❌ %s %s" % [_current_test, ("— " + message) if message != "" else ""])


func assert_false(condition: bool, message: String = "") -> void:
	assert_true(not condition, message)


func assert_equal(a: Variant, b: Variant, message: String = "") -> void:
	var msg = message if message != "" else "attendu=%s, obtenu=%s" % [str(b), str(a)]
	assert_true(a == b, msg)


func assert_not_equal(a: Variant, b: Variant, message: String = "") -> void:
	var msg = message if message != "" else "ne devrait pas être %s" % str(a)
	assert_true(a != b, msg)


func assert_gt(a: float, b: float, message: String = "") -> void:
	var msg = message if message != "" else "%s > %s" % [str(a), str(b)]
	assert_true(a > b, msg)


func assert_lt(a: float, b: float, message: String = "") -> void:
	var msg = message if message != "" else "%s < %s" % [str(a), str(b)]
	assert_true(a < b, msg)


func assert_gte(a: float, b: float, message: String = "") -> void:
	assert_true(a >= b, message if message != "" else "%s >= %s" % [str(a), str(b)])


func assert_in_range(value: float, min_val: float, max_val: float, message: String = "") -> void:
	var msg = message if message != "" else "%s dans [%s, %s]" % [str(value), str(min_val), str(max_val)]
	assert_true(value >= min_val and value <= max_val, msg)


func assert_not_null(value: Variant, message: String = "") -> void:
	assert_true(value != null, message if message != "" else "ne devrait pas être null")


func assert_null(value: Variant, message: String = "") -> void:
	assert_true(value == null, message if message != "" else "devrait être null")


func assert_has_method(obj: Object, method_name: String, message: String = "") -> void:
	assert_true(obj.has_method(method_name), message if message != "" else "devrait avoir la méthode %s" % method_name)


func assert_array_size(arr: Array, expected_size: int, message: String = "") -> void:
	assert_equal(arr.size(), expected_size, message if message != "" else "taille attendue=%d, obtenue=%d" % [expected_size, arr.size()])


func assert_dict_has_key(dict: Dictionary, key: String, message: String = "") -> void:
	assert_true(dict.has(key), message if message != "" else "devrait contenir la clé '%s'" % key)
