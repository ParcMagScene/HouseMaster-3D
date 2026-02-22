extends Node
class_name SaveManager

## Sauvegarde / Chargement JSON — HouseMaster 3D
## Format JSON complet : house, rooms, plumbing, electricity, network, domotics

signal SAVE_COMPLETED(path: String)
signal LOAD_COMPLETED(path: String)
signal EXPORT_COMPLETED(path: String)
signal SAVE_ERROR(message: String)

const DEFAULT_SAVE_PATH := "user://housemaster_save.json"

var house_ref: Node3D = null
var plumbing_ref: Node3D = null
var electricity_ref: Node3D = null
var network_ref: Node3D = null
var domotics_ref: Node3D = null


func setup(house: Node3D, plumbing: Node3D, electricity: Node3D, network: Node3D, domotics: Node3D) -> void:
	house_ref = house
	plumbing_ref = plumbing
	electricity_ref = electricity
	network_ref = network
	domotics_ref = domotics


func save_project(path: String = DEFAULT_SAVE_PATH) -> bool:
	var data := _build_save_data()
	var json_string = JSON.stringify(data, "\t")
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		var error_msg = "Erreur sauvegarde : impossible d'ouvrir %s" % path
		push_error(error_msg)
		SAVE_ERROR.emit(error_msg)
		return false
	
	file.store_string(json_string)
	file.close()
	
	print("Projet sauvegardé : %s" % path)
	SAVE_COMPLETED.emit(path)
	return true


func load_project(path: String = DEFAULT_SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		SAVE_ERROR.emit("Fichier introuvable : %s" % path)
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		SAVE_ERROR.emit("Erreur lecture : %s" % path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		SAVE_ERROR.emit("Erreur JSON : %s" % json.get_error_message())
		return false
	
	var data = json.data
	_apply_load_data(data)
	
	print("Projet chargé : %s" % path)
	LOAD_COMPLETED.emit(path)
	return true


func _build_save_data() -> Dictionary:
	var data := {
		"version": "1.0",
		"project_name": "HouseMaster 3D — Projet Alexandre",
		"date": Time.get_datetime_string_from_system(),
		"house": {},
		"plumbing": {},
		"electricity": {},
		"network": {},
		"domotics": {}
	}
	
	if house_ref and house_ref.has_method("to_dict"):
		data["house"] = house_ref.to_dict()
	if plumbing_ref and plumbing_ref.has_method("to_dict"):
		data["plumbing"] = plumbing_ref.to_dict()
	if electricity_ref and electricity_ref.has_method("to_dict"):
		data["electricity"] = electricity_ref.to_dict()
	if network_ref and network_ref.has_method("to_dict"):
		data["network"] = network_ref.to_dict()
	if domotics_ref and domotics_ref.has_method("to_dict"):
		data["domotics"] = domotics_ref.to_dict()
	
	return data


func _apply_load_data(data: Dictionary) -> void:
	if house_ref and house_ref.has_method("from_dict"):
		house_ref.from_dict(data.get("house", {}))
	if plumbing_ref and plumbing_ref.has_method("from_dict"):
		plumbing_ref.from_dict(data.get("plumbing", {}))
	if electricity_ref and electricity_ref.has_method("from_dict"):
		electricity_ref.from_dict(data.get("electricity", {}))
	if network_ref and network_ref.has_method("from_dict"):
		network_ref.from_dict(data.get("network", {}))
	if domotics_ref and domotics_ref.has_method("from_dict"):
		domotics_ref.from_dict(data.get("domotics", {}))


func export_2d_plan(path: String) -> bool:
	# Capture la vue 2D en image
	var viewport = get_viewport()
	if not viewport:
		return false
	
	await RenderingServer.frame_post_draw
	var image = viewport.get_texture().get_image()
	if image:
		image.save_png(path)
		print("Plan 2D exporté : %s" % path)
		EXPORT_COMPLETED.emit(path)
		return true
	return false


func export_3d_capture(path: String) -> bool:
	# Capture la vue 3D en image
	var viewport = get_viewport()
	if not viewport:
		return false
	
	await RenderingServer.frame_post_draw
	var image = viewport.get_texture().get_image()
	if image:
		image.save_png(path)
		print("Capture 3D exportée : %s" % path)
		EXPORT_COMPLETED.emit(path)
		return true
	return false
