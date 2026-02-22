extends Node3D
class_name ElectricityModule

## Module Électricité — HouseMaster 3D
## Règles métier :
##   - Circuit prises : max 8 par circuit
##   - Éclairage séparé des prises
##   - Disjoncteurs : 10A / 16A / 20A
##   - Tableau structuré

signal ELECTRICITY_UPDATED
signal CIRCUIT_ADDED(circuit: Dictionary)
signal ELEMENT_ADDED(element: Dictionary)

# --- Constantes métier ---
const MAX_SOCKETS_PER_CIRCUIT: int = 8
const BREAKER_SIZES := [10, 16, 20, 32]

# --- Couleurs ---
const COLOR_CABLE: Color = Color(0.1, 0.1, 0.1)
const COLOR_SOCKET: Color = Color(0.95, 0.95, 0.9)
const COLOR_SWITCH: Color = Color(0.9, 0.9, 0.85)
const COLOR_LIGHT: Color = Color(1.0, 0.95, 0.7)

# --- Données ---
var circuits: Array[Dictionary] = []
# Format circuit : {
#   "name": String,
#   "type": "sockets" / "lights" / "dedicated",
#   "breaker_amps": int,
#   "elements": Array[Dictionary],
#   "room": String
# }

var elements: Array[Dictionary] = []
# Format element : {
#   "type": "socket" / "switch" / "light" / "outlet_32a",
#   "position": Vector3,
#   "room": String,
#   "circuit_index": int,
#   "height": float (hauteur depuis le sol)
# }

var panel: Dictionary = {
	"position": Vector3.ZERO,
	"circuits": [],
	"main_breaker": 32,
}

# --- Nœuds rendu ---
var cables_container: Node3D = null
var elements_container: Node3D = null
var visible_layer: bool = true


func _ready() -> void:
	cables_container = Node3D.new()
	cables_container.name = "CablesContainer"
	add_child(cables_container)
	
	elements_container = Node3D.new()
	elements_container.name = "ElementsContainer"
	add_child(elements_container)


func add_circuit(circuit_name: String, type: String, breaker_amps: int = 16, room_name: String = "") -> int:
	if breaker_amps not in BREAKER_SIZES:
		push_warning("Électricité : disjoncteur %dA non standard" % breaker_amps)
	
	var circuit := {
		"name": circuit_name,
		"type": type,
		"breaker_amps": breaker_amps,
		"elements": [],
		"room": room_name
	}
	circuits.append(circuit)
	panel["circuits"].append(circuits.size() - 1)
	CIRCUIT_ADDED.emit(circuit)
	ELECTRICITY_UPDATED.emit()
	return circuits.size() - 1


func add_element(type: String, pos: Vector3, room_name: String, circuit_index: int, height: float = 0.3) -> void:
	# Validation : max 8 prises par circuit
	if type == "socket" and circuit_index >= 0 and circuit_index < circuits.size():
		var circuit = circuits[circuit_index]
		if circuit["type"] == "sockets":
			var socket_count := 0
			for el in elements:
				if el["type"] == "socket" and el["circuit_index"] == circuit_index:
					socket_count += 1
			if socket_count >= MAX_SOCKETS_PER_CIRCUIT:
				push_warning("Électricité : circuit %s a déjà %d prises (max %d)" %
					[circuit["name"], socket_count, MAX_SOCKETS_PER_CIRCUIT])
				return
	
	var element := {
		"type": type,
		"position": pos,
		"room": room_name,
		"circuit_index": circuit_index,
		"height": height
	}
	elements.append(element)
	
	if circuit_index >= 0 and circuit_index < circuits.size():
		circuits[circuit_index]["elements"].append(elements.size() - 1)
	
	_render_element(element)
	ELEMENT_ADDED.emit(element)
	ELECTRICITY_UPDATED.emit()


func remove_element(index: int) -> void:
	if index >= 0 and index < elements.size():
		elements.remove_at(index)
		_rebuild_render()
		ELECTRICITY_UPDATED.emit()


func add_cable(start: Vector3, end_pos: Vector3) -> void:
	_render_cable(start, end_pos)


func _render_element(element: Dictionary) -> void:
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	
	match element["type"]:
		"socket":
			box.size = Vector3(0.08, 0.08, 0.02)
		"switch":
			box.size = Vector3(0.08, 0.12, 0.02)
		"light":
			box.size = Vector3(0.15, 0.05, 0.15)
		"outlet_32a":
			box.size = Vector3(0.10, 0.10, 0.03)
	
	mesh_instance.mesh = box
	var pos = element["position"]
	pos.y = element["height"]
	if element["type"] == "light":
		pos.y = 2.4  # au plafond
	mesh_instance.position = pos
	
	var mat = StandardMaterial3D.new()
	match element["type"]:
		"socket":
			mat.albedo_color = COLOR_SOCKET
		"switch":
			mat.albedo_color = COLOR_SWITCH
		"light":
			mat.albedo_color = COLOR_LIGHT
			mat.emission_enabled = true
			mat.emission = COLOR_LIGHT
			mat.emission_energy_multiplier = 0.5
		"outlet_32a":
			mat.albedo_color = Color(0.9, 0.2, 0.2)
	mesh_instance.material_override = mat
	
	elements_container.add_child(mesh_instance)


func _render_cable(start: Vector3, end_pos: Vector3) -> void:
	var direction = end_pos - start
	var length = direction.length()
	if length < 0.001:
		return
	
	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.005
	cylinder.bottom_radius = 0.005
	cylinder.height = length
	mesh_instance.mesh = cylinder
	
	var center = (start + end_pos) / 2.0
	mesh_instance.position = center
	mesh_instance.look_at_from_position(center, end_pos, Vector3.UP)
	mesh_instance.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = COLOR_CABLE
	mesh_instance.material_override = mat
	
	cables_container.add_child(mesh_instance)


func _rebuild_render() -> void:
	if cables_container:
		for child in cables_container.get_children():
			child.queue_free()
	if elements_container:
		for child in elements_container.get_children():
			child.queue_free()
	for element in elements:
		_render_element(element)


func set_layer_visible(is_visible: bool) -> void:
	visible_layer = is_visible
	if cables_container:
		cables_container.visible = is_visible
	if elements_container:
		elements_container.visible = is_visible


func validate() -> Array[String]:
	var errors: Array[String] = []
	for i in circuits.size():
		var circuit = circuits[i]
		if circuit["type"] == "sockets":
			var count := 0
			for el in elements:
				if el["type"] == "socket" and el["circuit_index"] == i:
					count += 1
			if count > MAX_SOCKETS_PER_CIRCUIT:
				errors.append("Circuit '%s' : %d prises (max %d)" % [circuit["name"], count, MAX_SOCKETS_PER_CIRCUIT])
		if circuit["breaker_amps"] not in BREAKER_SIZES:
			errors.append("Circuit '%s' : disjoncteur %dA non standard" % [circuit["name"], circuit["breaker_amps"]])
	return errors


func get_panel_summary() -> Dictionary:
	var summary := {
		"main_breaker": panel["main_breaker"],
		"circuits_count": circuits.size(),
		"total_elements": elements.size(),
		"circuits": []
	}
	for circuit in circuits:
		var count := 0
		for el in elements:
			if el["circuit_index"] == circuits.find(circuit):
				count += 1
		summary["circuits"].append({
			"name": circuit["name"],
			"type": circuit["type"],
			"breaker": circuit["breaker_amps"],
			"elements_count": count
		})
	return summary


func to_dict() -> Dictionary:
	var elements_data := []
	for el in elements:
		elements_data.append({
			"type": el["type"],
			"position": {"x": el["position"].x, "y": el["position"].y, "z": el["position"].z},
			"room": el["room"],
			"circuit_index": el["circuit_index"],
			"height": el["height"],
		})
	return {
		"circuits": circuits,
		"elements": elements_data,
		"panel": panel,
	}


func from_dict(data: Dictionary) -> void:
	circuits = data.get("circuits", [])
	panel = data.get("panel", {"position": Vector3.ZERO, "circuits": [], "main_breaker": 32})
	elements.clear()
	_rebuild_render()
	for el in data.get("elements", []):
		var pos = el.get("position", {})
		add_element(el.get("type", "socket"), Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0)),
			el.get("room", ""), el.get("circuit_index", -1), el.get("height", 0.3))
