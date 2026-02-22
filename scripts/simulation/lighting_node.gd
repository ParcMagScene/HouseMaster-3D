extends Node

## LightingNode — Nœud luminaire avec propriétés d'éclairage
## Type, puissance, température couleur, angle, dimmer

class_name LightingNode

signal LIGHTING_NODE_UPDATED

var id: int = -1
var node_type: String = "light"  # light, switch, dimmer, detector, power_supply
var label: String = ""
var position: Vector3 = Vector3.ZERO
var room_id: String = ""

# Propriétés d'éclairage
var light_type: String = "led"  # led, halogen, fluorescent, incandescent
var power_w: float = 0.0
var luminous_flux_lm: float = 0.0
var color_temp_k: int = 4000  # Kelvin
var beam_angle_deg: float = 120.0
var dimmable: bool = false
var height_m: float = 2.5
var is_exterior: bool = false
var ip_rating: String = "IP20"

# État
var is_on: bool = false
var dim_level: float = 1.0  # 0.0 - 1.0

# Connexions
var circuit_id: int = -1
var switch_ids: Array[int] = []
var detector_ids: Array[int] = []


func get_effective_flux() -> float:
	if not is_on:
		return 0.0
	return luminous_flux_lm * dim_level


func get_efficacy() -> float:
	if power_w <= 0:
		return 0.0
	return luminous_flux_lm / power_w  # lm/W


func get_coverage_area_m2() -> float:
	# Approximation de la zone couverte au sol
	var half_angle = deg_to_rad(beam_angle_deg / 2.0)
	var radius = height_m * tan(half_angle)
	return PI * radius * radius


func to_dict() -> Dictionary:
	return {
		"id": id,
		"node_type": node_type,
		"label": label,
		"position": {"x": position.x, "y": position.y, "z": position.z},
		"room_id": room_id,
		"light_type": light_type,
		"power_w": power_w,
		"luminous_flux_lm": luminous_flux_lm,
		"color_temp_k": color_temp_k,
		"beam_angle_deg": beam_angle_deg,
		"dimmable": dimmable,
		"height_m": height_m,
		"is_exterior": is_exterior,
		"ip_rating": ip_rating,
		"circuit_id": circuit_id,
		"switch_ids": switch_ids,
		"detector_ids": detector_ids,
	}


static func from_dict(data: Dictionary) -> LightingNode:
	var node = LightingNode.new()
	node.id = data.get("id", -1)
	node.node_type = data.get("node_type", "light")
	node.label = data.get("label", "")
	var pos = data.get("position", {})
	node.position = Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0))
	node.room_id = data.get("room_id", "")
	node.light_type = data.get("light_type", "led")
	node.power_w = data.get("power_w", 0.0)
	node.luminous_flux_lm = data.get("luminous_flux_lm", 0.0)
	node.color_temp_k = data.get("color_temp_k", 4000)
	node.beam_angle_deg = data.get("beam_angle_deg", 120.0)
	node.dimmable = data.get("dimmable", false)
	node.height_m = data.get("height_m", 2.5)
	node.is_exterior = data.get("is_exterior", false)
	node.ip_rating = data.get("ip_rating", "IP20")
	node.circuit_id = data.get("circuit_id", -1)
	node.switch_ids = []
	for sid in data.get("switch_ids", []):
		node.switch_ids.append(sid)
	node.detector_ids = []
	for did in data.get("detector_ids", []):
		node.detector_ids.append(did)
	return node
