extends "res://tests/test_base.gd"

## Tests unitaires — MaterialCore

const MaterialScript = preload("res://scripts/core/material.gd")


func test_material_presets_exist() -> void:
	var mat = MaterialScript.new()
	assert_true(mat.PRESETS.size() > 0, "PRESETS non vide")
	mat.free()


func test_material_presets_keys() -> void:
	var mat = MaterialScript.new()
	var expected := ["meleze", "anthracite", "concrete", "plaster", "glass", "metal", "wood", "tile"]
	for key in expected:
		assert_true(mat.PRESETS.has(key), "PRESETS contient '%s'" % key)
	mat.free()


func test_material_preset_structure() -> void:
	var mat = MaterialScript.new()
	for key in mat.PRESETS:
		var preset = mat.PRESETS[key]
		assert_dict_has_key(preset, "color", "preset %s a 'color'" % key)
		assert_dict_has_key(preset, "roughness", "preset %s a 'roughness'" % key)
	mat.free()


func test_material_has_required_methods() -> void:
	var mat = MaterialScript.new()
	assert_has_method(mat, "create_standard_material", "create_standard_material existe")
	mat.free()


func test_material_get_static() -> void:
	var result = MaterialScript.get_material("meleze")
	assert_not_null(result, "get_material('meleze') non null")


func test_material_get_unknown() -> void:
	var result = MaterialScript.get_material("unknown_xyz")
	assert_null(result, "get_material('unknown') retourne null")


func test_material_create_standard() -> void:
	var mat = MaterialScript.new()
	mat.material_name = "meleze"
	var std = mat.create_standard_material()
	assert_not_null(std, "create_standard_material non null")
	assert_true(std is StandardMaterial3D, "retourne StandardMaterial3D")
	mat.free()


func test_material_roughness_range() -> void:
	var mat = MaterialScript.new()
	for key in mat.PRESETS:
		var r = mat.PRESETS[key]["roughness"]
		assert_in_range(r, 0.0, 1.0, "roughness %s dans [0, 1]" % key)
	mat.free()
