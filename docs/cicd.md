# CI/CD — HouseMaster 3D

## Pipelines GitHub Actions

### 1. `build.yml` — Build & Tests

**Déclencheur** : Push sur `main`, `develop`, Pull Requests

**Étapes** :
1. Checkout du code
2. Téléchargement Godot 4.4 headless Linux
3. Import du projet
4. Exécution des tests (`test_runner.gd`)
5. Rapport des résultats

### 2. `quality.yml` — Qualité du code

**Déclencheur** : Pull Requests

**Étapes** :
1. Vérification syntaxe GDScript (chargement headless)
2. Recherche `emit_signal()` obsolètes
3. Vérification conventions de nommage
4. Rapport

### 3. `release.yml` — Release

**Déclencheur** : Tag `v*`

**Étapes** :
1. Export Windows x64
2. Export Linux x64
3. Création release GitHub
4. Upload des artefacts

## Exécution locale

```bash
# Tests
godot --headless -s tests/test_runner.gd

# Vérification rapide syntaxe
godot --headless --script res://scripts/main.gd --quit
```
