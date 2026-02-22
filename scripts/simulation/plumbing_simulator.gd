extends RefCounted

## PlumbingSimulator — Simulation plomberie
## Pentes, diamètres, pertes de charge

class_name PlumbingSimulator

# --- Constantes métier ---
const MIN_SLOPE := 0.01  # 1%
const MAX_SLOPE := 0.05  # 5%
const EVAC_DIAMETER_RANGE := {"min": 40.0, "max": 100.0}
const SUPPLY_DIAMETER_RANGE := {"min": 12.0, "max": 16.0}
const MAX_SUPPLY_LENGTH := 20.0  # m avant perte de pression significative
const MAX_EVAC_LENGTH := 10.0  # m entre siphon et chute
const FRICTION_COEFF := 0.02  # coefficient de perte de charge linéaire
const WATER_DENSITY := 1000.0  # kg/m³
const GRAVITY := 9.81

# Débits par appareil (L/s)
const FLOW_RATES := {
	"sink": 0.2, "toilet": 1.5, "shower": 0.3,
	"bathtub": 0.4, "washing_machine": 0.3, "dishwasher": 0.2,
}


func simulate(graph: SimulationGraph) -> SimulationReport:
	var report := SimulationReport.new("plumbing")
	var plumb_nodes := graph.get_nodes_by_network("plumbing")
	var plumb_edges := graph.get_edges_by_network("plumbing")

	if plumb_nodes.size() == 0:
		report.set_metric("total_pipes", 0)
		report.set_metric("total_fixtures", 0)
		return report

	var fixture_count := 0
	var pipe_count := plumb_edges.size()
	var total_length := 0.0
	var total_flow := 0.0

	# Vérifier les appareils
	for node in plumb_nodes:
		if node.node_type == "equipment":
			fixture_count += 1
			var fixture_type = node.properties.get("fixture_type", "sink")
			var has_supply = node.properties.get("has_supply", false)
			var has_evac = node.properties.get("has_evacuation", false)

			if not has_supply:
				report.add_error("PLUMB_NO_SUPPLY", "Appareil '%s' sans arrivée d'eau" % node.label, node.id)
			if not has_evac:
				report.add_error("PLUMB_NO_EVAC", "Appareil '%s' sans évacuation" % node.label, node.id)

			total_flow += FLOW_RATES.get(fixture_type, 0.2)

	# Vérifier les tuyaux
	for edge in plumb_edges:
		var pipe_type = edge.properties.get("pipe_type", "supply")
		var diameter = edge.get_diameter()
		var length = edge.get_length()
		total_length += length

		if pipe_type == "evacuation":
			# Vérification pente
			var slope = edge.properties.get("slope", 0.0)
			if slope < MIN_SLOPE:
				report.add_error("PLUMB_SLOPE_LOW", "Tuyau %d : pente %.3f < min %.3f" % [edge.id, slope, MIN_SLOPE], -1, {"edge_id": edge.id})
			elif slope > MAX_SLOPE:
				report.add_warning("PLUMB_SLOPE_HIGH", "Tuyau %d : pente %.3f > recommandé %.3f" % [edge.id, slope, MAX_SLOPE])

			# Vérification diamètre évacuation
			if diameter < EVAC_DIAMETER_RANGE["min"]:
				report.add_error("PLUMB_EVAC_DIAM_LOW", "Tuyau %d : diamètre %.0f mm < min %.0f mm" % [edge.id, diameter, EVAC_DIAMETER_RANGE["min"]])
			elif diameter > EVAC_DIAMETER_RANGE["max"]:
				report.add_warning("PLUMB_EVAC_DIAM_HIGH", "Tuyau %d : diamètre %.0f mm surdimensionné" % [edge.id, diameter])

			# Longueur max évacuation
			if length > MAX_EVAC_LENGTH:
				report.add_warning("PLUMB_EVAC_LENGTH", "Tuyau évac %d : %.1fm > max recommandé %.1fm" % [edge.id, length, MAX_EVAC_LENGTH])

		else:  # supply / hot_supply
			# Vérification diamètre arrivée
			if diameter < SUPPLY_DIAMETER_RANGE["min"]:
				report.add_error("PLUMB_SUPPLY_DIAM_LOW", "Tuyau %d : diamètre %.0f mm < min %.0f mm" % [edge.id, diameter, SUPPLY_DIAMETER_RANGE["min"]])

			# Longueur max arrivée
			if length > MAX_SUPPLY_LENGTH:
				report.add_warning("PLUMB_SUPPLY_LENGTH", "Tuyau arrivée %d : %.1fm, perte de pression possible" % [edge.id, length])

	# Pertes de charge
	var pressure_loss = _calculate_pressure_loss(plumb_edges, total_flow)
	if pressure_loss > 50.0:
		report.add_warning("PLUMB_PRESSURE_LOSS", "Perte de charge totale %.1f kPa, considérer un surpresseur" % pressure_loss)

	# Composants connectés
	var components = graph.get_connected_components("plumbing")
	if components.size() > 1:
		report.add_warning("PLUMB_DISCONNECTED", "%d sous-réseaux plomberie non connectés" % components.size())

	report.set_metric("total_pipes", pipe_count)
	report.set_metric("total_fixtures", fixture_count)
	report.set_metric("total_length_m", total_length)
	report.set_metric("total_flow_ls", total_flow)
	report.set_metric("pressure_loss_kpa", pressure_loss)

	if fixture_count > 0 and pipe_count == 0:
		report.add_suggestion("PLUMB_NO_PIPES", "Appareils présents mais aucun tuyau défini")

	return report


func _calculate_pressure_loss(edges: Array, total_flow: float) -> float:
	var total_loss := 0.0
	for edge in edges:
		var diameter_m = edge.get_diameter() / 1000.0
		if diameter_m <= 0:
			continue
		var length = edge.get_length()
		var area = PI * (diameter_m / 2.0) ** 2
		var velocity = total_flow / 1000.0 / area if area > 0 else 0.0
		total_loss += FRICTION_COEFF * (length / diameter_m) * (WATER_DENSITY * velocity ** 2 / 2.0) / 1000.0
	return total_loss
