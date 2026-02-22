extends "res://tests/test_base.gd"

## Tests unitaires — ElectricityModule

const ElecScript = preload("res://scripts/modules/electricity_module.gd")


func test_electricity_constants() -> void:
	var e = ElecScript.new()
	assert_equal(e.MAX_SOCKETS_PER_CIRCUIT, 8, "max 8 prises/circuit")
	assert_true(10 in e.BREAKER_SIZES, "disjoncteur 10A")
	assert_true(16 in e.BREAKER_SIZES, "disjoncteur 16A")
	assert_true(20 in e.BREAKER_SIZES, "disjoncteur 20A")
	assert_true(32 in e.BREAKER_SIZES, "disjoncteur 32A")
	e.free()


func test_electricity_has_required_methods() -> void:
	var e = ElecScript.new()
	assert_has_method(e, "add_circuit", "add_circuit existe")
	assert_has_method(e, "add_element", "add_element existe")
	assert_has_method(e, "remove_element", "remove_element existe")
	assert_has_method(e, "validate", "validate existe")
	assert_has_method(e, "get_panel_summary", "get_panel_summary existe")
	assert_has_method(e, "to_dict", "to_dict existe")
	assert_has_method(e, "from_dict", "from_dict existe")
	e.free()


func test_electricity_validate_empty() -> void:
	var e = ElecScript.new()
	var errors = e.validate()
	assert_equal(errors.size(), 0, "aucune erreur si vide")
	e.free()


func test_electricity_panel_default() -> void:
	var e = ElecScript.new()
	assert_equal(e.panel["main_breaker"], 32, "disjoncteur principal = 32A")
	e.free()


func test_electricity_to_dict_structure() -> void:
	var e = ElecScript.new()
	var data = e.to_dict()
	assert_dict_has_key(data, "circuits", "to_dict contient circuits")
	assert_dict_has_key(data, "elements", "to_dict contient elements")
	assert_dict_has_key(data, "panel", "to_dict contient panel")
	e.free()


func test_electricity_from_dict_empty() -> void:
	var e = ElecScript.new()
	e.from_dict({})
	assert_equal(e.circuits.size(), 0, "from_dict({}) circuits vide")
	assert_equal(e.elements.size(), 0, "from_dict({}) elements vide")
	e.free()


func test_electricity_panel_summary_empty() -> void:
	var e = ElecScript.new()
	var summary = e.get_panel_summary()
	assert_dict_has_key(summary, "main_breaker", "summary a main_breaker")
	assert_dict_has_key(summary, "circuits_count", "summary a circuits_count")
	assert_dict_has_key(summary, "total_elements", "summary a total_elements")
	assert_equal(summary["circuits_count"], 0, "0 circuits")
	assert_equal(summary["total_elements"], 0, "0 elements")
	e.free()


func test_electricity_breaker_sizes_sorted() -> void:
	var e = ElecScript.new()
	for i in range(e.BREAKER_SIZES.size() - 1):
		assert_lt(float(e.BREAKER_SIZES[i]), float(e.BREAKER_SIZES[i + 1]), "disjoncteurs triés")
	e.free()
