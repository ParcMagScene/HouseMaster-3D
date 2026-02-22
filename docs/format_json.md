# Format JSON Sauvegarde — HouseMaster 3D

## Structure racine

```json
{
  "version": "1.0.0",
  "timestamp": "2025-01-15T10:30:00",
  "house": { ... },
  "modules": {
    "plumbing": { ... },
    "electricity": { ... },
    "network": { ... },
    "domotics": { ... }
  }
}
```

## House

```json
{
  "exterior_width": 10.5,
  "exterior_depth": 6.7,
  "wall_height": 2.5,
  "wall_thickness": 0.2,
  "rooms": [
    {
      "name": "Séjour + Cuisine",
      "type": "living",
      "position": {"x": 0.2, "y": 0, "z": 0.2},
      "size": {"x": 5.5, "y": 6.7},
      "technical_points": [
        {"position": {"x": 1, "y": 0.5, "z": 0.5}, "type": "plumbing", "label": "Évier"}
      ]
    }
  ],
  "walls": [
    {
      "start": {"x": 0, "y": 0, "z": 0},
      "end": {"x": 10.5, "y": 0, "z": 0},
      "height": 2.5,
      "thickness": 0.2,
      "is_exterior": true,
      "material": "concrete",
      "openings": [
        {"position": 2.0, "width": 1.2, "height": 2.1, "type": "door"}
      ]
    }
  ]
}
```

## Plumbing

```json
{
  "pipes": [
    {
      "start": {"x": 0, "y": 0, "z": 0},
      "end": {"x": 2, "y": 0, "z": 0},
      "diameter": 40,
      "type": "evacuation"
    }
  ],
  "fixtures": [
    {"position": {"x": 1, "y": 0, "z": 0}, "type": "sink"}
  ],
  "hot_water_source": {"position": {"x": 5, "y": 0, "z": 3}, "type": "cumulus", "capacity": 200}
}
```

## Electricity

```json
{
  "circuits": [
    {
      "name": "Prises Séjour",
      "breaker_amps": 16,
      "elements": [
        {"position": {"x": 1, "y": 0.3, "z": 0}, "type": "socket"}
      ]
    }
  ],
  "panel": {"position": {"x": 0.5, "y": 1.5, "z": 0.2}},
  "differential": {"rating_ma": 30, "type": "A"}
}
```

## Network

```json
{
  "points": [
    {"position": {"x": 1, "y": 0.3, "z": 0}, "type": "rj45"}
  ],
  "cables": [
    {"from": 0, "to": 1, "category": "cat6"}
  ],
  "patch_panel": {"position": {"x": 0.5, "y": 1.5, "z": 0.2}, "ports": 12},
  "wifi_zones": [
    {"position": {"x": 5, "y": 2.4, "z": 3}, "radius": 8.0}
  ]
}
```

## Domotics

```json
{
  "sensors": [
    {"position": {"x": 2, "y": 2.3, "z": 2}, "type": "motion", "state": false}
  ],
  "actuators": [
    {"position": {"x": 2.5, "y": 2.4, "z": 2}, "type": "light", "state": false}
  ],
  "scenarios": [
    {
      "name": "Auto-éclairage",
      "conditions": [
        {"sensor_index": 0, "operator": "==", "value": true}
      ],
      "actions": [
        {"actuator_index": 0, "action": "turn_on", "value": null}
      ]
    }
  ]
}
```

## Fichier de sauvegarde

Chemin : `user://housemaster_save.json`
