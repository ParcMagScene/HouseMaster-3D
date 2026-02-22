extends RefCounted

## SurveillanceSimulator — Simulation vidéosurveillance
## PoE, bande passante, angles de vue, zones mortes

class_name SurveillanceSimulator

# --- Constantes métier ---
const POE_POWER_BUDGET := 30.0         # W max par port PoE+
const POE_TOTAL_BUDGET := 370.0        # W budget total switch PoE typique
const CAMERA_BANDWIDTH_MBPS := {
	"1080p": 6.0, "2k": 10.0, "4k": 25.0, "4k_hdr": 40.0
}
const DEFAULT_RESOLUTION := "1080p"
const MIN_STORAGE_DAYS := 7             # jours de rétention minimum
const STORAGE_HOURS_PER_DAY := 24.0
const COMPRESSION_RATIO := 0.15        # H.265 approximatif
const MIN_FOV_DEGREES := 90.0          # angle de vue minimum recommandé
const MAX_IR_RANGE := 30.0             # m portée infrarouge max
const CAMERA_HEIGHT_MIN := 2.5         # m hauteur minimum caméra
const MAX_CAMERAS_PER_NVR := 32


func simulate(graph: SimulationGraph) -> SimulationReport:
	var report := SimulationReport.new("surveillance")
	var surv_nodes := graph.get_nodes_by_network("surveillance")
	var surv_edges := graph.get_edges_by_network("surveillance")

	if surv_nodes.size() == 0:
		report.set_metric("total_cameras", 0)
		report.set_metric("total_bandwidth_mbps", 0)
		return report

	var camera_count := 0
	var nvr_count := 0
	var total_bandwidth := 0.0
	var total_poe_power := 0.0
	var total_storage_gb := 0.0
	var zones_covered := {}

	# Analyse des caméras et NVR
	for node in surv_nodes:
		match node.node_type:
			"camera":
				camera_count += 1
				var resolution = node.properties.get("resolution", DEFAULT_RESOLUTION)
				var bandwidth = CAMERA_BANDWIDTH_MBPS.get(resolution, 6.0)
				total_bandwidth += bandwidth

				var poe_power = node.properties.get("power_w", 15.0)
				total_poe_power += poe_power

				# Angle de vue
				var fov = node.properties.get("fov_degrees", 90.0)
				if fov < MIN_FOV_DEGREES:
					report.add_warning("SURV_FOV_NARROW", "Caméra '%s' : angle %.0f° < recommandé %.0f°" % [node.label, fov, MIN_FOV_DEGREES], node.id)

				# Hauteur de montage
				var height = node.properties.get("height_m", 2.5)
				if height < CAMERA_HEIGHT_MIN:
					report.add_warning("SURV_HEIGHT_LOW", "Caméra '%s' : hauteur %.1fm < min %.1fm" % [node.label, height, CAMERA_HEIGHT_MIN], node.id)

				# Zone couverte
				var zone_id = node.properties.get("zone_id", "")
				if zone_id != "":
					if not zones_covered.has(zone_id):
						zones_covered[zone_id] = 0
					zones_covered[zone_id] += 1

				# Infrarouge
				var has_ir = node.properties.get("infrared", false)
				var ir_range = node.properties.get("ir_range_m", 0.0)
				if has_ir and ir_range > MAX_IR_RANGE:
					report.add_warning("SURV_IR_RANGE", "Caméra '%s' : portée IR %.0fm > max fiable %.0fm" % [node.label, ir_range, MAX_IR_RANGE])

				# Stockage estimé par caméra (Go/jour)
				var daily_gb = bandwidth * STORAGE_HOURS_PER_DAY * 3600.0 * COMPRESSION_RATIO / 8.0 / 1024.0
				total_storage_gb += daily_gb * MIN_STORAGE_DAYS

			"nvr":
				nvr_count += 1
				var max_channels = node.properties.get("max_channels", MAX_CAMERAS_PER_NVR)
				var storage_tb = node.properties.get("storage_tb", 0.0)

				if camera_count > max_channels:
					report.add_error("SURV_NVR_CHANNELS", "NVR '%s' : %d caméras > %d canaux max" % [node.label, camera_count, max_channels], node.id)

				if storage_tb > 0 and total_storage_gb > storage_tb * 1024.0:
					report.add_warning("SURV_NVR_STORAGE", "NVR '%s' : stockage %.0f Go requis > %.0f Go dispo (%d jours)" % [node.label, total_storage_gb, storage_tb * 1024.0, MIN_STORAGE_DAYS])

	# Vérifier câblage
	for edge in surv_edges:
		var length = edge.get_length()
		if length > 90.0:
			report.add_error("SURV_CABLE_LENGTH", "Câble surveillance %d : %.1fm > max 90m Ethernet" % [edge.id, length])

		if not edge.properties.get("poe", true):
			report.add_warning("SURV_NO_POE", "Câble %d sans PoE, alimentation séparée requise" % edge.id)

	# Budget PoE
	if total_poe_power > POE_TOTAL_BUDGET:
		report.add_error("SURV_POE_BUDGET", "Budget PoE total %.0fW > %.0fW max switch" % [total_poe_power, POE_TOTAL_BUDGET])
	elif total_poe_power > POE_TOTAL_BUDGET * 0.8:
		report.add_warning("SURV_POE_NEAR_MAX", "Budget PoE %.0fW/%.0fW (>80%%)" % [total_poe_power, POE_TOTAL_BUDGET])

	# Pas de NVR
	if nvr_count == 0 and camera_count > 0:
		report.add_error("SURV_NO_NVR", "Aucun NVR défini pour %d caméra(s)" % camera_count)

	# Composants connectés
	var components = graph.get_connected_components("surveillance")
	if components.size() > 1:
		report.add_warning("SURV_DISCONNECTED", "%d sous-réseaux surveillance non connectés" % components.size())

	# Bande passante totale
	if total_bandwidth > 1000.0:
		report.add_warning("SURV_BANDWIDTH_HIGH", "Bande passante totale %.0f Mbps, switch 10G recommandé" % total_bandwidth)

	report.set_metric("total_cameras", camera_count)
	report.set_metric("total_nvrs", nvr_count)
	report.set_metric("total_bandwidth_mbps", total_bandwidth)
	report.set_metric("total_poe_power_w", total_poe_power)
	report.set_metric("estimated_storage_gb", total_storage_gb)
	report.set_metric("zones_covered", zones_covered.size())

	return report
