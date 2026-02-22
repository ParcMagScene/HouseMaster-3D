extends "res://tests/test_base.gd"

## Tests unitaires — SaveManager

const SaveScript = preload("res://scripts/save_manager.gd")


func test_save_manager_has_methods() -> void:
	var sm = SaveScript.new()
	assert_has_method(sm, "save_project", "save_project existe")
	assert_has_method(sm, "load_project", "load_project existe")
	assert_has_method(sm, "export_2d_plan", "export_2d_plan existe")
	assert_has_method(sm, "export_3d_capture", "export_3d_capture existe")
	assert_has_method(sm, "export_bill_of_materials", "export_bill_of_materials existe")
	sm.free()


func test_save_manager_save_path() -> void:
	var sm = SaveScript.new()
	assert_equal(sm.SAVE_PATH, "user://housemaster_save.json", "chemin de sauvegarde")
	sm.free()


func test_save_manager_build_save_data_structure() -> void:
	var sm = SaveScript.new()
	var data = sm._build_save_data()
	assert_dict_has_key(data, "version", "version présente")
	assert_dict_has_key(data, "timestamp", "timestamp présent")
	assert_dict_has_key(data, "house", "house présent")
	assert_dict_has_key(data, "modules", "modules présent")
	sm.free()


func test_save_manager_build_modules_structure() -> void:
	var sm = SaveScript.new()
	var data = sm._build_save_data()
	var mods = data.get("modules", {})
	assert_dict_has_key(mods, "plumbing", "plumbing dans modules")
	assert_dict_has_key(mods, "electricity", "electricity dans modules")
	assert_dict_has_key(mods, "network", "network dans modules")
	assert_dict_has_key(mods, "domotics", "domotics dans modules")
	sm.free()


func test_save_manager_version_format() -> void:
	var sm = SaveScript.new()
	var data = sm._build_save_data()
	var ver = data.get("version", "")
	assert_true(ver.begins_with("1."), "version commence par 1.")
	sm.free()


func test_save_manager_signals() -> void:
	var sm = SaveScript.new()
	assert_true(sm.has_signal("SAVE_COMPLETED"), "signal SAVE_COMPLETED")
	assert_true(sm.has_signal("LOAD_COMPLETED"), "signal LOAD_COMPLETED")
	assert_true(sm.has_signal("EXPORT_COMPLETED"), "signal EXPORT_COMPLETED")
	sm.free()
