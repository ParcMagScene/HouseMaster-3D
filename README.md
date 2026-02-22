# HouseMaster 3D

**Configurateur technique de maison en 3D** — Application Godot 4.4

[![Build](https://github.com/ParcMagScene/HouseMaster-3D/actions/workflows/build.yml/badge.svg)](https://github.com/ParcMagScene/HouseMaster-3D/actions/workflows/build.yml)
[![Quality](https://github.com/ParcMagScene/HouseMaster-3D/actions/workflows/quality.yml/badge.svg)](https://github.com/ParcMagScene/HouseMaster-3D/actions/workflows/quality.yml)

---

## Présentation

HouseMaster 3D est une application professionnelle permettant de :

- Concevoir une maison en **2D et 3D** temps réel
- Configurer les **réseaux techniques** : plomberie, électricité, réseau (RJ45/fibre/Wi-Fi), domotique
- Modifier **matériaux et dimensions** de chaque élément
- **Exporter** le projet (JSON, captures, plans)

Développé avec **Godot 4.4 stable** (Vulkan) en GDScript.

---

## Projet de référence — Maison 70 m²

| Donnée | Valeur |
|--------|--------|
| Dimensions extérieures | **10.50 × 6.70 m** (≈ 70 m²) |
| Séjour + cuisine | 5.50 × 6.70 m (35 m²) |
| Chambre 1 | 3.00 × 4.00 m (12 m²) |
| Chambre 2 | 2.75 × 4.00 m (11 m²) |
| Salle de bain | 2.00 × 3.00 m (6 m²) |
| WC | 1.00 × 2.00 m (2 m²) |
| Cellier | 1.50 × 2.00 m (3 m²) |
| Style | Moderne bois + noir, bardage mélèze, alu anthracite |
| Hauteur murs | 2.50 m |
| Épaisseur murs | 0.20 m |

---

## Installation

### Prérequis
- [Godot 4.4 stable](https://godotengine.org/download) (Windows/Linux/macOS)

### Lancer le projet
```bash
# Ouvrir dans l'éditeur Godot
godot --path "chemin/vers/HouseMaster-3D"

# Ou lancer directement
godot --path "chemin/vers/HouseMaster-3D" --main-scene res://scenes/Main.tscn
```

### Lancer les tests
```bash
godot --headless --script res://tests/test_runner.gd --path "chemin/vers/HouseMaster-3D"
```

---

## Fonctionnalités

### Maison
- Création et redimensionnement de pièces
- Portes, fenêtres, ouvertures
- 7 matériaux PBR (bois, béton, plâtre, métal, verre, mélèze, anthracite)

### Modules techniques

| Module | Couleur | Raccourci | Règles métier |
|--------|---------|-----------|---------------|
| **Plomberie** | 🔵 Bleu | F1 | Pente min 1%, diamètres 40-100mm évac / 12-16mm arrivée |
| **Électricité** | 🟡 Jaune | F2 | Max 8 prises/circuit, disjoncteurs 10A/16A/20A |
| **Réseau** | 🟢 Vert | F3 | RJ45 Cat6 min, fibre entrée, zones Wi-Fi |
| **Domotique** | 🟣 Violet | F4 | Capteurs, actionneurs, scénarios IF/THEN |

### Visualisation
- **Vue orbitale 3D** — rotation, zoom, pan
- **Vue free-fly** — déplacement libre
- **Vue 2D top-down** — plan orthographique
- **Layers techniques** — activation/désactivation par module

### Sauvegarde
- Export/import JSON complet
- Capture 3D (PNG)
- Plan 2D (PNG)
- Undo/Redo illimité

---

## Interface utilisateur

Thème **dark professionnel** inspiré de Blender 4 / Unreal Engine 5 :

- **Palette** : `#1E1E1E` fond / `#252525` panneaux / `#4DA3FF` accent / `#E6E6E6` texte
- **Layout** : barre de menus, hiérarchie (gauche), propriétés (droite), console (bas), barre de statut
- **Animations** : transitions Tween (fade, slide, pop) sur tous les panneaux
- **25 icônes SVG** vectorielles

### Raccourcis clavier

| Raccourci | Action |
|-----------|--------|
| Ctrl+S | Sauvegarder |
| Ctrl+O | Charger |
| F1-F4 | Ouvrir éditeurs modules |
| Molette | Zoom caméra |
| Clic milieu | Rotation caméra |
| Shift+Milieu | Pan caméra |

---

## Architecture

```
scripts/
├── main.gd                    # Orchestrateur principal
├── camera_controller.gd       # 3 modes caméra
├── save_manager.gd            # Sérialisation JSON
├── selection_manager.gd       # Sélection 3D (raycast)
├── undo_redo_manager.gd       # Historique actions
├── core/                      # Modèles métier
│   ├── house.gd
│   ├── room.gd
│   ├── wall.gd
│   └── material.gd
├── modules/                   # Modules techniques
│   ├── plumbing_module.gd
│   ├── electricity_module.gd
│   ├── network_module.gd
│   └── domotics_module.gd
└── ui/                        # Interface
    ├── main_ui.gd
    ├── room_editor.gd
    ├── plumbing_editor.gd
    ├── electricity_editor.gd
    ├── network_editor.gd
    ├── domotics_editor.gd
    ├── ui_theme.gd            # Thème centralisé
    └── ui_animations.gd       # Animations Tween
```

### Patterns
- **MVC** — Core (modèle) / UI (vue) / Main (contrôleur)
- **Observer** — Signaux Godot typés `UPPER_CASE`
- **Component** — Modules techniques enfants de House
- **Scene Composition** — Scènes .tscn indépendantes
- **Resource-based** — Matériaux en fichiers .tres

---

## Tests

**117 tests** répartis en 3 catégories :

| Catégorie | Fichiers | Couverture |
|-----------|----------|------------|
| Unitaires | 10 | House, Room, Wall, Material, Plumbing, Electricity, Network, Domotics, Save, Undo/Redo |
| Intégration | 2 | Workflow complet, Sérialisation JSON |
| Performance | 1 | Benchmarks génération, rendu, réseaux |

```bash
# Exécuter tous les tests
godot --headless --script res://tests/test_runner.gd --path .
```

---

## CI/CD

3 pipelines GitHub Actions :

| Pipeline | Déclencheur | Actions |
|----------|-------------|---------|
| `build.yml` | Push / PR | Build + tests + benchmarks |
| `quality.yml` | Push / PR | Linting + analyse statique |
| `release.yml` | Tag `v*` | Export EXE + ZIP release |

---

## Documentation

La documentation complète est dans le dossier [`docs/`](docs/) :

- [Architecture](docs/architecture.md) — Patterns et organisation
- [Classes Core](docs/classes_core.md) — House, Room, Wall, Material
- [Modules Techniques](docs/modules_techniques.md) — Plomberie, Électricité, Réseau, Domotique
- [Signaux](docs/signaux.md) — Cartographie complète
- [Format JSON](docs/format_json.md) — Structure de sauvegarde
- [Règles Métier](docs/regles_metier.md) — Normes et contraintes
- [Tests](docs/tests.md) — Organisation et exécution
- [Plugin Qualité](docs/plugin_qualite.md) — EditorPlugin d'analyse
- [CI/CD](docs/cicd.md) — Pipelines GitHub Actions

---

## Inventaire

| Catégorie | Quantité |
|-----------|----------|
| Scripts GDScript | 37 |
| Scènes .tscn | 9 |
| Matériaux .tres | 7 |
| Icônes SVG | 25 |
| Tests | 117 (13 fichiers) |
| Documentation | 10 fichiers |
| Pipelines CI/CD | 3 |

---

## Format de sauvegarde JSON

```json
{
  "house": {
    "exterior_width": 10.5,
    "exterior_depth": 6.7,
    "wall_height": 2.5,
    "wall_thickness": 0.2
  },
  "rooms": [...],
  "plumbing": {...},
  "electricity": {...},
  "network": {...},
  "domotics": {...}
}
```

---

## Conventions

| Convention | Règle |
|------------|-------|
| Scripts | `snake_case` |
| Scènes | `PascalCase` |
| Signaux | `UPPER_CASE` |
| Dossiers | `snake_case` |
| Commits | Message descriptif en français |

---

## Licence

Projet personnel — Alexandre Alouges © 2026