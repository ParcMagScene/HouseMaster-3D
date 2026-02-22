extends RefCounted

## LightingEdge — Arête de liaison éclairage
## Câble, liaison switch-luminaire, circuit

class_name LightingEdge

var id: int = -1
var edge_type: String = "cable"  # cable, switch_link, dimmer_link, detector_link
var from_node_id: int = -1
var to_node_id: int = -1
var circuit_id: int = -1

# Propriétés câble
var cable_section_mm2: float = 1.5
var cable_length_m: float = 0.0
var cable_type: String = "standard"  # standard, siliconé, blindé

# Propriétés liaison
var is_wireless: bool = false
var protocol: String = ""  # dali, dmx, zigbee, wifi


func get_length() -> float:
	return cable_length_m


func get_section() -> float:
	return cable_section_mm2


func to_dict() -> Dictionary:
	return {
		"id": id,
		"edge_type": edge_type,
		"from_node_id": from_node_id,
		"to_node_id": to_node_id,
		"circuit_id": circuit_id,
		"cable_section_mm2": cable_section_mm2,
		"cable_length_m": cable_length_m,
		"cable_type": cable_type,
		"is_wireless": is_wireless,
		"protocol": protocol,
	}


static func from_dict(data: Dictionary) -> LightingEdge:
	var edge = LightingEdge.new()
	edge.id = data.get("id", -1)
	edge.edge_type = data.get("edge_type", "cable")
	edge.from_node_id = data.get("from_node_id", -1)
	edge.to_node_id = data.get("to_node_id", -1)
	edge.circuit_id = data.get("circuit_id", -1)
	edge.cable_section_mm2 = data.get("cable_section_mm2", 1.5)
	edge.cable_length_m = data.get("cable_length_m", 0.0)
	edge.cable_type = data.get("cable_type", "standard")
	edge.is_wireless = data.get("is_wireless", false)
	edge.protocol = data.get("protocol", "")
	return edge
