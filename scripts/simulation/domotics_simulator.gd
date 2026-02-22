extends RefCounted

## DomoticsSimulator — Simulation domotique
## Scénarios, capteurs, actionneurs, protocoles, couverture

class_name DomoticsSimulator

# --- Constantes métier ---
const PROTOCOLS := ["zigbee", "zwave", "wifi", "bluetooth", "thread", "matter"]
const MAX_ZIGBEE_DEVICES := 65000
const MAX_ZWAVE_DEVICES := 232
const MAX_WIFI_DEVICES := 50       # par AP recommandé
const MAX_BLUETOOTH_DEVICES := 7
const ZIGBEE_RANGE := 10.0         # m intérieur
const ZWAVE_RANGE := 30.0          # m intérieur
const WIFI_RANGE := 20.0           # m intérieur
const SENSOR_BATTERY_MONTHS := 12  # durée de vie moyenne
const MAX_SCENARIO_ACTIONS := 20
const MAX_LATENCY_MS := 500.0      # ms latence max acceptable


func simulate(graph: SimulationGraph) -> SimulationReport:
	var report := SimulationReport.new("domotics")
	var dom_nodes := graph.get_nodes_by_network("domotics")
	var dom_edges := graph.get_edges_by_network("domotics")

	if dom_nodes.size() == 0:
		report.set_metric("total_sensors", 0)
		report.set_metric("total_actuators", 0)
		return report

	var sensor_count := 0
	var actuator_count := 0
	var hub_count := 0
	var scenario_count := 0
	var protocol_devices := {}
	var battery_devices := []
	var rooms_covered := {}

	# Initialiser compteurs protocoles
	for proto in PROTOCOLS:
		protocol_devices[proto] = 0

	# Analyse des noeuds
	for node in dom_nodes:
		match node.node_type:
			"sensor":
				sensor_count += 1
				var proto = node.properties.get("protocol", "zigbee")
				if protocol_devices.has(proto):
					protocol_devices[proto] += 1

				var battery = node.properties.get("battery_powered", false)
				if battery:
					battery_devices.append(node)

				var room_id = node.properties.get("room_id", "")
				if room_id != "":
					if not rooms_covered.has(room_id):
						rooms_covered[room_id] = {"sensors": 0, "actuators": 0}
					rooms_covered[room_id]["sensors"] += 1

				# Vérifier type de capteur
				var sensor_type = node.properties.get("sensor_type", "")
				if sensor_type == "":
					report.add_warning("DOM_SENSOR_TYPE", "Capteur '%s' sans type défini" % node.label, node.id)

			"actuator":
				actuator_count += 1
				var proto = node.properties.get("protocol", "zigbee")
				if protocol_devices.has(proto):
					protocol_devices[proto] += 1

				var room_id = node.properties.get("room_id", "")
				if room_id != "":
					if not rooms_covered.has(room_id):
						rooms_covered[room_id] = {"sensors": 0, "actuators": 0}
					rooms_covered[room_id]["actuators"] += 1

				# Vérifier qu'un actuateur a au moins une commande
				var commands = node.properties.get("commands", [])
				if commands.size() == 0:
					report.add_warning("DOM_NO_COMMANDS", "Actionneur '%s' sans commande définie" % node.label, node.id)

			"hub":
				hub_count += 1
				var supported = node.properties.get("supported_protocols", [])
				if supported.size() == 0:
					report.add_warning("DOM_HUB_NO_PROTO", "Hub '%s' sans protocole supporté" % node.label, node.id)

			"scenario":
				scenario_count += 1
				var actions = node.properties.get("actions", [])
				var triggers = node.properties.get("triggers", [])

				if triggers.size() == 0:
					report.add_warning("DOM_SCENARIO_NO_TRIGGER", "Scénario '%s' sans déclencheur" % node.label, node.id)

				if actions.size() == 0:
					report.add_error("DOM_SCENARIO_NO_ACTION", "Scénario '%s' sans action" % node.label, node.id)
				elif actions.size() > MAX_SCENARIO_ACTIONS:
					report.add_warning("DOM_SCENARIO_MANY_ACTIONS", "Scénario '%s' : %d actions (>%d)" % [node.label, actions.size(), MAX_SCENARIO_ACTIONS], node.id)

	# Vérifier limites par protocole
	if protocol_devices.get("zwave", 0) > MAX_ZWAVE_DEVICES:
		report.add_error("DOM_ZWAVE_LIMIT", "%d appareils Z-Wave > max %d" % [protocol_devices["zwave"], MAX_ZWAVE_DEVICES])

	if protocol_devices.get("wifi", 0) > MAX_WIFI_DEVICES:
		report.add_warning("DOM_WIFI_LIMIT", "%d appareils Wi-Fi > recommandé %d par AP" % [protocol_devices["wifi"], MAX_WIFI_DEVICES])

	if protocol_devices.get("bluetooth", 0) > MAX_BLUETOOTH_DEVICES:
		report.add_warning("DOM_BT_LIMIT", "%d appareils Bluetooth > max %d simultanés" % [protocol_devices["bluetooth"], MAX_BLUETOOTH_DEVICES])

	# Vérifier portée des liaisons
	for edge in dom_edges:
		var length = edge.get_length()
		var proto = edge.properties.get("protocol", "zigbee")
		var max_range := 10.0

		match proto:
			"zigbee": max_range = ZIGBEE_RANGE
			"zwave": max_range = ZWAVE_RANGE
			"wifi": max_range = WIFI_RANGE

		if length > max_range:
			report.add_warning("DOM_RANGE_EXCEED", "Liaison %d (%s) : %.1fm > portée %.1fm" % [edge.id, proto, length, max_range])

		var latency = edge.properties.get("latency_ms", 0.0)
		if latency > MAX_LATENCY_MS:
			report.add_warning("DOM_LATENCY", "Liaison %d : latence %.0fms > max %.0fms" % [edge.id, latency, MAX_LATENCY_MS])

	# Pas de hub
	if hub_count == 0 and (sensor_count + actuator_count) > 0:
		report.add_error("DOM_NO_HUB", "Aucun hub domotique pour %d appareils" % (sensor_count + actuator_count))

	# Appareils sur batterie
	if battery_devices.size() > 0:
		report.add_suggestion("DOM_BATTERY", "%d appareils sur batterie, prévoir remplacement tous les %d mois" % [battery_devices.size(), SENSOR_BATTERY_MONTHS])

	# Composants connectés
	var components = graph.get_connected_components("domotics")
	if components.size() > 1:
		report.add_warning("DOM_DISCONNECTED", "%d sous-réseaux domotiques non connectés" % components.size())

	# Protocoles utilisés
	var active_protocols := []
	for proto in protocol_devices:
		if protocol_devices[proto] > 0:
			active_protocols.append(proto)

	if active_protocols.size() > 3:
		report.add_suggestion("DOM_MANY_PROTOCOLS", "%d protocoles différents, considérer Matter pour unification" % active_protocols.size())

	report.set_metric("total_sensors", sensor_count)
	report.set_metric("total_actuators", actuator_count)
	report.set_metric("total_hubs", hub_count)
	report.set_metric("total_scenarios", scenario_count)
	report.set_metric("total_devices", sensor_count + actuator_count)
	report.set_metric("battery_devices", battery_devices.size())
	report.set_metric("rooms_covered", rooms_covered.size())
	report.set_metric("active_protocols", active_protocols.size())
	report.set_metric("protocol_breakdown", protocol_devices)

	return report
