extends "res://tests/test_base.gd"

## Tests unitaires — PlumbingModule

const PlumbingScript = preload("res://scripts/modules/plumbing_module.gd")


func test_plumbing_constants() -> void:
	var p = PlumbingScript.new()
	assert_equal(p.MIN_SLOPE, 0.01, "pente min = 1%")
	assert_equal(p.EVACUATION_DIAMETER_MIN, 40.0, "diamètre évac min = 40")
	assert_equal(p.EVACUATION_DIAMETER_MAX, 100.0, "diamètre évac max = 100")
	assert_equal(p.SUPPLY_DIAMETER_MIN, 12.0, "diamètre arrivée min = 12")
	assert_equal(p.SUPPLY_DIAMETER_MAX, 16.0, "diamètre arrivée max = 16")
	p.free()


func test_plumbing_has_required_methods() -> void:
	var p = PlumbingScript.new()
	assert_has_method(p, "add_pipe", "add_pipe existe")
	assert_has_method(p, "remove_pipe", "remove_pipe existe")
	assert_has_method(p, "add_fixture", "add_fixture existe")
	assert_has_method(p, "remove_fixture", "remove_fixture existe")
	assert_has_method(p, "validate", "validate existe")
	assert_has_method(p, "to_dict", "to_dict existe")
	assert_has_method(p, "from_dict", "from_dict existe")
	p.free()


func test_plumbing_validate_empty() -> void:
	var p = PlumbingScript.new()
	var errors = p.validate()
	assert_equal(errors.size(), 0, "aucune erreur si vide")
	p.free()


func test_plumbing_to_dict_structure() -> void:
	var p = PlumbingScript.new()
	var data = p.to_dict()
	assert_dict_has_key(data, "pipes", "to_dict contient pipes")
	assert_dict_has_key(data, "fixtures", "to_dict contient fixtures")
	p.free()


func test_plumbing_to_dict_empty() -> void:
	var p = PlumbingScript.new()
	var data = p.to_dict()
	assert_equal(data["pipes"].size(), 0, "pipes vide")
	assert_equal(data["fixtures"].size(), 0, "fixtures vide")
	p.free()


func test_plumbing_from_dict_empty() -> void:
	var p = PlumbingScript.new()
	p.from_dict({})
	assert_equal(p.pipes.size(), 0, "from_dict({}) pipes vide")
	assert_equal(p.fixtures.size(), 0, "from_dict({}) fixtures vide")
	p.free()


func test_plumbing_pipe_types() -> void:
	var p = PlumbingScript.new()
	var types := ["supply", "hot_supply", "evacuation"]
	for t in types:
		assert_true(t in p.PIPE_TYPES, "PIPE_TYPES contient %s" % t)
	p.free()


func test_plumbing_fixture_diameters_toilet() -> void:
	# WC = évac 100mm, arrivée 12mm
	var p = PlumbingScript.new()
	# Vérifier les constantes métier indirectement
	assert_equal(p.EVACUATION_DIAMETER_MAX, 100.0, "diamètre max évac = 100 (WC)")
	p.free()
