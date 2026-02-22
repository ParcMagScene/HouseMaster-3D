# Plugin Qualité — HouseMaster 3D

## Installation

1. Le plugin se trouve dans `addons/quality_tools/`
2. Dans Godot : **Projet → Paramètres du projet → Extensions**
3. Activer **HouseMaster Quality**
4. Le dock apparaît dans le panneau droit inférieur

## Fonctionnalités

### 1. Analyse statique (Lint)

Vérifie dans tous les scripts `res://scripts/` :

- Lignes > 120 caractères
- Mélange tabs/espaces
- Espaces en fin de ligne (trailing whitespace)
- Appels `print()` restants (hors tests)

### 2. Vérification d'architecture

Valide la structure du projet :

- Dossiers attendus : `core/`, `modules/`, `ui/`, `scenes/`, `materials/`
- Fichiers core : `house.gd`, `room.gd`, `wall.gd`, `material.gd`
- Fichiers modules : `plumbing_module.gd`, `electricity_module.gd`, `network_module.gd`, `domotics_module.gd`

### 3. Vérification des signaux

Détecte les appels `emit_signal()` obsolètes (doit être `SIGNAL.emit()`).

### 4. Vérification null-safety

Détecte les accès `.get_children()`, `.get_child()`, `.get_child_count()` sans garde null dans les 3 lignes précédentes.

### 5. Conventions de nommage

- Signaux : `SCREAMING_SNAKE_CASE`
- Constantes : `SCREAMING_SNAKE_CASE` (sauf preloads)

## Boutons

| Bouton | Action |
|--------|--------|
| Analyse statique (lint) | Lance le lint seul |
| Vérifier architecture | Vérifie structure dossiers/fichiers |
| Vérifier signaux modernes | Cherche `emit_signal()` obsolètes |
| Vérifier null-safety | Détecte accès enfants non gardés |
| Vérifier conventions nommage | Vérifie conventions GDScript |
| ▶ Tout vérifier | Lance tous les checks |
