extends Node3D
class_name NetworkModule

## Module Réseau — HouseMaster 3D
## Règles :
##   - RJ45 cat6 minimum
##   - Fibre en entrée
##   - Baie de brassage optionnelle

signal NETWORK_UPDATED
signal POINT_ADDED(point: Dictionary)
signal CABLE_ADDED(cable: Dictionary)

# --- Constantes ---
const CABLE_TYPES := ["cat5e", "cat6", "cat6a", "cat7", "fiber"]
const MIN_CABLE_CATEGORY: String = "cat6"

# --- Couleurs ---
const COLOR_RJ45: Color = Color(0.2, 0.6, 0.3)
const COLOR_FIBER: Color = Color(0.9, 0.5, 0.1)
const COLOR_WIFI: Color = Color(0.3, 0.6, 0.9)
const COLOR_CABLE: Color = Color(0.3, 0.3, 0.8)

# --- Données ---
var network_points: Array[Dictionary] = []
# Format : {
#   "type": "rj45" / "fiber_inlet" / "router" / "switch" / "access_point",
#   "position": Vector3,
#   "room": String,
#   "cable_type": String,
#   "label": String
# }

var cables: Array[Dictionary] = []
# Format : {
#   "start_index": int,
#   "end_index": int,
#   "cable_type": String,
#   "length": float
# }

var wifi_zones: Array[Dictionary] = []
# Format : {
#   "center": Vector3,
#   "radius": float,
#   "ssid": String,
#   "band": "2.4GHz" / "5GHz" / "6GHz"
# }

var patch_panel: Dictionary = {
	"enabled": false,
	"position": Vector3.ZERO,
	"ports": 24,
	"connections": []
}

# --- Nœuds rendu ---
var points_container: Node3D = null
var cables_container: Node3D = null
var wifi_container: Node3D = null
var visible_layer: bool = true


func _ready() -> void:
	points_container = Node3D.new()
	points_container.name = "NetworkPointsContainer"
	add_child(points_container)
	
	cables_container = Node3D.new()
	cables_container.name = "NetworkCablesContainer"
	add_child(cables_container)
	
	wifi_container = Node3D.new()
	wifi_container.name = "WiFiContainer"
	add_child(wifi_container)


func add_point(type: String, pos: Vector3, room_name: String, cable_type: String = "cat6", label: String = "") -> int:
	if cable_type != "fiber" and CABLE_TYPES.find(cable_type) < CABLE_TYPES.find(MIN_CABLE_CATEGORY):
		push_warning("Réseau : câble %s inférieur au minimum requis (%s)" % [cable_type, MIN_CABLE_CATEGORY])
	
	var point := {
		"type": type,
		"position": pos,
		"room": room_name,
		"cable_type": cable_type,
		"label": label if label != "" else "%s_%d" % [type, network_points.size()]
	}
	network_points.append(point)
	_render_point(point)
	POINT_ADDED.emit(point)
	NETWORK_UPDATED.emit()
	return network_points.size() - 1


func remove_point(index: int) -> void:
	if index >= 0 and index < network_points.size():
		network_points.remove_at(index)
		# Supprimer câbles connectés
		cables = cables.filter(func(c): return c["start_index"] != index and c["end_index"] != index)
		_rebuild_render()
		NETWORK_UPDATED.emit()


func add_cable(start_index: int, end_index: int, cable_type: String = "cat6") -> void:
	if start_index < 0 or start_index >= network_points.size():
		return
	if end_index < 0 or end_index >= network_points.size():
		return
	
	var start_pos: Vector3 = network_points[start_index]["position"]
	var end_pos: Vector3 = network_points[end_index]["position"]
	var length = start_pos.distance_to(end_pos)
	
	var cable := {
		"start_index": start_index,
		"end_index": end_index,
		"cable_type": cable_type,
		"length": length
	}
	cables.append(cable)
	_render_cable_segment(start_pos, end_pos, cable_type)
	CABLE_ADDED.emit(cable)
	NETWORK_UPDATED.emit()


func add_wifi_zone(center: Vector3, radius: float, ssid: String = "HouseMaster_WiFi", band: String = "5GHz") -> void:
	var zone := {
		"center": center,
		"radius": radius,
		"ssid": ssid,
		"band": band
	}
	wifi_zones.append(zone)
	_render_wifi_zone(zone)
	NETWORK_UPDATED.emit()


func enable_patch_panel(pos: Vector3, ports: int = 24) -> void:
	patch_panel["enabled"] = true
	patch_panel["position"] = pos
	patch_panel["ports"] = ports
	_render_patch_panel()
	NETWORK_UPDATED.emit()


func _render_point(point: Dictionary) -> void:
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	
	match point["type"]:
		"rj45":
			box.size = Vector3(0.05, 0.05, 0.02)
		"fiber_inlet":
			box.size = Vector3(0.08, 0.08, 0.03)
		"router":
			box.size = Vector3(0.25, 0.05, 0.15)
		"switch":
			box.size = Vector3(0.30, 0.04, 0.15)
		"access_point":
			box.size = Vector3(0.15, 0.03, 0.15)
	
	mesh_instance.mesh = box
	mesh_instance.position = point["position"]
	
	var mat = StandardMaterial3D.new()
	match point["type"]:
		"rj45":
			mat.albedo_color = COLOR_RJ45
		"fiber_inlet":
			mat.albedo_color = COLOR_FIBER
		"router", "switch":
			mat.albedo_color = Color(0.2, 0.2, 0.25)
		"access_point":
			mat.albedo_color = COLOR_WIFI
	mesh_instance.material_override = mat
	
	points_container.add_child(mesh_instance)


func _render_cable_segment(start: Vector3, end_pos: Vector3, cable_type: String) -> void:
	var direction = end_pos - start
	var length = direction.length()
	if length < 0.001:
		return
	
	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.004
	cylinder.bottom_radius = 0.004
	cylinder.height = length
	mesh_instance.mesh = cylinder
	
	var center = (start + end_pos) / 2.0
	mesh_instance.position = center
	mesh_instance.look_at_from_position(center, end_pos, Vector3.UP)
	mesh_instance.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	
	var mat = StandardMaterial3D.new()
	if cable_type == "fiber":
		mat.albedo_color = COLOR_FIBER
	else:
		mat.albedo_color = COLOR_CABLE
	mesh_instance.material_override = mat
	
	cables_container.add_child(mesh_instance)


func _render_wifi_zone(zone: Dictionary) -> void:
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = zone["radius"]
	sphere.height = zone["radius"] * 2.0
	mesh_instance.mesh = sphere
	mesh_instance.position = zone["center"]
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.6, 0.9, 0.15)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = mat
	
	wifi_container.add_child(mesh_instance)


func _render_patch_panel() -> void:
	if not patch_panel["enabled"]:
		return
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.50, 0.10, 0.20)
	mesh_instance.mesh = box
	mesh_instance.position = patch_panel["position"]
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.2)
	mat.metallic = 0.5
	mesh_instance.material_override = mat
	
	points_container.add_child(mesh_instance)


func _rebuild_render() -> void:
	if points_container:
		for child in points_container.get_children():
			child.queue_free()
	if cables_container:
		for child in cables_container.get_children():
			child.queue_free()
	if wifi_container:
		for child in wifi_container.get_children():
			child.queue_free()
	for point in network_points:
		_render_point(point)
	for cable in cables:
		var si = cable.get("start_index", -1)
		var ei = cable.get("end_index", -1)
		if si >= 0 and si < network_points.size() and ei >= 0 and ei < network_points.size():
			_render_cable_segment(network_points[si]["position"], network_points[ei]["position"], cable.get("cable_type", "cat6"))
	for zone in wifi_zones:
		_render_wifi_zone(zone)
	if patch_panel["enabled"]:
		_render_patch_panel()


func set_layer_visible(is_visible: bool) -> void:
	visible_layer = is_visible
	if points_container:
		points_container.visible = is_visible
	if cables_container:
		cables_container.visible = is_visible
	if wifi_container:
		wifi_container.visible = is_visible


func validate() -> Array[String]:
	var errors: Array[String] = []
	for i in network_points.size():
		var point = network_points[i]
		if point["cable_type"] != "fiber":
			if CABLE_TYPES.find(point["cable_type"]) < CABLE_TYPES.find(MIN_CABLE_CATEGORY):
				errors.append("Point '%s' : câble %s inférieur au min (%s)" % [point["label"], point["cable_type"], MIN_CABLE_CATEGORY])
	
	var has_fiber_inlet := false
	for point in network_points:
		if point["type"] == "fiber_inlet":
			has_fiber_inlet = true
			break
	if not has_fiber_inlet and network_points.size() > 0:
		errors.append("Aucune arrivée fibre détectée")
	
	return errors


func to_dict() -> Dictionary:
	var points_data := []
	for p in network_points:
		points_data.append({
			"type": p["type"],
			"position": {"x": p["position"].x, "y": p["position"].y, "z": p["position"].z},
			"room": p["room"],
			"cable_type": p["cable_type"],
			"label": p["label"],
		})
	var wifi_data := []
	for z in wifi_zones:
		wifi_data.append({
			"center": {"x": z["center"].x, "y": z["center"].y, "z": z["center"].z},
			"radius": z["radius"],
			"ssid": z["ssid"],
			"band": z["band"],
		})
	return {
		"points": points_data,
		"cables": cables,
		"wifi_zones": wifi_data,
		"patch_panel": {
			"enabled": patch_panel["enabled"],
			"position": {"x": patch_panel["position"].x, "y": patch_panel["position"].y, "z": patch_panel["position"].z},
			"ports": patch_panel["ports"],
		}
	}


func from_dict(data: Dictionary) -> void:
	network_points.clear()
	cables.clear()
	wifi_zones.clear()
	_rebuild_render()
	
	for p in data.get("points", []):
		var pos = p.get("position", {})
		add_point(p.get("type", "rj45"), Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0)),
			p.get("room", ""), p.get("cable_type", "cat6"), p.get("label", ""))
	for c in data.get("cables", []):
		add_cable(c.get("start_index", 0), c.get("end_index", 0), c.get("cable_type", "cat6"))
	for z in data.get("wifi_zones", []):
		var center = z.get("center", {})
		add_wifi_zone(Vector3(center.get("x", 0), center.get("y", 0), center.get("z", 0)),
			z.get("radius", 5.0), z.get("ssid", ""), z.get("band", "5GHz"))
	
	var pp = data.get("patch_panel", {})
	if pp.get("enabled", false):
		var pos = pp.get("position", {})
		enable_patch_panel(Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0)), pp.get("ports", 24))
