extends Resource
class_name MaterialCore

## Système de gestion des matériaux PBR

@export var material_name: String = "default"
@export var material_type: String = "generic"  # wood, concrete, plaster, metal, glass
@export var albedo_color: Color = Color.WHITE
@export var roughness: float = 0.5
@export var metallic: float = 0.0
@export var normal_strength: float = 1.0

# --- Matériaux prédéfinis ---
static var PRESETS := {
	"wood": {
		"albedo_color": Color(0.65, 0.45, 0.25),
		"roughness": 0.7,
		"metallic": 0.0,
	},
	"concrete": {
		"albedo_color": Color(0.7, 0.7, 0.7),
		"roughness": 0.9,
		"metallic": 0.0,
	},
	"plaster": {
		"albedo_color": Color(0.95, 0.93, 0.88),
		"roughness": 0.8,
		"metallic": 0.0,
	},
	"metal": {
		"albedo_color": Color(0.6, 0.6, 0.65),
		"roughness": 0.3,
		"metallic": 0.8,
	},
	"glass": {
		"albedo_color": Color(0.7, 0.85, 0.95, 0.3),
		"roughness": 0.1,
		"metallic": 0.2,
	},
	"meleze": {
		"albedo_color": Color(0.72, 0.52, 0.30),
		"roughness": 0.65,
		"metallic": 0.0,
	},
	"anthracite": {
		"albedo_color": Color(0.2, 0.2, 0.22),
		"roughness": 0.4,
		"metallic": 0.1,
	},
	"terrasse_bois": {
		"albedo_color": Color(0.6, 0.42, 0.22),
		"roughness": 0.75,
		"metallic": 0.0,
	},
}


func create_standard_material(mat_type: String = "") -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	var preset_type = mat_type if mat_type != "" else material_type
	
	if preset_type in PRESETS:
		var preset = PRESETS[preset_type]
		mat.albedo_color = preset["albedo_color"]
		mat.roughness = preset["roughness"]
		mat.metallic = preset["metallic"]
	else:
		mat.albedo_color = albedo_color
		mat.roughness = roughness
		mat.metallic = metallic
	
	if preset_type == "glass":
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	return mat


static func get_material(mat_type: String) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	if mat_type in PRESETS:
		var preset = PRESETS[mat_type]
		mat.albedo_color = preset["albedo_color"]
		mat.roughness = preset["roughness"]
		mat.metallic = preset["metallic"]
		if mat_type == "glass":
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat


func to_dict() -> Dictionary:
	return {
		"name": material_name,
		"type": material_type,
		"albedo_color": {"r": albedo_color.r, "g": albedo_color.g, "b": albedo_color.b, "a": albedo_color.a},
		"roughness": roughness,
		"metallic": metallic,
	}


func from_dict(data: Dictionary) -> void:
	material_name = data.get("name", "default")
	material_type = data.get("type", "generic")
	var c = data.get("albedo_color", {})
	albedo_color = Color(c.get("r", 1), c.get("g", 1), c.get("b", 1), c.get("a", 1))
	roughness = data.get("roughness", 0.5)
	metallic = data.get("metallic", 0.0)
