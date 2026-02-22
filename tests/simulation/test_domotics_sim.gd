extends "res://tests/test_base.gd"

## Tests DomoticsSimulator

func _make_domotics_graph() -> SimulationGraph:
	var g = SimulationGraph.new()
	var hub = g.add_node("hub", "domotics", Vector3.ZERO, "Hub Zigbee")
	hub.properties["supported_protocols"] = ["zigbee", "wifi"]

	var sensor = g.add_node("sensor", "domotics", Vector3(3, 1, 0), "Capteur Temp")
	sensor.properties["protocol"] = "zigbee"
	sensor.properties["sensor_type"] = "temperature"
	sensor.properties["battery_powered"] = true
	sensor.properties["room_id"] = "sejour"

	var actuator = g.add_node("actuator", "domotics", Vector3(3, 0, 0), "Vanne")
	actuator.properties["protocol"] = "zigbee"
	actuator.properties["commands"] = ["open", "close"]
	actuator.properties["room_id"] = "sejour"

	var scenario = g.add_node("scenario", "domotics", Vector3.ZERO, "Scénario Chauffage")
	scenario.properties["triggers"] = [{"type": "temperature", "threshold": 19}]
	scenario.properties["actions"] = [{"type": "open_valve"}]

	g.add_edge("link", "domotics", hub.id, sensor.id, {
		"length_m": 5.0, "protocol": "zigbee",
	})
	g.add_edge("link", "domotics", hub.id, actuator.id, {
		"length_m": 4.0, "protocol": "zigbee",
	})

	return g


func test_simulate_valid() -> void:
	var sim = DomoticsSimulator.new()
	var g = _make_domotics_graph()
	var report = sim.simulate(g)
	assert_not_null(report)
	assert_equal(report.network, "domotics")


func test_simulate_empty() -> void:
	var sim = DomoticsSimulator.new()
	var g = SimulationGraph.new()
	var report = sim.simulate(g)
	assert_equal(report.get_metric("total_sensors"), 0)


func test_detect_no_hub() -> void:
	var sim = DomoticsSimulator.new()
	var g = SimulationGraph.new()
	var sensor = g.add_node("sensor", "domotics", Vector3.ZERO, "Capteur")
	sensor.properties["protocol"] = "zigbee"
	sensor.properties["sensor_type"] = "motion"

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0, "pas de hub détecté")


func test_detect_scenario_no_action() -> void:
	var sim = DomoticsSimulator.new()
	var g = SimulationGraph.new()
	var hub = g.add_node("hub", "domotics", Vector3.ZERO, "Hub")
	hub.properties["supported_protocols"] = ["zigbee"]

	var scenario = g.add_node("scenario", "domotics", Vector3.ZERO, "Scén vide")
	scenario.properties["triggers"] = [{"type": "time"}]
	scenario.properties["actions"] = []

	var report = sim.simulate(g)
	assert_true(report.errors.size() > 0, "scénario sans action détecté")


func test_detect_range_exceed() -> void:
	var sim = DomoticsSimulator.new()
	var g = SimulationGraph.new()
	var hub = g.add_node("hub", "domotics", Vector3.ZERO, "Hub")
	hub.properties["supported_protocols"] = ["zigbee"]
	var sensor = g.add_node("sensor", "domotics", Vector3(20, 0, 0), "Capteur")
	sensor.properties["protocol"] = "zigbee"
	sensor.properties["sensor_type"] = "door"

	g.add_edge("link", "domotics", hub.id, sensor.id, {
		"length_m": 15.0, "protocol": "zigbee",
	})

	var report = sim.simulate(g)
	assert_true(report.warnings.size() > 0, "portée dépassée détectée")


func test_metrics() -> void:
	var sim = DomoticsSimulator.new()
	var g = _make_domotics_graph()
	var report = sim.simulate(g)
	assert_equal(report.get_metric("total_sensors"), 1)
	assert_equal(report.get_metric("total_actuators"), 1)
	assert_equal(report.get_metric("total_hubs"), 1)
	assert_gt(report.get_metric("total_devices"), 0.0, "devices > 0")
