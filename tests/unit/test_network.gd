extends "res://tests/test_base.gd"

## Tests unitaires — NetworkModule

const NetScript = preload("res://scripts/modules/network_module.gd")


func test_network_constants() -> void:
	var n = NetScript.new()
	assert_equal(n.MIN_CABLE_CATEGORY, "cat6", "catégorie min = cat6")
	assert_true("cat5e" in n.CABLE_TYPES, "CABLE_TYPES contient cat5e")
	assert_true("cat6" in n.CABLE_TYPES, "CABLE_TYPES contient cat6")
	assert_true("cat6a" in n.CABLE_TYPES, "CABLE_TYPES contient cat6a")
	assert_true("cat7" in n.CABLE_TYPES, "CABLE_TYPES contient cat7")
	assert_true("fiber" in n.CABLE_TYPES, "CABLE_TYPES contient fiber")
	n.free()


func test_network_has_required_methods() -> void:
	var n = NetScript.new()
	assert_has_method(n, "add_point", "add_point existe")
	assert_has_method(n, "remove_point", "remove_point existe")
	assert_has_method(n, "add_cable", "add_cable existe")
	assert_has_method(n, "add_wifi_zone", "add_wifi_zone existe")
	assert_has_method(n, "enable_patch_panel", "enable_patch_panel existe")
	assert_has_method(n, "validate", "validate existe")
	assert_has_method(n, "to_dict", "to_dict existe")
	assert_has_method(n, "from_dict", "from_dict existe")
	n.free()


func test_network_validate_empty() -> void:
	var n = NetScript.new()
	var errors = n.validate()
	assert_equal(errors.size(), 0, "aucune erreur si vide")
	n.free()


func test_network_patch_panel_default() -> void:
	var n = NetScript.new()
	assert_false(n.patch_panel["enabled"], "patch panel désactivé par défaut")
	assert_equal(n.patch_panel["ports"], 24, "24 ports par défaut")
	n.free()


func test_network_to_dict_structure() -> void:
	var n = NetScript.new()
	var data = n.to_dict()
	assert_dict_has_key(data, "points", "to_dict contient points")
	assert_dict_has_key(data, "cables", "to_dict contient cables")
	assert_dict_has_key(data, "wifi_zones", "to_dict contient wifi_zones")
	assert_dict_has_key(data, "patch_panel", "to_dict contient patch_panel")
	n.free()


func test_network_from_dict_empty() -> void:
	var n = NetScript.new()
	n.from_dict({})
	assert_equal(n.network_points.size(), 0, "from_dict({}) points vide")
	assert_equal(n.cables.size(), 0, "from_dict({}) cables vide")
	assert_equal(n.wifi_zones.size(), 0, "from_dict({}) wifi vide")
	n.free()


func test_network_cable_category_order() -> void:
	var n = NetScript.new()
	var cat5e_idx = n.CABLE_TYPES.find("cat5e")
	var cat6_idx = n.CABLE_TYPES.find("cat6")
	var cat7_idx = n.CABLE_TYPES.find("cat7")
	assert_lt(float(cat5e_idx), float(cat6_idx), "cat5e < cat6")
	assert_lt(float(cat6_idx), float(cat7_idx), "cat6 < cat7")
	n.free()
