extends Node

## SimulationManager — Orchestre toutes les simulations
## S'intègre à main.gd via signaux, compatible undo/redo et save/load

class_name SimulationManager

signal SIMULATION_UPDATED(report: Dictionary)
signal SIMULATION_ERROR(network: String, message: String)
signal SIMULATION_COMPLETED(reports: Array)

# --- Graphe global ---
var graph: SimulationGraph = SimulationGraph.new()

# --- Simulateurs ---
var electricity_sim = null
var plumbing_sim = null
var network_sim = null
var heating_sim = null
var surveillance_sim = null
var domotics_sim = null
var lighting_sim = null
var thermal_sim = null
var energy_sim = null
var cable_router = null
var water_router = null
var network_optimizer = null

# --- Rapports ---
var reports: Dictionary = {}
var auto_simulate: bool = true

# --- Preloads ---
const ElecSimScript = preload("res://scripts/simulation/electricity_simulator.gd")
const PlumbSimScript = preload("res://scripts/simulation/plumbing_simulator.gd")
const NetSimScript = preload("res://scripts/simulation/network_simulator.gd")
const HeatSimScript = preload("res://scripts/simulation/heating_simulator.gd")
const SurvSimScript = preload("res://scripts/simulation/surveillance_simulator.gd")
const DomSimScript = preload("res://scripts/simulation/domotics_simulator.gd")
const LightSimScript = preload("res://scripts/simulation/lighting_simulator.gd")
const ThermalSimScript = preload("res://scripts/simulation/thermal_simulator.gd")
const EnergySimScript = preload("res://scripts/simulation/energy_simulator.gd")
const CableRouterScript = preload("res://scripts/simulation/cable_router.gd")
const WaterRouterScript = preload("res://scripts/simulation/water_router.gd")
const NetOptimizerScript = preload("res://scripts/simulation/network_optimizer.gd")


func _ready() -> void:
	electricity_sim = ElecSimScript.new()
	plumbing_sim = PlumbSimScript.new()
	network_sim = NetSimScript.new()
	heating_sim = HeatSimScript.new()
	surveillance_sim = SurvSimScript.new()
	domotics_sim = DomSimScript.new()
	lighting_sim = LightSimScript.new()
	thermal_sim = ThermalSimScript.new()
	energy_sim = EnergySimScript.new()
	cable_router = CableRouterScript.new()
	water_router = WaterRouterScript.new()
	network_optimizer = NetOptimizerScript.new()


func setup(house: Node3D, plumbing: Node3D, electricity: Node3D, network: Node3D, domotics: Node3D) -> void:
	# Connecter les signaux des modules existants pour auto-recalcul
	if electricity and electricity.has_signal("ELECTRICITY_UPDATED"):
		electricity.ELECTRICITY_UPDATED.connect(_on_network_changed.bind("electricity"))
	if plumbing and plumbing.has_signal("PLUMBING_UPDATED"):
		plumbing.PLUMBING_UPDATED.connect(_on_network_changed.bind("plumbing"))
	if network and network.has_signal("NETWORK_UPDATED"):
		network.NETWORK_UPDATED.connect(_on_network_changed.bind("network"))
	if domotics and domotics.has_signal("DOMOTICS_UPDATED"):
		domotics.DOMOTICS_UPDATED.connect(_on_network_changed.bind("domotics"))
	print("🔬 SimulationManager initialisé")


func _on_network_changed(network_name: String) -> void:
	if auto_simulate:
		run_simulation(network_name)


func run_all_simulations() -> Array:
	var all_reports := []
	for net in ["electricity", "plumbing", "network", "heating", "surveillance", "domotics", "lighting"]:
		var report = run_simulation(net)
		if report:
			all_reports.append(report)
	# Simulations transversales
	var thermal_data = thermal_sim.simulate_house([])
	reports["thermal"] = thermal_data
	var energy_data = energy_sim.simulate(self)
	reports["energy"] = energy_data
	SIMULATION_COMPLETED.emit(all_reports)
	return all_reports


func run_simulation(network_name: String) -> SimulationReport:
	var report: SimulationReport = null
	match network_name:
		"electricity":
			report = electricity_sim.simulate(graph)
		"plumbing":
			report = plumbing_sim.simulate(graph)
		"network":
			report = network_sim.simulate(graph)
		"heating":
			report = heating_sim.simulate(graph)
		"surveillance":
			report = surveillance_sim.simulate(graph)
		"domotics":
			report = domotics_sim.simulate(graph)
		"lighting":
			report = lighting_sim.simulate(graph)
	if report:
		reports[network_name] = report
		SIMULATION_UPDATED.emit(report.to_dict())
		if not report.valid:
			SIMULATION_ERROR.emit(network_name, "%d erreur(s)" % report.get_error_count())
	return report


func run_cable_routing() -> Dictionary:
	return cable_router.route_cables(graph, "", [])


func run_water_routing() -> Dictionary:
	return water_router.route_water(graph, [])


func run_network_optimization() -> Dictionary:
	return network_optimizer.optimize_paths(graph, "")


func get_report(network_name: String):
	return reports.get(network_name, null)


func get_all_errors() -> Array:
	var all_errors := []
	for report in reports.values():
		if report is SimulationReport:
			all_errors.append_array(report.errors)
	return all_errors


func get_all_warnings() -> Array:
	var all_warnings := []
	for report in reports.values():
		if report is SimulationReport:
			all_warnings.append_array(report.warnings)
	return all_warnings


func to_dict() -> Dictionary:
	var reports_data := {}
	for key in reports:
		if reports[key] is SimulationReport:
			reports_data[key] = reports[key].to_dict()
		elif reports[key] is Dictionary:
			reports_data[key] = reports[key]
	return {
		"graph": graph.to_dict(),
		"reports": reports_data,
		"auto_simulate": auto_simulate,
	}


func from_dict(data: Dictionary) -> void:
	graph.from_dict(data.get("graph", {}))
	auto_simulate = data.get("auto_simulate", true)
	reports.clear()
