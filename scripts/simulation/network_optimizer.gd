extends RefCounted

## NetworkOptimizer — Optimisation des chemins réseau
## Chemins optimaux, minimise longueurs/coûts, évite collisions, Dijkstra

class_name NetworkOptimizer

# --- Constantes ---
const COST_PER_METER := {
	"cat6": 0.8, "cat6a": 1.5, "cat7": 2.5, "fiber": 5.0,
	"copper_pipe": 8.0, "pex_pipe": 3.0, "pvc_pipe": 2.0,
	"electric_1.5": 0.5, "electric_2.5": 0.8, "electric_6": 2.0,
}
const DEFAULT_COST_PER_METER := 1.0
const BEND_PENALTY := 0.5       # surcoût par coude
const CROSSING_PENALTY := 2.0   # surcoût par croisement


func optimize_paths(graph: SimulationGraph, network: String) -> Dictionary:
	var result := {
		"optimized_edges": [],
		"total_original_length": 0.0,
		"total_optimized_length": 0.0,
		"cost_savings": 0.0,
		"suggestions": [],
	}

	var edges = graph.get_edges_by_network(network)
	var nodes = graph.get_nodes_by_network(network)

	if edges.size() == 0 or nodes.size() == 0:
		return result

	# Construire matrice d'adjacence pondérée
	var adj := {}  # node_id -> [{to, edge, cost}]
	for node in nodes:
		adj[node.id] = []

	for edge in edges:
		var cost = _calculate_edge_cost(edge)
		result["total_original_length"] += edge.get_length()

		adj[edge.from_node].append({"to": edge.to_node, "edge": edge, "cost": cost})
		# Bidirectionnel pour l'optimisation
		adj[edge.to_node].append({"to": edge.from_node, "edge": edge, "cost": cost})

	# Trouver les nœuds source (panneaux, baies, chaudières)
	var sources := []
	for node in nodes:
		if node.node_type in ["panel", "patch_panel", "boiler", "hub", "switch", "nvr"]:
			sources.append(node.id)

	if sources.size() == 0 and nodes.size() > 0:
		sources.append(nodes[0].id)

	# Dijkstra depuis chaque source
	for source_id in sources:
		var shortest = _dijkstra(adj, source_id, nodes)
		for node in nodes:
			if node.id == source_id:
				continue
			if shortest.has(node.id):
				var path_data = shortest[node.id]
				result["optimized_edges"].append({
					"from": source_id,
					"to": node.id,
					"cost": path_data["cost"],
					"path": path_data["path"],
				})

	# Détecter les câbles redondants
	var edge_usage := {}
	for edge in edges:
		var key = "%d-%d" % [mini(edge.from_node, edge.to_node), maxi(edge.from_node, edge.to_node)]
		if not edge_usage.has(key):
			edge_usage[key] = 0
		edge_usage[key] += 1

	for key in edge_usage:
		if edge_usage[key] > 1:
			result["suggestions"].append("Liaison %s : %d câbles parallèles, mutualisation possible" % [key, edge_usage[key]])

	# Détecter les parcours trop longs vs distance directe
	for edge in edges:
		var from_node = graph.get_node(edge.from_node)
		var to_node = graph.get_node(edge.to_node)
		if from_node and to_node:
			var direct_dist = from_node.position.distance_to(to_node.position)
			if direct_dist > 0 and edge.get_length() > direct_dist * 2.0:
				result["suggestions"].append("Câble %d : %.1fm vs %.1fm direct, parcours non optimal" % [edge.id, edge.get_length(), direct_dist])

	result["total_optimized_length"] = result["total_original_length"]  # base
	result["cost_savings"] = 0.0

	return result


func _calculate_edge_cost(edge: SimulationEdge) -> float:
	var cable_type = edge.properties.get("cable_type", "")
	var cost_per_m = COST_PER_METER.get(cable_type, DEFAULT_COST_PER_METER)
	var length = edge.get_length()
	var bends = edge.properties.get("bends", 0)
	var crossings = edge.properties.get("crossings", 0)

	return length * cost_per_m + bends * BEND_PENALTY + crossings * CROSSING_PENALTY


func _dijkstra(adj: Dictionary, source: int, nodes: Array) -> Dictionary:
	var dist := {}
	var prev := {}
	var visited := {}

	for node in nodes:
		dist[node.id] = INF
		prev[node.id] = -1
	dist[source] = 0.0

	var queue := [source]

	while queue.size() > 0:
		# Trouver le noeud avec la plus petite distance
		var min_dist := INF
		var min_idx := 0
		for i in range(queue.size()):
			if dist[queue[i]] < min_dist:
				min_dist = dist[queue[i]]
				min_idx = i

		var current = queue[min_idx]
		queue.remove_at(min_idx)

		if visited.has(current):
			continue
		visited[current] = true

		if not adj.has(current):
			continue

		for neighbor_data in adj[current]:
			var to = neighbor_data["to"]
			var cost = neighbor_data["cost"]
			var new_dist = dist[current] + cost

			if new_dist < dist.get(to, INF):
				dist[to] = new_dist
				prev[to] = current
				if not visited.has(to):
					queue.append(to)

	# Reconstruire les chemins
	var result := {}
	for node in nodes:
		if node.id == source or dist.get(node.id, INF) == INF:
			continue
		var path := []
		var current = node.id
		while current != -1 and current != source:
			path.insert(0, current)
			current = prev.get(current, -1)
		if current == source:
			path.insert(0, source)
			result[node.id] = {"cost": dist[node.id], "path": path}

	return result
