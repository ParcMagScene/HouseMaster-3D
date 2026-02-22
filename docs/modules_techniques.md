# Modules Techniques — HouseMaster 3D

## PlumbingModule (`scripts/modules/plumbing_module.gd`)

Gestion de la plomberie : tuyaux, raccords, appareils sanitaires.

### Constantes

| Constante | Valeur | Description |
|-----------|--------|-------------|
| `MIN_SLOPE` | `0.01` (1%) | Pente minimale évacuation |
| `EVAC_DIAMETERS` | `[40, 50, 63, 75, 100]` | Diamètres évacuation (mm) |
| `SUPPLY_DIAMETERS` | `[12, 14, 16]` | Diamètres alimentation (mm) |

### Données

- `pipes: Array` — Tuyaux `{start, end, diameter, type}`
- `fixtures: Array` — Appareils `{position, type}`
- `hot_water_source: Dictionary` — Source ECS

### Méthodes

| Méthode | Description |
|---------|-------------|
| `add_pipe(start, end, diameter, type)` | Ajoute un tuyau |
| `remove_pipe(index)` | Supprime un tuyau |
| `add_fixture(position, type)` | Ajoute un appareil |
| `validate()` | Valide les règles métier |
| `to_dict()` / `from_dict(data)` | Sérialisation |

---

## ElectricityModule (`scripts/modules/electricity_module.gd`)

Gestion électrique : circuits, éléments, tableau.

### Constantes

| Constante | Valeur | Description |
|-----------|--------|-------------|
| `MAX_SOCKETS_PER_CIRCUIT` | `8` | Prises max par circuit |
| `MAX_LIGHTS_PER_CIRCUIT` | `8` | Points lumineux max |
| `BREAKER_SIZES` | `[10, 16, 20, 32]` | Calibres disjoncteurs (A) |

### Données

- `circuits: Array` — Circuits `{name, breaker_amps, elements}`
- `panel: Dictionary` — Tableau électrique
- `differential: Dictionary` — Interrupteur différentiel 30mA

### Méthodes

| Méthode | Description |
|---------|-------------|
| `add_circuit(name, breaker_amps)` | Ajoute un circuit |
| `add_element(circuit_idx, position, type)` | Ajoute prise/luminaire |
| `validate()` | Valide NF C 15-100 |
| `get_panel_summary()` | Résumé du tableau |
| `to_dict()` / `from_dict(data)` | Sérialisation |

---

## NetworkModule (`scripts/modules/network_module.gd`)

Gestion réseau : points, câbles, WiFi, baie de brassage.

### Constantes

| Constante | Valeur | Description |
|-----------|--------|-------------|
| `CABLE_TYPES` | `[cat5e, cat6, cat6a, cat7, fiber]` | Types de câbles |
| `MIN_CABLE_CATEGORY` | `cat6` | Grade minimum recommandé |

### Données

- `points: Array` — Points réseau `{position, type}`
- `cables: Array` — Câbles `{from, to, category}`
- `patch_panel: Dictionary` — Baie de brassage
- `wifi_zones: Array` — Zones WiFi

### Méthodes

| Méthode | Description |
|---------|-------------|
| `add_point(position, type)` | Ajoute un point réseau |
| `add_cable(from_idx, to_idx, category)` | Tire un câble |
| `validate()` | Vérifie arrivée fibre, grade câbles |
| `to_dict()` / `from_dict(data)` | Sérialisation |

---

## DomoticsModule (`scripts/modules/domotics_module.gd`)

Gestion domotique : capteurs, actionneurs, scénarios IF/THEN.

### Types

**Capteurs** : `motion`, `temperature`, `opening`, `humidity`, `light_level`

**Actionneurs** : `light`, `shutter`, `heating`, `alarm`, `lock`

### Données

- `sensors: Array` — Capteurs `{position, type, state}`
- `actuators: Array` — Actionneurs `{position, type, state}`
- `scenarios: Array` — Scénarios `{name, conditions[], actions[]}`

### Méthodes

| Méthode | Description |
|---------|-------------|
| `add_sensor(position, type)` | Ajoute un capteur |
| `add_actuator(position, type)` | Ajoute un actionneur |
| `add_scenario(name, conditions, actions)` | Crée un scénario |
| `evaluate_scenarios()` | Évalue tous les scénarios |
| `to_dict()` / `from_dict(data)` | Sérialisation |

### Format Scénario

```gdscript
{
    "name": "Auto-éclairage",
    "conditions": [
        {"sensor_index": 0, "operator": "==", "value": true}
    ],
    "actions": [
        {"actuator_index": 0, "action": "turn_on", "value": null}
    ]
}
```
