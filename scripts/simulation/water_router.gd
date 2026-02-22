extends RefCounted

## WaterRouter — Routage des canalisations eau
## Calcule pentes, évite croisements, optimise longueurs

class_name WaterRouter

# --- Constantes ---
const MIN_SLOPE := 0.01       # 1% pente minimum évacuation
const OPTIMAL_SLOPE := 0.03   # 3% pente optimale
const MAX_SLOPE := 0.05       # 5% pente maximum
const GRAVITY := 9.81

const PIPE_MATERIALS := {
	"pex": {"cost_per_m": 3.0, "min_radius_mm": 50.0, "max_temp_c": 95.0},
	"copper": {"cost_per_m": 8.0, "min_radius_mm": 40.0, "max_temp_c": 120.0},
	"pvc": {"cost_per_m": 2.0, "min_radius_mm": 60.0, "max_temp_c": 60.0},
	"multicouche": {"cost_per_m": 4.0, "min_radius_mm": 45.0, "max_temp_c": 95.0},
}

const MIN_HORIZONTAL_COVER_MM := 200.0  # Sous dalle
const MIN_WALL_DISTANCE_MM := 30.0
const MAX_STRAIGHT_RUN_M := 8.0  # Avant point fixe
const ANTI_BELIER_THRESHOLD_LS := 0.5  # Débit seuil anti-bélier


func route_water(graph: SimulationGraph, room_data: Array) -> Dictionary:
	var result := {
		"routes": [],
		"total_supply_length": 0.0,
		"total_evac_length": 0.0,
		"slope_corrections": [],
		"warnings": [],
		"errors": [],
	}

	var plumb_edges = graph.get_edges_by_network("plumbing")
	if plumb_edges.size() == 0:
		return result

	for edge in plumb_edges:
		var from_node = graph.get_node(edge.from_node)
		var to_node = graph.get_node(edge.to_node)

		if not from_node or not to_node:
			result["errors"].append("Tuyau %d : noeud introuvable" % edge.id)
			continue

		var pipe_type = edge.properties.get("pipe_type", "supply")
		var route = _calculate_water_route(from_node, to_node, edge, pipe_type)
		result["routes"].append(route)

		if pipe_type == "evacuation":
			result["total_evac_length"] += route["length"]

			# Vérifier et corriger la pente
			var slope = route["slope"]
			if slope < MIN_SLOPE:
				var correction = {
					"edge_id": edge.id,
					"current_slope": slope,
					"required_slope": MIN_SLOPE,
					"height_adjustment_m": (MIN_SLOPE - slope) * route["horizontal_length"],
				}
				result["slope_corrections"].append(correction)
				result["errors"].append("Tuyau évac %d : pente %.3f < min %.3f, ajuster de %.3fm" % [edge.id, slope, MIN_SLOPE, correction["height_adjustment_m"]])
		else:
			result["total_supply_length"] += route["length"]

	# Détecter croisements
	_detect_crossings(result)

	# Vérifier anti-bélier
	_check_water_hammer(graph, result)

	# Vérifier matériaux compatibles
	_check_materials(graph, result)

	return result


func _calculate_water_route(from_node: SimulationNode, to_node: SimulationNode, edge: SimulationEdge, pipe_type: String) -> Dictionary:
	var start = from_node.position
	var end = to_node.position

	var horizontal_length = Vector2(end.x - start.x, end.z - start.z).length()
	var height_diff = start.y - end.y  # Positif = descente
	var slope = height_diff / horizontal_length if horizontal_length > 0 else 0.0
	var total_length = start.distance_to(end)

	var route := {
		"edge_id": edge.id,
		"from": from_node.id,
		"to": to_node.id,
		"length": total_length,
		"horizontal_length": horizontal_length,
		"height_diff": height_diff,
		"slope": slope,
		"pipe_type": pipe_type,
		"segments": [],
	}

	if pipe_type == "evacuation":
		# Route d'évacuation : doit descendre progressivement
		route["segments"] = _create_gravity_route(start, end, OPTIMAL_SLOPE)
	else:
		# Route d'arrivée : peut monter/descendre librement
		route["segments"] = _create_pressure_route(start, end)

	return route


func _create_gravity_route(start: Vector3, end: Vector3, target_slope: float) -> Array:
	var segments := []
	var horizontal_dist = Vector2(end.x - start.x, end.z - start.z).length()
	var required_drop = horizontal_dist * target_slope

	# Segment horizontal avec pente constante
	var intermediate_y = start.y - required_drop

	# Si la destination est plus basse que prévu, c'est OK
	if end.y <= intermediate_y:
		segments.append({
			"start": start,
			"end": Vector3(end.x, intermediate_y, end.z),
			"slope": target_slope,
			"type": "gravity_run",
		})
		if abs(intermediate_y - end.y) > 0.01:
			segments.append({
				"start": Vector3(end.x, intermediate_y, end.z),
				"end": end,
				"slope": 0.0,
				"type": "vertical_drop",
			})
	else:
		# Destination plus haute : problème de pente
		segments.append({
			"start": start,
			"end": end,
			"slope": (start.y - end.y) / horizontal_dist if horizontal_dist > 0 else 0.0,
			"type": "gravity_run",
		})

	return segments


func _create_pressure_route(start: Vector3, end: Vector3) -> Array:
	var segments := []

	# Route Manhattan 3D pour suivre les murs
	if abs(start.x - end.x) > 0.01:
		segments.append({
			"start": start,
			"end": Vector3(end.x, start.y, start.z),
			"type": "horizontal_x",
		})

	if abs(start.z - end.z) > 0.01:
		segments.append({
			"start": Vector3(end.x, start.y, start.z),
			"end": Vector3(end.x, start.y, end.z),
			"type": "horizontal_z",
		})

	if abs(start.y - end.y) > 0.01:
		segments.append({
			"start": Vector3(end.x, start.y, end.z),
			"end": end,
			"type": "vertical",
		})

	return segments


func _detect_crossings(result: Dictionary) -> void:
	var routes = result["routes"]
	for i in range(routes.size()):
		for j in range(i + 1, routes.size()):
			# Approximation : vérifier si les routes passent par des zones proches
			var r1 = routes[i]
			var r2 = routes[j]
			for s1 in r1.get("segments", []):
				for s2 in r2.get("segments", []):
					var mid1 = (s1.get("start", Vector3.ZERO) + s1.get("end", Vector3.ZERO)) / 2.0
					var mid2 = (s2.get("start", Vector3.ZERO) + s2.get("end", Vector3.ZERO)) / 2.0
					if mid1.distance_to(mid2) < 0.1:  # 10cm
						result["warnings"].append("Croisement potentiel tuyaux %d et %d" % [r1["edge_id"], r2["edge_id"]])


func _check_water_hammer(graph: SimulationGraph, result: Dictionary) -> void:
	var plumb_nodes = graph.get_nodes_by_network("plumbing")
	for node in plumb_nodes:
		if node.node_type == "equipment":
			var flow = node.properties.get("flow_rate_ls", 0.0)
			if flow > ANTI_BELIER_THRESHOLD_LS:
				var has_anti_hammer = node.properties.get("anti_hammer", false)
				if not has_anti_hammer:
					result["warnings"].append("Appareil '%s' : débit %.1f L/s, anti-bélier recommandé" % [node.label, flow])


func _check_materials(graph: SimulationGraph, result: Dictionary) -> void:
	var plumb_edges = graph.get_edges_by_network("plumbing")
	for edge in plumb_edges:
		var material = edge.properties.get("material", "pex")
		var is_hot = edge.properties.get("hot_water", false)

		if PIPE_MATERIALS.has(material):
			var mat_data = PIPE_MATERIALS[material]
			if is_hot and material == "pvc":
				result["errors"].append("Tuyau %d : PVC incompatible eau chaude (max %.0f°C)" % [edge.id, mat_data["max_temp_c"]])
