extends Node3D
class_name DomoticsModule

## Module Domotique — HouseMaster 3D
## Capteurs : mouvement, température, ouverture
## Actionneurs : lumières, volets, chauffage
## Scénarios : règles IF/THEN

signal DOMOTICS_UPDATED
signal SENSOR_ADDED(sensor: Dictionary)
signal ACTUATOR_ADDED(actuator: Dictionary)
signal SCENARIO_ADDED(scenario: Dictionary)

# --- Types ---
const SENSOR_TYPES := ["motion", "temperature", "opening", "humidity", "light_level"]
const ACTUATOR_TYPES := ["light", "shutter", "heating", "alarm", "lock"]

# --- Couleurs ---
const COLOR_SENSOR: Color = Color(0.2, 0.8, 0.3)
const COLOR_ACTUATOR: Color = Color(0.8, 0.4, 0.2)
const COLOR_SCENARIO_LINK: Color = Color(0.5, 0.2, 0.8)

# --- Données ---
var sensors: Array[Dictionary] = []
# Format : {
#   "type": String,
#   "position": Vector3,
#   "room": String,
#   "label": String,
#   "state": Variant (valeur courante simulée)
# }

var actuators: Array[Dictionary] = []
# Format : {
#   "type": String,
#   "position": Vector3,
#   "room": String,
#   "label": String,
#   "state": Variant
# }

var scenarios: Array[Dictionary] = []
# Format : {
#   "name": String,
#   "conditions": Array[Dictionary],  # {"sensor_index": int, "operator": String, "value": Variant}
#   "actions": Array[Dictionary],     # {"actuator_index": int, "action": String, "value": Variant}
#   "enabled": bool,
#   "time_condition": String           # "any" / "20:00-06:00" etc.
# }

# --- Nœuds rendu ---
var sensors_container: Node3D = null
var actuators_container: Node3D = null
var links_container: Node3D = null
var visible_layer: bool = true


func _ready() -> void:
	sensors_container = Node3D.new()
	sensors_container.name = "SensorsContainer"
	add_child(sensors_container)
	
	actuators_container = Node3D.new()
	actuators_container.name = "ActuatorsContainer"
	add_child(actuators_container)
	
	links_container = Node3D.new()
	links_container.name = "ScenarioLinksContainer"
	add_child(links_container)


func add_sensor(type: String, pos: Vector3, room_name: String, label: String = "") -> int:
	if type not in SENSOR_TYPES:
		push_warning("Domotique : type de capteur inconnu '%s'" % type)
	
	var sensor := {
		"type": type,
		"position": pos,
		"room": room_name,
		"label": label if label != "" else "%s_%d" % [type, sensors.size()],
		"state": _default_sensor_state(type)
	}
	sensors.append(sensor)
	_render_sensor(sensor)
	SENSOR_ADDED.emit(sensor)
	DOMOTICS_UPDATED.emit()
	return sensors.size() - 1


func remove_sensor(index: int) -> void:
	if index >= 0 and index < sensors.size():
		sensors.remove_at(index)
		_rebuild_render()
		DOMOTICS_UPDATED.emit()


func add_actuator(type: String, pos: Vector3, room_name: String, label: String = "") -> int:
	if type not in ACTUATOR_TYPES:
		push_warning("Domotique : type d'actionneur inconnu '%s'" % type)
	
	var actuator := {
		"type": type,
		"position": pos,
		"room": room_name,
		"label": label if label != "" else "%s_%d" % [type, actuators.size()],
		"state": _default_actuator_state(type)
	}
	actuators.append(actuator)
	_render_actuator(actuator)
	ACTUATOR_ADDED.emit(actuator)
	DOMOTICS_UPDATED.emit()
	return actuators.size() - 1


func remove_actuator(index: int) -> void:
	if index >= 0 and index < actuators.size():
		actuators.remove_at(index)
		_rebuild_render()
		DOMOTICS_UPDATED.emit()


func add_scenario(scenario_name: String, conditions: Array, actions: Array, time_condition: String = "any") -> int:
	var scenario := {
		"name": scenario_name,
		"conditions": conditions,
		"actions": actions,
		"enabled": true,
		"time_condition": time_condition
	}
	scenarios.append(scenario)
	_render_scenario_links(scenarios.size() - 1)
	SCENARIO_ADDED.emit(scenario)
	DOMOTICS_UPDATED.emit()
	return scenarios.size() - 1


func remove_scenario(index: int) -> void:
	if index >= 0 and index < scenarios.size():
		scenarios.remove_at(index)
		_rebuild_render()
		DOMOTICS_UPDATED.emit()


func evaluate_scenarios() -> Array[Dictionary]:
	## Évalue tous les scénarios actifs et retourne les actions déclenchées
	var triggered_actions: Array[Dictionary] = []
	
	for scenario in scenarios:
		if not scenario["enabled"]:
			continue
		
		var all_conditions_met := true
		for condition in scenario["conditions"]:
			var sensor_idx: int = condition.get("sensor_index", -1)
			if sensor_idx < 0 or sensor_idx >= sensors.size():
				all_conditions_met = false
				break
			
			var sensor_state = sensors[sensor_idx]["state"]
			var op: String = condition.get("operator", "==")
			var target_value = condition.get("value", null)
			
			match op:
				"==":
					if sensor_state != target_value:
						all_conditions_met = false
				">":
					if sensor_state <= target_value:
						all_conditions_met = false
				"<":
					if sensor_state >= target_value:
						all_conditions_met = false
				">=":
					if sensor_state < target_value:
						all_conditions_met = false
				"<=":
					if sensor_state > target_value:
						all_conditions_met = false
		
		if all_conditions_met:
			for action in scenario["actions"]:
				triggered_actions.append(action)
				_execute_action(action)
	
	return triggered_actions


func _execute_action(action: Dictionary) -> void:
	var actuator_idx: int = action.get("actuator_index", -1)
	if actuator_idx < 0 or actuator_idx >= actuators.size():
		return
	
	var act: String = action.get("action", "")
	var value = action.get("value", null)
	
	match act:
		"turn_on":
			actuators[actuator_idx]["state"] = true
		"turn_off":
			actuators[actuator_idx]["state"] = false
		"set_value":
			actuators[actuator_idx]["state"] = value
		"toggle":
			actuators[actuator_idx]["state"] = not actuators[actuator_idx]["state"]


func _default_sensor_state(type: String) -> Variant:
	match type:
		"motion":
			return false
		"temperature":
			return 20.0
		"opening":
			return false  # fermé
		"humidity":
			return 50.0
		"light_level":
			return 500.0
	return null


func _default_actuator_state(type: String) -> Variant:
	match type:
		"light":
			return false
		"shutter":
			return 100  # % ouvert
		"heating":
			return 20.0  # consigne °C
		"alarm":
			return false
		"lock":
			return true  # verrouillé
	return null


func _render_sensor(sensor: Dictionary) -> void:
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	mesh_instance.mesh = sphere
	mesh_instance.position = sensor["position"]
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = COLOR_SENSOR
	mat.emission_enabled = true
	mat.emission = COLOR_SENSOR
	mat.emission_energy_multiplier = 0.3
	mesh_instance.material_override = mat
	
	sensors_container.add_child(mesh_instance)


func _render_actuator(actuator: Dictionary) -> void:
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.08, 0.08, 0.04)
	mesh_instance.mesh = box
	mesh_instance.position = actuator["position"]
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = COLOR_ACTUATOR
	mat.emission_enabled = true
	mat.emission = COLOR_ACTUATOR
	mat.emission_energy_multiplier = 0.3
	mesh_instance.material_override = mat
	
	actuators_container.add_child(mesh_instance)


func _render_scenario_links(scenario_index: int) -> void:
	if scenario_index < 0 or scenario_index >= scenarios.size():
		return
	var scenario = scenarios[scenario_index]
	
	# Dessiner les liens entre capteurs et actionneurs
	for condition in scenario["conditions"]:
		var sensor_idx: int = condition.get("sensor_index", -1)
		if sensor_idx < 0 or sensor_idx >= sensors.size():
			continue
		for action in scenario["actions"]:
			var actuator_idx: int = action.get("actuator_index", -1)
			if actuator_idx < 0 or actuator_idx >= actuators.size():
				continue
			_render_link(sensors[sensor_idx]["position"], actuators[actuator_idx]["position"])


func _render_link(start: Vector3, end_pos: Vector3) -> void:
	var direction = end_pos - start
	var length = direction.length()
	if length < 0.001:
		return
	
	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.003
	cylinder.bottom_radius = 0.003
	cylinder.height = length
	mesh_instance.mesh = cylinder
	
	var center = (start + end_pos) / 2.0
	mesh_instance.position = center
	mesh_instance.look_at_from_position(center, end_pos, Vector3.UP)
	mesh_instance.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = COLOR_SCENARIO_LINK
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.6
	mesh_instance.material_override = mat
	
	links_container.add_child(mesh_instance)


func _rebuild_render() -> void:
	if sensors_container:
		for child in sensors_container.get_children():
			child.queue_free()
	if actuators_container:
		for child in actuators_container.get_children():
			child.queue_free()
	if links_container:
		for child in links_container.get_children():
			child.queue_free()
	for sensor in sensors:
		_render_sensor(sensor)
	for actuator in actuators:
		_render_actuator(actuator)
	for i in scenarios.size():
		_render_scenario_links(i)


func set_layer_visible(is_visible: bool) -> void:
	visible_layer = is_visible
	if sensors_container:
		sensors_container.visible = is_visible
	if actuators_container:
		actuators_container.visible = is_visible
	if links_container:
		links_container.visible = is_visible


func to_dict() -> Dictionary:
	var sensors_data := []
	for s in sensors:
		sensors_data.append({
			"type": s["type"],
			"position": {"x": s["position"].x, "y": s["position"].y, "z": s["position"].z},
			"room": s["room"],
			"label": s["label"],
		})
	var actuators_data := []
	for a in actuators:
		actuators_data.append({
			"type": a["type"],
			"position": {"x": a["position"].x, "y": a["position"].y, "z": a["position"].z},
			"room": a["room"],
			"label": a["label"],
		})
	return {
		"sensors": sensors_data,
		"actuators": actuators_data,
		"scenarios": scenarios
	}


func from_dict(data: Dictionary) -> void:
	sensors.clear()
	actuators.clear()
	scenarios.clear()
	_rebuild_render()
	
	for s in data.get("sensors", []):
		var pos = s.get("position", {})
		add_sensor(s.get("type", "motion"), Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0)),
			s.get("room", ""), s.get("label", ""))
	for a in data.get("actuators", []):
		var pos = a.get("position", {})
		add_actuator(a.get("type", "light"), Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0)),
			a.get("room", ""), a.get("label", ""))
	for sc in data.get("scenarios", []):
		add_scenario(sc.get("name", ""), sc.get("conditions", []), sc.get("actions", []),
			sc.get("time_condition", "any"))
