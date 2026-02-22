extends Node3D
class_name PlumbingModule

## Module Plomberie — HouseMaster 3D
## Règles métier :
##   - Pente min évacuation : 1%
##   - Diamètre évacuation : 40–100 mm
##   - Arrivée eau : 12–16 mm
##   - Chaque appareil = arrivée + évacuation

signal PLUMBING_UPDATED
signal PIPE_ADDED(pipe: Dictionary)
signal PIPE_REMOVED(index: int)

# --- Constantes métier ---
const MIN_SLOPE: float = 0.01  # 1%
const EVACUATION_DIAMETER_MIN: float = 40.0  # mm
const EVACUATION_DIAMETER_MAX: float = 100.0  # mm
const SUPPLY_DIAMETER_MIN: float = 12.0  # mm
const SUPPLY_DIAMETER_MAX: float = 16.0  # mm

# --- Couleurs de visualisation ---
const COLOR_SUPPLY: Color = Color(0.2, 0.4, 0.9)       # Bleu = eau froide
const COLOR_HOT_SUPPLY: Color = Color(0.9, 0.3, 0.2)   # Rouge = eau chaude
const COLOR_EVACUATION: Color = Color(0.6, 0.3, 0.1)    # Marron = évacuation

# --- Données ---
var pipes: Array[Dictionary] = []
# Format pipe : {
#   "type": "supply" / "hot_supply" / "evacuation",
#   "start": Vector3,
#   "end": Vector3,
#   "diameter": float (mm),
#   "room": String,
#   "slope": float (pour évacuation)
# }

var fixtures: Array[Dictionary] = []
# Format fixture : {
#   "type": "sink" / "toilet" / "shower" / "bathtub" / "washing_machine",
#   "position": Vector3,
#   "room": String,
#   "supply_diameter": float,
#   "evacuation_diameter": float
# }

# --- Nœuds de rendu ---
var pipes_container: Node3D = null
var fixtures_container: Node3D = null
var visible_layer: bool = true


func _ready() -> void:
	pipes_container = Node3D.new()
	pipes_container.name = "PipesContainer"
	add_child(pipes_container)
	
	fixtures_container = Node3D.new()
	fixtures_container.name = "FixturesContainer"
	add_child(fixtures_container)


func add_pipe(type: String, start: Vector3, end: Vector3, diameter: float, room_name: String = "") -> int:
	var slope := 0.0
	if type == "evacuation":
		slope = _calculate_slope(start, end)
		if slope < MIN_SLOPE:
			push_warning("Plomberie : pente insuffisante (%.3f < %.3f)" % [slope, MIN_SLOPE])
		if diameter < EVACUATION_DIAMETER_MIN or diameter > EVACUATION_DIAMETER_MAX:
			push_warning("Plomberie : diamètre évacuation hors norme (%.0f mm)" % diameter)
	else:
		if diameter < SUPPLY_DIAMETER_MIN or diameter > SUPPLY_DIAMETER_MAX:
			push_warning("Plomberie : diamètre arrivée hors norme (%.0f mm)" % diameter)
	
	var pipe := {
		"type": type,
		"start": start,
		"end": end,
		"diameter": diameter,
		"room": room_name,
		"slope": slope
	}
	pipes.append(pipe)
	_render_pipe(pipe)
	PIPE_ADDED.emit(pipe)
	PLUMBING_UPDATED.emit()
	return pipes.size() - 1


func remove_pipe(index: int) -> void:
	if index >= 0 and index < pipes.size():
		pipes.remove_at(index)
		_rebuild_render()
		PIPE_REMOVED.emit(index)
		PLUMBING_UPDATED.emit()


func add_fixture(type: String, pos: Vector3, room_name: String) -> void:
	var supply_d := SUPPLY_DIAMETER_MIN
	var evac_d := EVACUATION_DIAMETER_MIN
	
	match type:
		"toilet":
			evac_d = 100.0
			supply_d = 12.0
		"shower":
			evac_d = 50.0
			supply_d = 14.0
		"bathtub":
			evac_d = 50.0
			supply_d = 14.0
		"sink":
			evac_d = 40.0
			supply_d = 12.0
		"washing_machine":
			evac_d = 40.0
			supply_d = 16.0
	
	var fixture := {
		"type": type,
		"position": pos,
		"room": room_name,
		"supply_diameter": supply_d,
		"evacuation_diameter": evac_d,
	}
	fixtures.append(fixture)
	_render_fixture(fixture)
	PLUMBING_UPDATED.emit()


func remove_fixture(index: int) -> void:
	if index >= 0 and index < fixtures.size():
		fixtures.remove_at(index)
		_rebuild_render()
		PLUMBING_UPDATED.emit()


func _calculate_slope(start: Vector3, end: Vector3) -> float:
	var horizontal_distance = Vector2(end.x - start.x, end.z - start.z).length()
	if horizontal_distance == 0:
		return 0.0
	return abs(end.y - start.y) / horizontal_distance


func _render_pipe(pipe: Dictionary) -> void:
	var start: Vector3 = pipe["start"]
	var end_pos: Vector3 = pipe["end"]
	var direction = end_pos - start
	var length = direction.length()
	
	if length < 0.001:
		return
	
	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	var radius = pipe["diameter"] / 2000.0  # mm -> m
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = length
	mesh_instance.mesh = cylinder
	
	# Position et orientation
	var center = (start + end_pos) / 2.0
	mesh_instance.position = center
	mesh_instance.look_at_from_position(center, end_pos, Vector3.UP)
	mesh_instance.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	
	# Couleur selon type
	var mat = StandardMaterial3D.new()
	match pipe["type"]:
		"supply":
			mat.albedo_color = COLOR_SUPPLY
		"hot_supply":
			mat.albedo_color = COLOR_HOT_SUPPLY
		"evacuation":
			mat.albedo_color = COLOR_EVACUATION
	mat.metallic = 0.3
	mat.roughness = 0.4
	mesh_instance.material_override = mat
	
	pipes_container.add_child(mesh_instance)


func _render_fixture(fixture: Dictionary) -> void:
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	
	match fixture["type"]:
		"toilet":
			box.size = Vector3(0.4, 0.4, 0.6)
		"shower":
			box.size = Vector3(0.9, 0.1, 0.9)
		"bathtub":
			box.size = Vector3(0.7, 0.5, 1.5)
		"sink":
			box.size = Vector3(0.5, 0.15, 0.4)
		"washing_machine":
			box.size = Vector3(0.6, 0.85, 0.6)
	
	mesh_instance.mesh = box
	mesh_instance.position = fixture["position"]
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.95)
	mesh_instance.material_override = mat
	
	fixtures_container.add_child(mesh_instance)


func _rebuild_render() -> void:
	for child in pipes_container.get_children():
		child.queue_free()
	for child in fixtures_container.get_children():
		child.queue_free()
	for pipe in pipes:
		_render_pipe(pipe)
	for fixture in fixtures:
		_render_fixture(fixture)


func set_layer_visible(is_visible: bool) -> void:
	visible_layer = is_visible
	pipes_container.visible = is_visible
	fixtures_container.visible = is_visible


func validate() -> Array[String]:
	var errors: Array[String] = []
	for i in pipes.size():
		var pipe = pipes[i]
		if pipe["type"] == "evacuation":
			if pipe["slope"] < MIN_SLOPE:
				errors.append("Tuyau %d : pente insuffisante (%.3f%%)" % [i, pipe["slope"] * 100])
			if pipe["diameter"] < EVACUATION_DIAMETER_MIN:
				errors.append("Tuyau %d : diamètre évacuation trop petit (%d mm)" % [i, pipe["diameter"]])
		else:
			if pipe["diameter"] < SUPPLY_DIAMETER_MIN or pipe["diameter"] > SUPPLY_DIAMETER_MAX:
				errors.append("Tuyau %d : diamètre arrivée hors norme (%d mm)" % [i, pipe["diameter"]])
	return errors


func to_dict() -> Dictionary:
	var pipes_data := []
	for pipe in pipes:
		pipes_data.append({
			"type": pipe["type"],
			"start": {"x": pipe["start"].x, "y": pipe["start"].y, "z": pipe["start"].z},
			"end": {"x": pipe["end"].x, "y": pipe["end"].y, "z": pipe["end"].z},
			"diameter": pipe["diameter"],
			"room": pipe["room"],
			"slope": pipe["slope"],
		})
	var fixtures_data := []
	for fixture in fixtures:
		fixtures_data.append({
			"type": fixture["type"],
			"position": {"x": fixture["position"].x, "y": fixture["position"].y, "z": fixture["position"].z},
			"room": fixture["room"],
			"supply_diameter": fixture["supply_diameter"],
			"evacuation_diameter": fixture["evacuation_diameter"],
		})
	return {"pipes": pipes_data, "fixtures": fixtures_data}


func from_dict(data: Dictionary) -> void:
	pipes.clear()
	fixtures.clear()
	_rebuild_render()
	for p in data.get("pipes", []):
		var s = p.get("start", {})
		var e = p.get("end", {})
		add_pipe(p.get("type", "supply"), Vector3(s.get("x", 0), s.get("y", 0), s.get("z", 0)), Vector3(e.get("x", 0), e.get("y", 0), e.get("z", 0)), p.get("diameter", 12.0), p.get("room", ""))
	for f in data.get("fixtures", []):
		var pos = f.get("position", {})
		add_fixture(f.get("type", "sink"), Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0)), f.get("room", ""))
