extends "res://tests/test_base.gd"

## Tests unitaires — DomoticsModule

const DomScript = preload("res://scripts/modules/domotics_module.gd")


func test_domotics_sensor_types() -> void:
	var d = DomScript.new()
	var expected := ["motion", "temperature", "opening", "humidity", "light_level"]
	for t in expected:
		assert_true(t in d.SENSOR_TYPES, "SENSOR_TYPES contient %s" % t)
	d.free()


func test_domotics_actuator_types() -> void:
	var d = DomScript.new()
	var expected := ["light", "shutter", "heating", "alarm", "lock"]
	for t in expected:
		assert_true(t in d.ACTUATOR_TYPES, "ACTUATOR_TYPES contient %s" % t)
	d.free()


func test_domotics_has_required_methods() -> void:
	var d = DomScript.new()
	assert_has_method(d, "add_sensor", "add_sensor existe")
	assert_has_method(d, "remove_sensor", "remove_sensor existe")
	assert_has_method(d, "add_actuator", "add_actuator existe")
	assert_has_method(d, "remove_actuator", "remove_actuator existe")
	assert_has_method(d, "add_scenario", "add_scenario existe")
	assert_has_method(d, "remove_scenario", "remove_scenario existe")
	assert_has_method(d, "evaluate_scenarios", "evaluate_scenarios existe")
	assert_has_method(d, "to_dict", "to_dict existe")
	assert_has_method(d, "from_dict", "from_dict existe")
	d.free()


func test_domotics_default_sensor_states() -> void:
	var d = DomScript.new()
	assert_equal(d._default_sensor_state("motion"), false, "motion = false")
	assert_equal(d._default_sensor_state("temperature"), 20.0, "temperature = 20.0")
	assert_equal(d._default_sensor_state("opening"), false, "opening = false")
	assert_equal(d._default_sensor_state("humidity"), 50.0, "humidity = 50.0")
	assert_equal(d._default_sensor_state("light_level"), 500.0, "light_level = 500.0")
	d.free()


func test_domotics_default_actuator_states() -> void:
	var d = DomScript.new()
	assert_equal(d._default_actuator_state("light"), false, "light = false")
	assert_equal(d._default_actuator_state("shutter"), 100, "shutter = 100")
	assert_equal(d._default_actuator_state("heating"), 20.0, "heating = 20.0")
	assert_equal(d._default_actuator_state("alarm"), false, "alarm = false")
	assert_equal(d._default_actuator_state("lock"), true, "lock = true")
	d.free()


func test_domotics_to_dict_structure() -> void:
	var d = DomScript.new()
	var data = d.to_dict()
	assert_dict_has_key(data, "sensors", "to_dict contient sensors")
	assert_dict_has_key(data, "actuators", "to_dict contient actuators")
	assert_dict_has_key(data, "scenarios", "to_dict contient scenarios")
	d.free()


func test_domotics_from_dict_empty() -> void:
	var d = DomScript.new()
	d.from_dict({})
	assert_equal(d.sensors.size(), 0, "from_dict({}) sensors vide")
	assert_equal(d.actuators.size(), 0, "from_dict({}) actuators vide")
	assert_equal(d.scenarios.size(), 0, "from_dict({}) scenarios vide")
	d.free()


func test_domotics_execute_action_out_of_bounds() -> void:
	var d = DomScript.new()
	d._execute_action({"actuator_index": -1, "action": "turn_on", "value": null})
	d._execute_action({"actuator_index": 999, "action": "turn_on", "value": null})
	assert_true(true, "_execute_action out of bounds ne crashe pas")
	d.free()


func test_domotics_evaluate_empty() -> void:
	var d = DomScript.new()
	var results = d.evaluate_scenarios()
	assert_equal(results.size(), 0, "evaluate_scenarios vide = 0 actions")
	d.free()
