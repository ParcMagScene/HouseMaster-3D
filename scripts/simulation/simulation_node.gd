extends RefCounted

## SimulationNode — Nœud de base du graphe de simulation
## Représente un équipement, un point de connexion ou un nœud logique

class_name SimulationNode

var id: int = -1
var node_type: String = ""  # "equipment" / "junction" / "source" / "sink"
var network: String = ""    # "electricity" / "plumbing" / "network" / "heating" / "surveillance" / "domotics" / "lighting"
var position: Vector3 = Vector3.ZERO
var room: String = ""
var label: String = ""
var properties: Dictionary = {}
var edges_in: Array[int] = []
var edges_out: Array[int] = []


func _init(p_id: int = -1, p_type: String = "", p_network: String = "") -> void:
	id = p_id
	node_type = p_type
	network = p_network


func add_edge_in(edge_id: int) -> void:
	if edge_id not in edges_in:
		edges_in.append(edge_id)


func add_edge_out(edge_id: int) -> void:
	if edge_id not in edges_out:
		edges_out.append(edge_id)


func remove_edge(edge_id: int) -> void:
	edges_in.erase(edge_id)
	edges_out.erase(edge_id)


func to_dict() -> Dictionary:
	return {
		"id": id,
		"node_type": node_type,
		"network": network,
		"position": {"x": position.x, "y": position.y, "z": position.z},
		"room": room,
		"label": label,
		"properties": properties,
		"edges_in": edges_in.duplicate(),
		"edges_out": edges_out.duplicate(),
	}


static func from_dict(data: Dictionary) -> SimulationNode:
	var node := SimulationNode.new()
	node.id = data.get("id", -1)
	node.node_type = data.get("node_type", "")
	node.network = data.get("network", "")
	var pos = data.get("position", {})
	node.position = Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0))
	node.room = data.get("room", "")
	node.label = data.get("label", "")
	node.properties = data.get("properties", {})
	node.edges_in = Array(data.get("edges_in", []), TYPE_INT, "", null)
	node.edges_out = Array(data.get("edges_out", []), TYPE_INT, "", null)
	return node
