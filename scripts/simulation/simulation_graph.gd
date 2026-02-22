extends RefCounted

## SimulationGraph — Graphe orienté pour la simulation des réseaux
## Contient nœuds et arêtes, fournit traversée et analyse topologique

class_name SimulationGraph

var nodes: Dictionary = {}  # id -> SimulationNode
var edges: Dictionary = {}  # id -> SimulationEdge
var _next_node_id: int = 0
var _next_edge_id: int = 0


func add_node(node_type: String, network: String, pos: Vector3 = Vector3.ZERO, room: String = "", label: String = "") -> int:
	var id := _next_node_id
	_next_node_id += 1
	var node := SimulationNode.new(id, node_type, network)
	node.position = pos
	node.room = room
	node.label = label if label != "" else "%s_%d" % [node_type, id]
	nodes[id] = node
	return id


func remove_node(id: int) -> void:
	if not nodes.has(id):
		return
	var node: SimulationNode = nodes[id]
	var edge_ids := node.edges_in.duplicate()
	edge_ids.append_array(node.edges_out)
	for eid in edge_ids:
		remove_edge(eid)
	nodes.erase(id)


func add_edge(from_id: int, to_id: int, edge_type: String, network: String, props: Dictionary = {}) -> int:
	if not nodes.has(from_id) or not nodes.has(to_id):
		return -1
	var id := _next_edge_id
	_next_edge_id += 1
	var edge := SimulationEdge.new(id, from_id, to_id)
	edge.edge_type = edge_type
	edge.network = network
	edge.properties = props
	edges[id] = edge
	nodes[from_id].add_edge_out(id)
	nodes[to_id].add_edge_in(id)
	return id


func remove_edge(id: int) -> void:
	if not edges.has(id):
		return
	var edge: SimulationEdge = edges[id]
	if nodes.has(edge.from_node):
		nodes[edge.from_node].remove_edge(id)
	if nodes.has(edge.to_node):
		nodes[edge.to_node].remove_edge(id)
	edges.erase(id)


func get_node(id: int) -> SimulationNode:
	return nodes.get(id, null)


func get_edge(id: int) -> SimulationEdge:
	return edges.get(id, null)


func get_nodes_by_network(network: String) -> Array:
	var result := []
	for node in nodes.values():
		if node.network == network:
			result.append(node)
	return result


func get_edges_by_network(network: String) -> Array:
	var result := []
	for edge in edges.values():
		if edge.network == network:
			result.append(edge)
	return result


func get_neighbors(node_id: int) -> Array:
	var result := []
	if not nodes.has(node_id):
		return result
	var node: SimulationNode = nodes[node_id]
	for eid in node.edges_out:
		if edges.has(eid):
			result.append(edges[eid].to_node)
	for eid in node.edges_in:
		if edges.has(eid):
			result.append(edges[eid].from_node)
	return result


func get_total_edge_length(network: String = "") -> float:
	var total := 0.0
	for edge in edges.values():
		if network == "" or edge.network == network:
			total += edge.get_length()
	return total


func get_connected_components(network: String = "") -> Array:
	var visited := {}
	var components := []
	var node_ids := []
	for node in nodes.values():
		if network == "" or node.network == network:
			node_ids.append(node.id)
	for nid in node_ids:
		if visited.has(nid):
			continue
		var component := []
		var stack := [nid]
		while stack.size() > 0:
			var current = stack.pop_back()
			if visited.has(current):
				continue
			visited[current] = true
			component.append(current)
			for neighbor in get_neighbors(current):
				if not visited.has(neighbor) and neighbor in node_ids:
					stack.append(neighbor)
		components.append(component)
	return components


func find_path(from_id: int, to_id: int) -> Array:
	if not nodes.has(from_id) or not nodes.has(to_id):
		return []
	var visited := {}
	var parent := {}
	var queue := [from_id]
	visited[from_id] = true
	while queue.size() > 0:
		var current = queue.pop_front()
		if current == to_id:
			var path := [to_id]
			var p = to_id
			while parent.has(p):
				p = parent[p]
				path.insert(0, p)
			return path
		for neighbor in get_neighbors(current):
			if not visited.has(neighbor):
				visited[neighbor] = true
				parent[neighbor] = current
				queue.append(neighbor)
	return []


func clear() -> void:
	nodes.clear()
	edges.clear()
	_next_node_id = 0
	_next_edge_id = 0


func to_dict() -> Dictionary:
	var nodes_data := {}
	for id in nodes:
		nodes_data[str(id)] = nodes[id].to_dict()
	var edges_data := {}
	for id in edges:
		edges_data[str(id)] = edges[id].to_dict()
	return {
		"nodes": nodes_data,
		"edges": edges_data,
		"next_node_id": _next_node_id,
		"next_edge_id": _next_edge_id,
	}


func from_dict(data: Dictionary) -> void:
	clear()
	_next_node_id = data.get("next_node_id", 0)
	_next_edge_id = data.get("next_edge_id", 0)
	for key in data.get("nodes", {}).keys():
		var node = SimulationNode.from_dict(data["nodes"][key])
		nodes[node.id] = node
	for key in data.get("edges", {}).keys():
		var edge = SimulationEdge.from_dict(data["edges"][key])
		edges[edge.id] = edge
