extends RefCounted

## ElectricitySimulator — Simulation électrique NF C 15-100
## Circuits, intensité, surcharge, longueurs, sections

class_name ElectricitySimulator

# --- Constantes NF C 15-100 ---
const MAX_SOCKETS_PER_CIRCUIT := 8
const MAX_LIGHTS_PER_CIRCUIT := 8
const BREAKER_SIZES := [10, 16, 20, 25, 32, 40, 63]
const SECTION_BY_BREAKER := {10: 1.5, 16: 1.5, 20: 2.5, 25: 4.0, 32: 6.0, 40: 10.0, 63: 16.0}
const MAX_LENGTH_BY_SECTION := {1.5: 16.0, 2.5: 22.0, 4.0: 28.0, 6.0: 36.0, 10.0: 46.0, 16.0: 58.0}
const VOLTAGE := 230.0
const POWER_PER_SOCKET := 2300.0  # W (230V × 10A)
const POWER_PER_LIGHT := 100.0   # W


func simulate(graph: SimulationGraph) -> SimulationReport:
	var report := SimulationReport.new("electricity")
	var elec_nodes := graph.get_nodes_by_network("electricity")
	var elec_edges := graph.get_edges_by_network("electricity")

	if elec_nodes.size() == 0:
		report.set_metric("total_circuits", 0)
		report.set_metric("total_elements", 0)
		report.set_metric("total_power_w", 0.0)
		return report

	# Compteurs
	var circuits := {}
	var total_power := 0.0
	var total_intensity := 0.0
	var total_elements := 0

	# Regrouper par circuit
	for node in elec_nodes:
		var circuit_id = node.properties.get("circuit_id", "default")
		if not circuits.has(circuit_id):
			circuits[circuit_id] = {"nodes": [], "breaker": 16, "type": "mixed", "power": 0.0}
		circuits[circuit_id]["nodes"].append(node)
		circuits[circuit_id]["breaker"] = node.properties.get("breaker_amps", 16)
		circuits[circuit_id]["type"] = node.properties.get("circuit_type", "mixed")
		total_elements += 1

	# Validation par circuit
	for cid in circuits:
		var circuit = circuits[cid]
		var socket_count := 0
		var light_count := 0
		var circuit_power := 0.0

		for node in circuit["nodes"]:
			match node.properties.get("element_type", ""):
				"socket":
					socket_count += 1
					circuit_power += POWER_PER_SOCKET
				"light":
					light_count += 1
					circuit_power += node.properties.get("power_w", POWER_PER_LIGHT)
				"outlet_32a":
					circuit_power += 7360.0

		circuit["power"] = circuit_power
		total_power += circuit_power

		# Max prises par circuit
		if socket_count > MAX_SOCKETS_PER_CIRCUIT:
			report.add_error("ELEC_MAX_SOCKETS", "Circuit '%s' : %d prises (max %d)" % [cid, socket_count, MAX_SOCKETS_PER_CIRCUIT])

		# Max points lumineux
		if light_count > MAX_LIGHTS_PER_CIRCUIT:
			report.add_error("ELEC_MAX_LIGHTS", "Circuit '%s' : %d luminaires (max %d)" % [cid, light_count, MAX_LIGHTS_PER_CIRCUIT])

		# Vérification disjoncteur
		var breaker = circuit["breaker"]
		if breaker not in BREAKER_SIZES:
			report.add_error("ELEC_BREAKER_INVALID", "Circuit '%s' : disjoncteur %dA non standard" % [cid, breaker])

		# Intensité du circuit
		var intensity = circuit_power / VOLTAGE
		if intensity > breaker:
			report.add_error("ELEC_OVERLOAD", "Circuit '%s' : intensité %.1fA dépasse disjoncteur %dA" % [cid, intensity, breaker])
		elif intensity > breaker * 0.8:
			report.add_warning("ELEC_HIGH_LOAD", "Circuit '%s' : charge élevée %.1fA / %dA (>80%%)" % [cid, intensity, breaker])

		# Section minimale
		var min_section = SECTION_BY_BREAKER.get(breaker, 2.5)
		var circuit_section = circuit["nodes"][0].properties.get("section_mm2", min_section) if circuit["nodes"].size() > 0 else min_section
		if circuit_section < min_section:
			report.add_error("ELEC_SECTION_LOW", "Circuit '%s' : section %.1f mm² < min %.1f mm²" % [cid, circuit_section, min_section])

	# Longueurs câbles
	for edge in elec_edges:
		var length = edge.get_length()
		var section = edge.properties.get("section_mm2", 1.5)
		var max_length = MAX_LENGTH_BY_SECTION.get(section, 20.0)
		if length > max_length:
			report.add_warning("ELEC_LENGTH_MAX", "Câble %d : %.1fm dépasse max %.1fm pour section %.1f mm²" % [edge.id, length, max_length, section])

	# Composants connectés
	var components = graph.get_connected_components("electricity")
	if components.size() > 1:
		report.add_warning("ELEC_DISCONNECTED", "%d sous-réseaux électriques non connectés" % components.size())

	total_intensity = total_power / VOLTAGE

	report.set_metric("total_circuits", circuits.size())
	report.set_metric("total_elements", total_elements)
	report.set_metric("total_power_w", total_power)
	report.set_metric("total_intensity_a", total_intensity)
	report.set_metric("total_cable_length_m", graph.get_total_edge_length("electricity"))

	if total_intensity > 63:
		report.add_suggestion("ELEC_MAIN_BREAKER", "Intensité totale %.1fA, considérer un abonnement > 63A" % total_intensity)

	return report
