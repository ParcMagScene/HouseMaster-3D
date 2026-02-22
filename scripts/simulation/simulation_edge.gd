extends RefCounted

## SimulationEdge — Arête du graphe de simulation
## Représente un lien entre deux nœuds (câble, tuyau, liaison logique)

class_name SimulationEdge

var id: int = -1
var edge_type: String = ""  # "cable" / "pipe" / "wifi" / "logical"
var network: String = ""
var from_node: int = -1
var to_node: int = -1
var properties: Dictionary = {}
# Properties communes :
#   "length": float (mètres)
#   "section": float (mm²)
#   "diameter": float (mm)
#   "capacity": float
#   "loss": float


func _init(p_id: int = -1, p_from: int = -1, p_to: int = -1) -> void:
	id = p_id
	from_node = p_from
	to_node = p_to


func get_length() -> float:
	return properties.get("length", 0.0)


func get_section() -> float:
	return properties.get("section", 0.0)


func get_diameter() -> float:
	return properties.get("diameter", 0.0)


func to_dict() -> Dictionary:
	return {
		"id": id,
		"edge_type": edge_type,
		"network": network,
		"from_node": from_node,
		"to_node": to_node,
		"properties": properties,
	}


static func from_dict(data: Dictionary) -> SimulationEdge:
	var edge := SimulationEdge.new()
	edge.id = data.get("id", -1)
	edge.edge_type = data.get("edge_type", "")
	edge.network = data.get("network", "")
	edge.from_node = data.get("from_node", -1)
	edge.to_node = data.get("to_node", -1)
	edge.properties = data.get("properties", {})
	return edge
