extends RefCounted

## LightingSimulator — Simulation éclairage
## NF C 15-100 éclairage, circuits 10A, section 1.5mm², variateurs, détecteurs, cônes

class_name LightingSimulator

# --- Constantes métier NF C 15-100 ---
const MAX_LIGHTS_PER_CIRCUIT := 8
const CIRCUIT_BREAKER_A := 10         # A pour circuit éclairage
const MIN_SECTION_MM2 := 1.5          # mm² minimum éclairage
const MAX_POWER_PER_CIRCUIT_W := 2300  # 10A × 230V
const VOLTAGE := 230.0

# Niveaux d'éclairement recommandés (lux)
const LUX_REQUIREMENTS := {
	"living_room": 300, "bedroom": 150, "kitchen": 500, "bathroom": 200,
	"office": 500, "hallway": 100, "garage": 100, "exterior": 50,
	"staircase": 150, "closet": 100, "laundry": 200, "dining_room": 300,
}
const DEFAULT_LUX := 200

# Efficacité lumineuse (lm/W)
const EFFICACY := {
	"led": 100.0, "halogen": 15.0, "fluorescent": 60.0, "incandescent": 12.0,
}

# IP minimum par zone
const IP_REQUIREMENTS := {
	"bathroom": "IP44", "exterior": "IP65", "garage": "IP44",
}

# Seuils
const MIN_EFFICACY_LMW := 50.0  # Efficacité minimale recommandée
const MAX_COLOR_TEMP_K := 6500
const MIN_COLOR_TEMP_K := 2700
const MAX_CABLE_LENGTH_M := 25.0  # Longueur max câble éclairage avant chute


func simulate(graph: SimulationGraph) -> SimulationReport:
	var report := SimulationReport.new("lighting")
	var light_nodes := graph.get_nodes_by_network("lighting")
	var light_edges := graph.get_edges_by_network("lighting")

	if light_nodes.size() == 0:
		report.set_metric("total_lights", 0)
		report.set_metric("total_power_w", 0)
		return report

	var light_count := 0
	var switch_count := 0
	var dimmer_count := 0
	var detector_count := 0
	var total_power := 0.0
	var total_flux := 0.0
	var circuits := {}  # circuit_id -> {count, power, lights}
	var rooms_lighting := {}

	# Analyse des noeuds
	for node in light_nodes:
		var circuit_id = node.properties.get("circuit_id", -1)

		match node.node_type:
			"light":
				light_count += 1
				var power = node.properties.get("power_w", 0.0)
				var flux = node.properties.get("luminous_flux_lm", 0.0)
				var light_type = node.properties.get("light_type", "led")
				total_power += power
				total_flux += flux

				# Enregistrer dans le circuit
				if circuit_id >= 0:
					if not circuits.has(circuit_id):
						circuits[circuit_id] = {"count": 0, "power": 0.0}
					circuits[circuit_id]["count"] += 1
					circuits[circuit_id]["power"] += power

				# Efficacité
				var efficacy = flux / power if power > 0 else 0.0
				if efficacy < MIN_EFFICACY_LMW and power > 0:
					report.add_suggestion("LIGHT_LOW_EFFICACY", "Luminaire '%s' : %.0f lm/W, LED recommandé (>%.0f)" % [node.label, efficacy, MIN_EFFICACY_LMW], node.id)

				# Température couleur
				var color_temp = node.properties.get("color_temp_k", 4000)
				if color_temp < MIN_COLOR_TEMP_K or color_temp > MAX_COLOR_TEMP_K:
					report.add_warning("LIGHT_COLOR_TEMP", "Luminaire '%s' : %dK hors plage %d-%dK" % [node.label, color_temp, MIN_COLOR_TEMP_K, MAX_COLOR_TEMP_K], node.id)

				# IP par zone
				var room_type = node.properties.get("room_type", "")
				var ip_rating = node.properties.get("ip_rating", "IP20")
				if IP_REQUIREMENTS.has(room_type):
					var required_ip = IP_REQUIREMENTS[room_type]
					if _ip_value(ip_rating) < _ip_value(required_ip):
						report.add_error("LIGHT_IP_INSUFFICIENT", "Luminaire '%s' : %s < %s requis pour %s" % [node.label, ip_rating, required_ip, room_type], node.id)

				# Accumulation par pièce
				var room_id = node.properties.get("room_id", "")
				if room_id != "":
					if not rooms_lighting.has(room_id):
						rooms_lighting[room_id] = {"flux": 0.0, "area": node.properties.get("room_area_m2", 0.0), "type": room_type}
					rooms_lighting[room_id]["flux"] += flux

			"switch":
				switch_count += 1

			"dimmer":
				dimmer_count += 1
				var max_power = node.properties.get("max_power_w", 300.0)
				# Vérifier la charge du variateur
				var controlled_power := 0.0
				for other_node in light_nodes:
					if other_node.node_type == "light":
						var switch_ids = other_node.properties.get("switch_ids", [])
						if node.id in switch_ids:
							controlled_power += other_node.properties.get("power_w", 0.0)
				if controlled_power > max_power:
					report.add_error("LIGHT_DIMMER_OVERLOAD", "Variateur '%s' : %.0fW > max %.0fW" % [node.label, controlled_power, max_power], node.id)

			"detector":
				detector_count += 1
				var detection_range = node.properties.get("range_m", 6.0)
				var detection_angle = node.properties.get("angle_deg", 180.0)

	# Vérifier circuits
	for cid in circuits:
		var cdata = circuits[cid]
		if cdata["count"] > MAX_LIGHTS_PER_CIRCUIT:
			report.add_error("LIGHT_CIRCUIT_COUNT", "Circuit %d : %d luminaires > max %d (NF C 15-100)" % [cid, cdata["count"], MAX_LIGHTS_PER_CIRCUIT])
		if cdata["power"] > MAX_POWER_PER_CIRCUIT_W:
			report.add_error("LIGHT_CIRCUIT_POWER", "Circuit %d : %.0fW > max %.0fW (10A)" % [cid, cdata["power"], MAX_POWER_PER_CIRCUIT_W])
		elif cdata["power"] > MAX_POWER_PER_CIRCUIT_W * 0.8:
			report.add_warning("LIGHT_CIRCUIT_NEAR_MAX", "Circuit %d : %.0fW, proche du max %.0fW" % [cid, cdata["power"], MAX_POWER_PER_CIRCUIT_W])

	# Vérifier éclairement par pièce
	for room_id in rooms_lighting:
		var rdata = rooms_lighting[room_id]
		if rdata["area"] > 0:
			var actual_lux = rdata["flux"] / rdata["area"]
			var required_lux = LUX_REQUIREMENTS.get(rdata["type"], DEFAULT_LUX)
			if actual_lux < required_lux * 0.7:
				report.add_warning("LIGHT_LUX_LOW", "Pièce %s : %.0f lux < %.0f requis" % [str(room_id), actual_lux, required_lux])
			elif actual_lux > required_lux * 2.0:
				report.add_suggestion("LIGHT_LUX_HIGH", "Pièce %s : %.0f lux >> %.0f requis, énergie gaspillée" % [str(room_id), actual_lux, required_lux])

	# Vérifier câbles
	var total_cable_length := 0.0
	for edge in light_edges:
		var length = edge.get_length()
		total_cable_length += length
		var section = edge.get_section()

		if section < MIN_SECTION_MM2:
			report.add_error("LIGHT_SECTION_LOW", "Câble %d : %.1f mm² < min %.1f mm²" % [edge.id, section, MIN_SECTION_MM2])

		if length > MAX_CABLE_LENGTH_M:
			report.add_warning("LIGHT_CABLE_LENGTH", "Câble %d : %.1fm, chute de tension possible" % [edge.id, length])

	# Luminaires sans interrupteur
	if light_count > 0 and switch_count == 0 and dimmer_count == 0:
		report.add_error("LIGHT_NO_SWITCH", "Aucun interrupteur pour %d luminaire(s)" % light_count)

	# Composants connectés
	var components = graph.get_connected_components("lighting")
	if components.size() > 1:
		report.add_warning("LIGHT_DISCONNECTED", "%d circuits éclairage non connectés" % components.size())

	report.set_metric("total_lights", light_count)
	report.set_metric("total_switches", switch_count)
	report.set_metric("total_dimmers", dimmer_count)
	report.set_metric("total_detectors", detector_count)
	report.set_metric("total_power_w", total_power)
	report.set_metric("total_flux_lm", total_flux)
	report.set_metric("total_circuits", circuits.size())
	report.set_metric("total_cable_length_m", total_cable_length)
	report.set_metric("rooms_lit", rooms_lighting.size())

	return report


func _ip_value(ip_str: String) -> int:
	# Convertir IP20, IP44, IP65 etc. en valeur numérique
	var cleaned = ip_str.replace("IP", "")
	return cleaned.to_int() if cleaned.is_valid_int() else 0
