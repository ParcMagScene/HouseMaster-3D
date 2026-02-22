extends RefCounted

## EnergySimulator — Simulation énergétique globale
## Consommation totale, par réseau, estimation coût annuel

class_name EnergySimulator

# --- Constantes métier ---
const ELECTRICITY_PRICE_KWH := 0.2276  # €/kWh (tarif bleu 2024)
const GAS_PRICE_KWH := 0.1121         # €/kWh
const WATER_PRICE_M3 := 4.34          # €/m³
const HOT_WATER_ENERGY_KWH_PER_M3 := 58.0  # Énergie pour chauffer 1m³ de 15°C à 55°C
const HOURS_PER_YEAR := 8760.0
const HEATING_HOURS := 5000.0         # h/an chauffage en France
const LIGHTING_HOURS := 2500.0        # h/an éclairage moyen
const STANDBY_POWER_W := 5.0          # W par appareil en veille
const ECS_CONSUMPTION_L_PERSON := 50.0 # L/jour eau chaude sanitaire

# Coefficients d'usage
const USAGE_FACTORS := {
	"lighting": 0.3,      # 30% du temps d'allumage
	"sockets": 0.15,      # 15% du temps de charge
	"heating": 0.6,       # 60% du temps en hiver
	"cooling": 0.3,       # 30% du temps en été
	"ventilation": 1.0,   # 100% permanent
	"domotics": 1.0,      # 100% permanent
	"surveillance": 1.0,  # 100% permanent
	"network": 1.0,       # 100% permanent
}


func simulate(simulation_manager) -> Dictionary:
	var result := {
		"networks": {},
		"total_power_w": 0.0,
		"total_energy_kwh_year": 0.0,
		"total_cost_year_eur": 0.0,
		"electricity_kwh_year": 0.0,
		"gas_kwh_year": 0.0,
		"water_m3_year": 0.0,
		"electricity_cost_eur": 0.0,
		"gas_cost_eur": 0.0,
		"water_cost_eur": 0.0,
		"energy_class": "G",
		"co2_kg_year": 0.0,
		"suggestions": [],
		"breakdown": [],
	}

	# Récupérer les rapports de simulation par réseau
	var networks = ["electricity", "plumbing", "network", "heating", "surveillance", "domotics", "lighting"]

	for net in networks:
		var report = simulation_manager.get_report(net) if simulation_manager else null
		var net_data = _analyze_network(net, report)
		result["networks"][net] = net_data

		result["total_power_w"] += net_data["power_w"]
		result["total_energy_kwh_year"] += net_data["energy_kwh_year"]

		result["breakdown"].append({
			"network": net,
			"power_w": net_data["power_w"],
			"energy_kwh_year": net_data["energy_kwh_year"],
			"cost_eur_year": net_data["cost_eur_year"],
			"percentage": 0.0,  # Calculé après
		})

	# Coûts par énergie
	result["electricity_kwh_year"] = _sum_electric_networks(result["networks"])
	result["gas_kwh_year"] = result["networks"].get("heating", {}).get("gas_kwh_year", 0.0)
	result["water_m3_year"] = result["networks"].get("plumbing", {}).get("water_m3_year", 0.0)

	result["electricity_cost_eur"] = result["electricity_kwh_year"] * ELECTRICITY_PRICE_KWH
	result["gas_cost_eur"] = result["gas_kwh_year"] * GAS_PRICE_KWH
	result["water_cost_eur"] = result["water_m3_year"] * WATER_PRICE_M3

	result["total_cost_year_eur"] = result["electricity_cost_eur"] + result["gas_cost_eur"] + result["water_cost_eur"]

	# CO2 (facteur émission France)
	var co2_elec = result["electricity_kwh_year"] * 0.057  # kg CO2/kWh France
	var co2_gas = result["gas_kwh_year"] * 0.227           # kg CO2/kWh gaz
	result["co2_kg_year"] = co2_elec + co2_gas

	# Pourcentages
	if result["total_energy_kwh_year"] > 0:
		for item in result["breakdown"]:
			item["percentage"] = item["energy_kwh_year"] / result["total_energy_kwh_year"] * 100.0

	# Suggestions
	_generate_suggestions(result)

	return result


func _analyze_network(network: String, report) -> Dictionary:
	var data := {
		"power_w": 0.0,
		"energy_kwh_year": 0.0,
		"cost_eur_year": 0.0,
		"gas_kwh_year": 0.0,
		"water_m3_year": 0.0,
	}

	if report == null:
		return data

	var usage = USAGE_FACTORS.get(network, 0.5)

	match network:
		"electricity":
			var total_power = report.get_metric("total_power_w")
			if total_power != null:
				data["power_w"] = total_power
				data["energy_kwh_year"] = total_power * HOURS_PER_YEAR * usage / 1000.0
				data["cost_eur_year"] = data["energy_kwh_year"] * ELECTRICITY_PRICE_KWH

		"lighting":
			var total_power = report.get_metric("total_power_w")
			if total_power != null:
				data["power_w"] = total_power
				data["energy_kwh_year"] = total_power * LIGHTING_HOURS * USAGE_FACTORS["lighting"] / 1000.0
				data["cost_eur_year"] = data["energy_kwh_year"] * ELECTRICITY_PRICE_KWH

		"heating":
			var total_power = report.get_metric("total_power_w")
			if total_power != null:
				data["power_w"] = total_power
				# Chauffage gaz par défaut
				data["gas_kwh_year"] = total_power * HEATING_HOURS * USAGE_FACTORS["heating"] / 1000.0
				data["energy_kwh_year"] = data["gas_kwh_year"]
				data["cost_eur_year"] = data["gas_kwh_year"] * GAS_PRICE_KWH

		"plumbing":
			var fixtures = report.get_metric("total_fixtures")
			if fixtures != null and fixtures > 0:
				# Estimation consommation eau
				data["water_m3_year"] = fixtures * 20.0  # ~20m³/an par appareil
				data["cost_eur_year"] = data["water_m3_year"] * WATER_PRICE_M3
				# Énergie eau chaude
				var hot_water_m3 = data["water_m3_year"] * 0.4  # 40% eau chaude
				data["energy_kwh_year"] = hot_water_m3 * HOT_WATER_ENERGY_KWH_PER_M3
				data["power_w"] = data["energy_kwh_year"] * 1000.0 / HOURS_PER_YEAR

		"network":
			var total_points = report.get_metric("total_points")
			if total_points != null:
				# Équipements réseau : switches, AP, etc.
				data["power_w"] = total_points * 5.0 + report.get_metric("total_poe_power_w") if report.get_metric("total_poe_power_w") != null else total_points * 10.0
				data["energy_kwh_year"] = data["power_w"] * HOURS_PER_YEAR / 1000.0
				data["cost_eur_year"] = data["energy_kwh_year"] * ELECTRICITY_PRICE_KWH

		"surveillance":
			var total_cameras = report.get_metric("total_cameras")
			var poe_power = report.get_metric("total_poe_power_w")
			if poe_power != null:
				data["power_w"] = poe_power
			elif total_cameras != null:
				data["power_w"] = total_cameras * 15.0
			data["energy_kwh_year"] = data["power_w"] * HOURS_PER_YEAR / 1000.0
			data["cost_eur_year"] = data["energy_kwh_year"] * ELECTRICITY_PRICE_KWH

		"domotics":
			var total_devices = report.get_metric("total_devices")
			if total_devices != null:
				data["power_w"] = total_devices * STANDBY_POWER_W
				data["energy_kwh_year"] = data["power_w"] * HOURS_PER_YEAR / 1000.0
				data["cost_eur_year"] = data["energy_kwh_year"] * ELECTRICITY_PRICE_KWH

	return data


func _sum_electric_networks(networks: Dictionary) -> float:
	var total := 0.0
	for net in ["electricity", "lighting", "network", "surveillance", "domotics"]:
		if networks.has(net):
			total += networks[net].get("energy_kwh_year", 0.0)
	return total


func _generate_suggestions(result: Dictionary) -> void:
	# Top consommateur
	var sorted_breakdown = result["breakdown"].duplicate()
	sorted_breakdown.sort_custom(func(a, b): return a["energy_kwh_year"] > b["energy_kwh_year"])

	if sorted_breakdown.size() > 0 and sorted_breakdown[0]["percentage"] > 50.0:
		result["suggestions"].append("Le réseau '%s' représente %.0f%% de la consommation" % [sorted_breakdown[0]["network"], sorted_breakdown[0]["percentage"]])

	# Coût total élevé
	if result["total_cost_year_eur"] > 3000.0:
		result["suggestions"].append("Coût annuel estimé %.0f€, optimisation énergétique recommandée" % result["total_cost_year_eur"])

	# CO2
	if result["co2_kg_year"] > 1000.0:
		result["suggestions"].append("Émissions CO2 : %.0f kg/an, considérer pompe à chaleur ou solaire" % result["co2_kg_year"])

	# Éclairage LED
	var lighting = result["networks"].get("lighting", {})
	if lighting.get("energy_kwh_year", 0.0) > 500.0:
		result["suggestions"].append("Éclairage > 500 kWh/an, vérifier qu'il est 100%% LED")

	# Veille domotique
	var domotics = result["networks"].get("domotics", {})
	if domotics.get("energy_kwh_year", 0.0) > 200.0:
		result["suggestions"].append("Consommation domotique veille > 200 kWh/an")
