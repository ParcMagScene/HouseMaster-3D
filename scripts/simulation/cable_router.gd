extends RefCounted

## CableRouter — Routage de câbles
## Suit murs/plafonds/plinthes, évite obstacles, routes 3D

class_name CableRouter

# --- Constantes ---
const ROUTE_TYPES := ["wall", "ceiling", "floor", "baseboard", "conduit", "tray"]
const MIN_BEND_RADIUS_MM := {"cat6": 25.0, "cat6a": 25.0, "cat7": 35.0, "fiber": 30.0, "electric": 60.0, "copper_pipe": 40.0}
const MAX_CABLES_PER_CONDUIT := 12
const CONDUIT_FILL_RATIO := 0.4  # 40% max remplissage
const MIN_SEPARATION_MM := {"electric_network": 50.0, "electric_water": 200.0, "gas_electric": 200.0}
const WALL_DEPTH_MM := 20.0     # Profondeur saignée
const CEILING_HEIGHT_M := 2.5


func route_cables(graph: SimulationGraph, network: String, room_data: Array) -> Dictionary:
	var result := {
		"routes": [],
		"total_length": 0.0,
		"conduits_needed": 0,
		"warnings": [],
		"errors": [],
	}

	var edges = graph.get_edges_by_network(network)
	if edges.size() == 0:
		return result

	for edge in edges:
		var from_node = graph.get_node(edge.from_node)
		var to_node = graph.get_node(edge.to_node)

		if not from_node or not to_node:
			result["errors"].append("Câble %d : noeud source ou destination introuvable" % edge.id)
			continue

		var route = _calculate_route(from_node, to_node, edge, room_data)
		result["routes"].append(route)
		result["total_length"] += route["length"]

	# Détecter conduits nécessaires
	var segments := {}  # Position clé -> nombre de câbles
	for route in result["routes"]:
		for seg in route.get("segments", []):
			var key = _segment_key(seg)
			if not segments.has(key):
				segments[key] = 0
			segments[key] += 1

	for key in segments:
		if segments[key] > 3:
			result["conduits_needed"] += 1
			if segments[key] > MAX_CABLES_PER_CONDUIT:
				result["warnings"].append("Segment %s : %d câbles, dédoubler le conduit" % [key, segments[key]])

	# Vérifier séparations
	_check_separations(graph, result)

	return result


func _calculate_route(from_node: SimulationNode, to_node: SimulationNode, edge: SimulationEdge, room_data: Array) -> Dictionary:
	var route := {
		"edge_id": edge.id,
		"from": from_node.id,
		"to": to_node.id,
		"length": 0.0,
		"route_type": "wall",
		"segments": [],
	}

	var start = from_node.position
	var end = to_node.position

	# Stratégie : longer les murs (Manhattan routing 3D)
	# 1. Monter/descendre au niveau du plafond ou plinthe
	# 2. Longer le mur en X
	# 3. Longer le mur en Z
	# 4. Descendre/monter vers la destination

	var route_height = CEILING_HEIGHT_M - 0.1  # Sous le plafond

	# Déterminer si on passe par le plafond ou la plinthe
	var avg_y = (start.y + end.y) / 2.0
	if avg_y > CEILING_HEIGHT_M / 2.0:
		route_height = CEILING_HEIGHT_M - 0.1
		route["route_type"] = "ceiling"
	else:
		route_height = 0.15  # Plinthe
		route["route_type"] = "baseboard"

	# Segments du parcours
	var segments := []

	# Segment 1 : vertical depuis le départ
	if abs(start.y - route_height) > 0.01:
		segments.append({
			"start": start,
			"end": Vector3(start.x, route_height, start.z),
			"type": "vertical",
			"length": abs(start.y - route_height),
		})

	# Segment 2 : horizontal X
	if abs(start.x - end.x) > 0.01:
		segments.append({
			"start": Vector3(start.x, route_height, start.z),
			"end": Vector3(end.x, route_height, start.z),
			"type": "horizontal_x",
			"length": abs(start.x - end.x),
		})

	# Segment 3 : horizontal Z
	if abs(start.z - end.z) > 0.01:
		segments.append({
			"start": Vector3(end.x, route_height, start.z),
			"end": Vector3(end.x, route_height, end.z),
			"type": "horizontal_z",
			"length": abs(start.z - end.z),
		})

	# Segment 4 : vertical vers destination
	if abs(route_height - end.y) > 0.01:
		segments.append({
			"start": Vector3(end.x, route_height, end.z),
			"end": end,
			"type": "vertical",
			"length": abs(route_height - end.y),
		})

	route["segments"] = segments

	var total_length := 0.0
	for seg in segments:
		total_length += seg["length"]
	route["length"] = total_length

	return route


func _segment_key(seg: Dictionary) -> String:
	var s = seg.get("start", Vector3.ZERO)
	var e = seg.get("end", Vector3.ZERO)
	var mid = (s + e) / 2.0
	return "%d_%d_%d" % [int(mid.x), int(mid.y), int(mid.z)]


func _check_separations(graph: SimulationGraph, result: Dictionary) -> void:
	# Vérifier séparation entre réseaux incompatibles
	var electric_edges = graph.get_edges_by_network("electricity")
	var water_edges = graph.get_edges_by_network("plumbing")
	var network_edges = graph.get_edges_by_network("network")

	# Vérifier séparation électrique/eau
	for e_edge in electric_edges:
		for w_edge in water_edges:
			var min_dist = _min_edge_distance(graph, e_edge, w_edge)
			if min_dist >= 0 and min_dist < MIN_SEPARATION_MM["electric_water"] / 1000.0:
				result["warnings"].append("Câble élec %d trop proche du tuyau %d (%.0fmm < %.0fmm)" % [e_edge.id, w_edge.id, min_dist * 1000.0, MIN_SEPARATION_MM["electric_water"]])

	# Vérifier séparation électrique/réseau
	for e_edge in electric_edges:
		for n_edge in network_edges:
			var min_dist = _min_edge_distance(graph, e_edge, n_edge)
			if min_dist >= 0 and min_dist < MIN_SEPARATION_MM["electric_network"] / 1000.0:
				result["warnings"].append("Câble élec %d trop proche du câble réseau %d (%.0fmm < %.0fmm)" % [e_edge.id, n_edge.id, min_dist * 1000.0, MIN_SEPARATION_MM["electric_network"]])


func _min_edge_distance(graph: SimulationGraph, edge1: SimulationEdge, edge2: SimulationEdge) -> float:
	var n1_from = graph.get_node(edge1.from_node)
	var n1_to = graph.get_node(edge1.to_node)
	var n2_from = graph.get_node(edge2.from_node)
	var n2_to = graph.get_node(edge2.to_node)

	if not n1_from or not n1_to or not n2_from or not n2_to:
		return -1.0

	# Approximation : distance minimale entre les milieux
	var mid1 = (n1_from.position + n1_to.position) / 2.0
	var mid2 = (n2_from.position + n2_to.position) / 2.0
	return mid1.distance_to(mid2)
