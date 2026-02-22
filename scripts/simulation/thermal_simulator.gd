extends RefCounted

## ThermalSimulator — Simulation thermique
## Pertes thermiques, puissance chauffage, déperditions par pièce

class_name ThermalSimulator

# --- Constantes métier RT2012/RE2020 ---
const U_VALUES := {
	# Coefficients de transmission thermique W/(m²·K)
	"wall_insulated": 0.25,
	"wall_standard": 0.45,
	"wall_old": 1.2,
	"roof_insulated": 0.20,
	"roof_standard": 0.35,
	"roof_old": 1.5,
	"floor_insulated": 0.30,
	"floor_standard": 0.50,
	"floor_old": 1.0,
	"window_double": 1.4,
	"window_triple": 0.8,
	"window_single": 5.0,
	"door_insulated": 1.5,
	"door_standard": 3.0,
}

const DEFAULT_OUTDOOR_TEMP := -5.0    # °C (température de base)
const INDOOR_TEMP := 20.0             # °C
const AIR_RENEWAL_RATE := 0.5         # vol/h (VMC)
const AIR_HEAT_CAPACITY := 0.34       # Wh/(m³·K)
const THERMAL_BRIDGE_FACTOR := 0.1    # +10% pour ponts thermiques
const SOLAR_GAIN_FACTOR := 0.3        # Apports solaires moyens
const INTERNAL_GAIN_W_PER_M2 := 5.0   # Apports internes (occupants, appareils)

# Classes énergétiques (kWh/m²/an)
const ENERGY_CLASSES := {
	"A": 50, "B": 90, "C": 150, "D": 230, "E": 330, "F": 450, "G": 999999,
}


func simulate_room(room_data: Dictionary) -> Dictionary:
	var result := {
		"room_id": room_data.get("id", ""),
		"room_name": room_data.get("name", ""),
		"area_m2": 0.0,
		"volume_m3": 0.0,
		"total_loss_w": 0.0,
		"wall_loss_w": 0.0,
		"window_loss_w": 0.0,
		"roof_loss_w": 0.0,
		"floor_loss_w": 0.0,
		"air_loss_w": 0.0,
		"thermal_bridge_w": 0.0,
		"solar_gain_w": 0.0,
		"internal_gain_w": 0.0,
		"heating_power_w": 0.0,
		"warnings": [],
	}

	var area = room_data.get("area_m2", 0.0)
	var height = room_data.get("height_m", 2.5)
	var volume = area * height
	var delta_t = INDOOR_TEMP - room_data.get("outdoor_temp", DEFAULT_OUTDOOR_TEMP)

	result["area_m2"] = area
	result["volume_m3"] = volume

	# Pertes par les murs
	var walls = room_data.get("walls", [])
	for wall in walls:
		var wall_area = wall.get("area_m2", 0.0)
		var wall_type = wall.get("type", "wall_standard")
		var u = U_VALUES.get(wall_type, U_VALUES["wall_standard"])
		var loss = wall_area * u * delta_t
		result["wall_loss_w"] += loss

	# Pertes par les fenêtres
	var windows = room_data.get("windows", [])
	for win in windows:
		var win_area = win.get("area_m2", 0.0)
		var win_type = win.get("type", "window_double")
		var u = U_VALUES.get(win_type, U_VALUES["window_double"])
		var loss = win_area * u * delta_t
		result["window_loss_w"] += loss

		# Apports solaires
		var orientation = win.get("orientation", "north")
		var solar_factor = _solar_factor(orientation)
		result["solar_gain_w"] += win_area * solar_factor * 100.0  # W/m² solaire simplifié

	# Pertes par le toit
	var is_top_floor = room_data.get("is_top_floor", false)
	if is_top_floor:
		var roof_type = room_data.get("roof_type", "roof_standard")
		var u = U_VALUES.get(roof_type, U_VALUES["roof_standard"])
		result["roof_loss_w"] = area * u * delta_t

	# Pertes par le sol
	var is_ground_floor = room_data.get("is_ground_floor", true)
	if is_ground_floor:
		var floor_type = room_data.get("floor_type", "floor_standard")
		var u = U_VALUES.get(floor_type, U_VALUES["floor_standard"])
		result["floor_loss_w"] = area * u * delta_t * 0.7  # Facteur sol

	# Pertes par renouvellement d'air
	var renewal = room_data.get("air_renewal_rate", AIR_RENEWAL_RATE)
	result["air_loss_w"] = volume * renewal * AIR_HEAT_CAPACITY * delta_t

	# Ponts thermiques
	var sub_losses = result["wall_loss_w"] + result["window_loss_w"] + result["roof_loss_w"] + result["floor_loss_w"]
	result["thermal_bridge_w"] = sub_losses * THERMAL_BRIDGE_FACTOR

	# Apports internes
	result["internal_gain_w"] = area * INTERNAL_GAIN_W_PER_M2

	# Total des pertes
	result["total_loss_w"] = sub_losses + result["air_loss_w"] + result["thermal_bridge_w"]

	# Puissance de chauffage nécessaire
	result["heating_power_w"] = max(0.0, result["total_loss_w"] - result["solar_gain_w"] - result["internal_gain_w"])

	# Vérifications
	var w_per_m2 = result["heating_power_w"] / area if area > 0 else 0.0
	if w_per_m2 > 150.0:
		result["warnings"].append("%.0f W/m² requis, isolation insuffisante" % w_per_m2)
	elif w_per_m2 > 100.0:
		result["warnings"].append("%.0f W/m², améliorer l'isolation recommandé" % w_per_m2)

	return result


func simulate_house(rooms: Array) -> Dictionary:
	var total := {
		"rooms": [],
		"total_loss_w": 0.0,
		"total_heating_power_w": 0.0,
		"total_area_m2": 0.0,
		"average_w_per_m2": 0.0,
		"energy_class": "G",
		"estimated_kwh_per_year": 0.0,
		"warnings": [],
		"suggestions": [],
	}

	for room_data in rooms:
		var room_result = simulate_room(room_data)
		total["rooms"].append(room_result)
		total["total_loss_w"] += room_result["total_loss_w"]
		total["total_heating_power_w"] += room_result["heating_power_w"]
		total["total_area_m2"] += room_result["area_m2"]
		for w in room_result["warnings"]:
			total["warnings"].append("%s : %s" % [room_result["room_name"], w])

	if total["total_area_m2"] > 0:
		total["average_w_per_m2"] = total["total_heating_power_w"] / total["total_area_m2"]

		# Estimation consommation annuelle (heures de chauffage)
		var heating_hours = 5000.0  # ~5000h/an en France
		total["estimated_kwh_per_year"] = total["total_heating_power_w"] * heating_hours / 1000.0
		var kwh_per_m2 = total["estimated_kwh_per_year"] / total["total_area_m2"]

		# Classe énergétique
		for cls in ["A", "B", "C", "D", "E", "F", "G"]:
			if kwh_per_m2 <= ENERGY_CLASSES[cls]:
				total["energy_class"] = cls
				break

		if total["energy_class"] in ["E", "F", "G"]:
			total["suggestions"].append("Classe %s : rénovation énergétique fortement recommandée" % total["energy_class"])
		elif total["energy_class"] in ["C", "D"]:
			total["suggestions"].append("Classe %s : amélioration possible (isolation, fenêtres)" % total["energy_class"])

	return total


func _solar_factor(orientation: String) -> float:
	match orientation:
		"south": return 1.0
		"south_east", "south_west": return 0.7
		"east", "west": return 0.4
		"north_east", "north_west": return 0.2
		"north": return 0.1
		_: return SOLAR_GAIN_FACTOR
