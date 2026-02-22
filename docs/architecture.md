# Architecture — HouseMaster 3D

## Patterns utilisés

| Pattern | Usage |
|---------|-------|
| **MVC** | Séparation données (core), vue (scenes), contrôle (scripts racine) |
| **Observer** | Signaux Godot pour communication découplée |
| **Component** | Modules techniques indépendants attachés à la House |
| **Scene Composition** | Scènes `.tscn` imbriquées |
| **Resource** | Matériaux `.tres` réutilisables |

## Structure des dossiers

```
project.godot
scripts/
├── core/              # Données métier pures
│   ├── house.gd       # HouseCore — conteneur principal
│   ├── room.gd        # RoomCore — pièce individuelle
│   ├── wall.gd        # WallCore — segment de mur
│   └── material.gd    # MaterialCore — presets matériaux
├── modules/           # Modules techniques
│   ├── plumbing_module.gd
│   ├── electricity_module.gd
│   ├── network_module.gd
│   └── domotics_module.gd
├── ui/                # Éditeurs visuels
│   ├── main_ui.gd
│   ├── room_editor.gd
│   ├── plumbing_editor.gd
│   ├── electricity_editor.gd
│   ├── network_editor.gd
│   └── domotics_editor.gd
├── camera_controller.gd
├── main.gd            # Orchestrateur principal
├── save_manager.gd
├── selection_manager.gd
└── undo_redo_manager.gd
scenes/
├── Main.tscn          # Scène racine
├── House.tscn
├── Room.tscn
├── Wall.tscn
├── Domotics/DomoticsModule.tscn
├── Electricity/ElectricityModule.tscn
├── Network/NetworkModule.tscn
└── Plumbing/PlumbingModule.tscn
materials/             # Ressources .tres
tests/
├── test_runner.gd
├── test_base.gd
├── unit/
├── integration/
└── performance/
addons/
└── quality_tools/     # EditorPlugin lint/archi
docs/                  # Documentation
.github/workflows/     # CI/CD
```

## Flux de données

```
main.gd (orchestrateur)
  ├── HouseCore
  │     ├── RoomCore × 6
  │     └── WallCore × N
  ├── PlumbingModule
  ├── ElectricityModule
  ├── NetworkModule
  ├── DomoticsModule
  ├── CameraController
  ├── SelectionManager
  ├── UndoRedoManager
  ├── SaveManager
  └── MainUI
        ├── RoomEditor
        ├── PlumbingEditor
        ├── ElectricityEditor
        ├── NetworkEditor
        └── DomoticsEditor
```

## Communication

Tous les composants communiquent via **signaux Godot** (syntaxe moderne `.emit()`).
Le `main.gd` connecte les signaux des composants entre eux au démarrage.
Aucun couplage direct entre modules.
