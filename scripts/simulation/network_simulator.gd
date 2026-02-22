extends RefCounted

## NetworkSimulator — Simulation réseau informatique
## RJ45, fibre, PoE, Wi-Fi, débits, longueurs

class_name NetworkSimulator

# --- Constantes métier ---
const MAX_CABLE_LENGTH := {"cat5e": 90.0, "cat6": 90.0, "cat6a": 90.0, "cat7": 100.0, "fiber": 2000.0}
const CABLE_BANDWIDTH := {"cat5e": 1000.0, "cat6": 1000.0, "cat6a": 10000.0, "cat7": 10000.0, "fiber": 100000.0}
const MIN_CABLE_CATEGORY := "cat6"
const CATEGORY_ORDER := ["cat5", "cat5e", "cat6", "cat6a", "cat7"]
const POE_MAX_POWER := 30.0  # W (PoE+)
const POE_MAX_DEVICES_PER_SWITCH := 24
const WIFI_MAX_RANGE := 20.0  # m intérieur
const WIFI_MIN_OVERLAP := 0.15  # 15% de recouvrement recommandé
const MIN_POINTS_PER_ROOM := 1
const MAX_DAISY_CHAIN := 1  # Nombre max de cascades


func simulate(graph: SimulationGraph) -> SimulationReport:
	var report := SimulationReport.new("network")
	var net_nodes := graph.get_nodes_by_network("network")
	var net_edges := graph.get_edges_by_network("network")

	if net_nodes.size() == 0:
		report.set_metric("total_points", 0)
		report.set_metric("total_cables", 0)
		return report

	var point_count := 0
	var switch_count := 0
	var wifi_count := 0
	var total_length := 0.0
	var total_poe_power := 0.0
	var rooms_covered := {}

	# Analyse des noeuds
	for node in net_nodes:
		match node.node_type:
			"equipment":
				point_count += 1
				var room_id = node.properties.get("room_id", "")
				if room_id != "":
					if not rooms_covered.has(room_id):
						rooms_covered[room_id] = 0
					rooms_covered[room_id] += 1

			"switch":
				switch_count += 1
				var port_count = node.properties.get("port_count", 24)
				var connected = node.edges_in.size() + node.edges_out.size()
				if connected > port_count:
					report.add_error("NET_SWITCH_FULL", "Switch '%s' : %d connexions > %d ports" % [node.label, connected, port_count], node.id)
				elif connected > int(port_count * 0.8):
					report.add_warning("NET_SWITCH_NEAR_FULL", "Switch '%s' : %d/%d ports utilisés (>80%%)" % [node.label, connected, port_count], node.id)

			"wifi_ap":
				wifi_count += 1
				var range_m = node.properties.get("range_m", WIFI_MAX_RANGE)
				var is_poe = node.properties.get("poe", false)
				if is_poe:
					total_poe_power += node.properties.get("power_w", 15.0)

			"patch_panel":
				pass  # Baie de brassage

	# Vérifier les câbles
	for edge in net_edges:
		var cable_type = edge.properties.get("cable_type", "cat6")
		var length = edge.get_length()
		total_length += length

		# Catégorie minimale
		var cat_idx = CATEGORY_ORDER.find(cable_type)
		var min_idx = CATEGORY_ORDER.find(MIN_CABLE_CATEGORY)
		if cat_idx >= 0 and min_idx >= 0 and cat_idx < min_idx:
			report.add_error("NET_CABLE_CAT", "Câble %d : %s < catégorie minimale %s" % [edge.id, cable_type, MIN_CABLE_CATEGORY], -1, {"edge_id": edge.id})

		# Longueur max
		var max_len = MAX_CABLE_LENGTH.get(cable_type, 90.0)
		if length > max_len:
			report.add_error("NET_CABLE_LENGTH", "Câble %d : %.1fm > max %.1fm pour %s" % [edge.id, length, max_len, cable_type], -1, {"edge_id": edge.id})
		elif length > max_len * 0.9:
			report.add_warning("NET_CABLE_NEAR_MAX", "Câble %d : %.1fm, proche du max %.1fm" % [edge.id, length, max_len])

		# PoE
		if edge.properties.get("poe", false):
			var poe_power = edge.properties.get("poe_power_w", 15.0)
			total_poe_power += poe_power
			if poe_power > POE_MAX_POWER:
				report.add_error("NET_POE_POWER", "Câble %d : PoE %.0fW > max %.0fW" % [edge.id, poe_power, POE_MAX_POWER])

	# Composants connectés
	var components = graph.get_connected_components("network")
	if components.size() > 1:
		report.add_warning("NET_DISCONNECTED", "%d sous-réseaux non connectés" % components.size())

	# Vérifier couverture Wi-Fi
	if wifi_count == 0 and point_count > 0:
		report.add_suggestion("NET_NO_WIFI", "Aucun point d'accès Wi-Fi défini")

	# Pas de switch
	if switch_count == 0 and point_count > 2:
		report.add_warning("NET_NO_SWITCH", "Aucun switch défini pour %d points réseau" % point_count)

	var total_bandwidth := 0.0
	for edge in net_edges:
		var cable_type = edge.properties.get("cable_type", "cat6")
		total_bandwidth += CABLE_BANDWIDTH.get(cable_type, 1000.0)

	report.set_metric("total_points", point_count)
	report.set_metric("total_cables", net_edges.size())
	report.set_metric("total_switches", switch_count)
	report.set_metric("total_wifi_aps", wifi_count)
	report.set_metric("total_length_m", total_length)
	report.set_metric("total_poe_power_w", total_poe_power)
	report.set_metric("rooms_covered", rooms_covered.size())
	report.set_metric("max_bandwidth_mbps", total_bandwidth)

	return report
