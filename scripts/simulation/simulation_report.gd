extends RefCounted

## SimulationReport — Rapport de simulation avec erreurs, warnings, métriques
## Généré par chaque simulateur après analyse

class_name SimulationReport

var network: String = ""
var timestamp: float = 0.0
var errors: Array[Dictionary] = []
var warnings: Array[Dictionary] = []
var suggestions: Array[Dictionary] = []
var metrics: Dictionary = {}
var valid: bool = true


func _init(p_network: String = "") -> void:
	network = p_network
	timestamp = Time.get_unix_time_from_system()


func add_error(code: String, message: String, node_id: int = -1, details: Dictionary = {}) -> void:
	errors.append({"code": code, "message": message, "node_id": node_id, "details": details})
	valid = false


func add_warning(code: String, message: String, node_id: int = -1, details: Dictionary = {}) -> void:
	warnings.append({"code": code, "message": message, "node_id": node_id, "details": details})


func add_suggestion(code: String, message: String, details: Dictionary = {}) -> void:
	suggestions.append({"code": code, "message": message, "details": details})


func set_metric(key: String, value: Variant) -> void:
	metrics[key] = value


func get_metric(key: String, default: Variant = null) -> Variant:
	return metrics.get(key, default)


func get_error_count() -> int:
	return errors.size()


func get_warning_count() -> int:
	return warnings.size()


func merge(other: SimulationReport) -> void:
	errors.append_array(other.errors)
	warnings.append_array(other.warnings)
	suggestions.append_array(other.suggestions)
	for key in other.metrics:
		metrics[key] = other.metrics[key]
	if not other.valid:
		valid = false


func to_dict() -> Dictionary:
	return {
		"network": network,
		"timestamp": timestamp,
		"valid": valid,
		"errors": errors.duplicate(true),
		"warnings": warnings.duplicate(true),
		"suggestions": suggestions.duplicate(true),
		"metrics": metrics.duplicate(true),
	}


func get_summary_text() -> String:
	var lines := []
	lines.append("══ Rapport %s ══" % network.to_upper())
	lines.append("Statut : %s" % ("✅ Valide" if valid else "❌ Erreurs détectées"))
	if errors.size() > 0:
		lines.append("Erreurs (%d) :" % errors.size())
		for e in errors:
			lines.append("  ❌ [%s] %s" % [e["code"], e["message"]])
	if warnings.size() > 0:
		lines.append("Warnings (%d) :" % warnings.size())
		for w in warnings:
			lines.append("  ⚠️ [%s] %s" % [w["code"], w["message"]])
	if suggestions.size() > 0:
		lines.append("Suggestions (%d) :" % suggestions.size())
		for s in suggestions:
			lines.append("  💡 [%s] %s" % [s["code"], s["message"]])
	if metrics.size() > 0:
		lines.append("Métriques :")
		for key in metrics:
			lines.append("  📊 %s = %s" % [key, str(metrics[key])])
	return "\n".join(lines)
