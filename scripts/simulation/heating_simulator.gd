extends RefCounted

## HeatingSimulator — Simulation chauffage
## Puissance, pertes thermiques, équilibrage

class_name HeatingSimulator

# --- Constantes métier ---
const HEAT_LOSS_COEFF := {
	"well_insulated": 0.6,   # W/m³/°C
	"standard": 1.0,
	"poorly_insulated": 1.6,
}
const DEFAULT_INSULATION := "standard"
const OUTDOOR_TEMP := -5.0   # °C (design temperature)
const INDOOR_TEMP := 20.0    # °C
const SAFETY_MARGIN := 1.2   # 20% de marge
const MIN_POWER_PER_M2 := 70.0   # W/m² minimum
const MAX_POWER_PER_M2 := 150.0  # W/m² maximum
const PIPE_MAX_LENGTH := 80.0    # m boucle plancher chauffant
const PIPE_DELTA_T := 10.0       # °C écart départ/retour
const WATER_CP := 4185.0         # J/(kg·°C)
const MIN_RADIATOR_HEIGHT := 0.3 # m du sol


func simulate(graph: SimulationGraph) -> SimulationReport:
	var report := SimulationReport.new("heating")
	var heat_nodes := graph.get_nodes_by_network("heating")
	var heat_edges := graph.get_edges_by_network("heating")

	if heat_nodes.size() == 0:
		report.set_metric("total_emitters", 0)
		report.set_metric("total_power_w", 0)
		return report

	var emitter_count := 0
	var boiler_count := 0
	var total_power := 0.0
	var total_required := 0.0
	var total_length := 0.0
	var rooms_heated := {}

	# Analyse des noeuds
	for node in heat_nodes:
		match node.node_type:
			"emitter":
				emitter_count += 1
				var power_w = node.properties.get("power_w", 0.0)
				var room_id = node.properties.get("room_id", "")
				var room_area = node.properties.get("room_area_m2", 0.0)
				var room_height = node.properties.get("room_height_m", 2.5)
				var insulation = node.properties.get("insulation", DEFAULT_INSULATION)

				total_power += power_w

				if room_id != "":
					if not rooms_heated.has(room_id):
						rooms_heated[room_id] = {"power": 0.0, "required": 0.0, "area": room_area, "height": room_height}
					rooms_heated[room_id]["power"] += power_w

					# Calculer besoin thermique
					var coeff = HEAT_LOSS_COEFF.get(insulation, HEAT_LOSS_COEFF["standard"])
					var delta_t = INDOOR_TEMP - OUTDOOR_TEMP
					var volume = room_area * room_height
					var required = volume * coeff * delta_t * SAFETY_MARGIN
					rooms_heated[room_id]["required"] = required
					total_required += required

				# Vérification puissance par m²
				if room_area > 0:
					var w_per_m2 = power_w / room_area
					if w_per_m2 < MIN_POWER_PER_M2:
						report.add_warning("HEAT_UNDERPOWER", "Émetteur '%s' : %.0f W/m² < min %.0f" % [node.label, w_per_m2, MIN_POWER_PER_M2], node.id)
					elif w_per_m2 > MAX_POWER_PER_M2:
						report.add_warning("HEAT_OVERPOWER", "Émetteur '%s' : %.0f W/m² > max %.0f" % [node.label, w_per_m2, MAX_POWER_PER_M2], node.id)

			"boiler":
				boiler_count += 1
				var boiler_power = node.properties.get("power_w", 0.0)
				if boiler_power > 0 and total_power > boiler_power:
					report.add_error("HEAT_BOILER_UNDERSIZE", "Chaudière '%s' : %.0fW < besoin total %.0fW" % [node.label, boiler_power, total_power], node.id)

			"thermostat":
				var has_room = node.properties.get("room_id", "") != ""
				if not has_room:
					report.add_warning("HEAT_THERMO_NO_ROOM", "Thermostat '%s' non affecté à une pièce" % node.label, node.id)

	# Vérifier les tuyaux
	for edge in heat_edges:
		var length = edge.get_length()
		total_length += length
		var pipe_type = edge.properties.get("pipe_type", "standard")

		if pipe_type == "floor_heating" and length > PIPE_MAX_LENGTH:
			report.add_error("HEAT_LOOP_LENGTH", "Boucle plancher %d : %.1fm > max %.1fm" % [edge.id, length, PIPE_MAX_LENGTH])

		var diameter = edge.get_diameter()
		if diameter > 0 and diameter < 12.0:
			report.add_warning("HEAT_PIPE_SMALL", "Tuyau %d : diamètre %.0fmm peut limiter le débit" % [edge.id, diameter])

	# Vérifier équilibrage par pièce
	for room_id in rooms_heated:
		var data = rooms_heated[room_id]
		if data["required"] > 0 and data["power"] < data["required"] * 0.8:
			report.add_warning("HEAT_ROOM_UNDERSIZE", "Pièce %s : %.0fW installé < %.0fW requis (80%%)" % [str(room_id), data["power"], data["required"]])
		elif data["required"] > 0 and data["power"] > data["required"] * 1.5:
			report.add_suggestion("HEAT_ROOM_OVERSIZE", "Pièce %s : %.0fW installé >> %.0fW requis" % [str(room_id), data["power"], data["required"]])

	if boiler_count == 0 and emitter_count > 0:
		report.add_error("HEAT_NO_BOILER", "Aucune chaudière/source de chaleur définie")

	# Composants connectés
	var components = graph.get_connected_components("heating")
	if components.size() > 1:
		report.add_warning("HEAT_DISCONNECTED", "%d circuits chauffage non connectés" % components.size())

	report.set_metric("total_emitters", emitter_count)
	report.set_metric("total_boilers", boiler_count)
	report.set_metric("total_power_w", total_power)
	report.set_metric("total_required_w", total_required)
	report.set_metric("total_pipe_length_m", total_length)
	report.set_metric("rooms_heated", rooms_heated.size())

	return report
