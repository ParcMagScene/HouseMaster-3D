# Tests — HouseMaster 3D

## Infrastructure

### TestBase (`tests/test_base.gd`)

Classe de base fournissant les assertions :

| Assertion | Description |
|-----------|-------------|
| `assert_true(val, msg)` | Vérifie `val == true` |
| `assert_false(val, msg)` | Vérifie `val == false` |
| `assert_equal(a, b, msg)` | Vérifie `a == b` |
| `assert_not_equal(a, b, msg)` | Vérifie `a != b` |
| `assert_gt(a, b, msg)` | Vérifie `a > b` |
| `assert_lt(a, b, msg)` | Vérifie `a < b` |
| `assert_gte(a, b, msg)` | Vérifie `a >= b` |
| `assert_in_range(val, min, max, msg)` | Vérifie `min <= val <= max` |
| `assert_not_null(val, msg)` | Vérifie `val != null` |
| `assert_null(val, msg)` | Vérifie `val == null` |
| `assert_has_method(obj, method, msg)` | Vérifie que `obj` a la méthode |
| `assert_array_size(arr, size, msg)` | Vérifie `arr.size() == size` |
| `assert_dict_has_key(dict, key, msg)` | Vérifie que la clé existe |

### TestRunner (`tests/test_runner.gd`)

Exécuteur SceneTree qui charge et lance tous les scripts de test.

**Commande** :
```bash
godot --headless -s tests/test_runner.gd
```

**Sortie** : Résumé avec ✅ passés, ❌ échoués, ⏭️ ignorés.

## Tests unitaires (`tests/unit/`)

| Fichier | Cible | Tests |
|---------|-------|-------|
| `test_house.gd` | HouseCore | 10 |
| `test_room.gd` | RoomCore | 10 |
| `test_wall.gd` | WallCore | 9 |
| `test_material.gd` | MaterialCore | 9 |
| `test_plumbing.gd` | PlumbingModule | 9 |
| `test_electricity.gd` | ElectricityModule | 9 |
| `test_network.gd` | NetworkModule | 8 |
| `test_domotics.gd` | DomoticsModule | 9 |
| `test_save_manager.gd` | SaveManager | 6 |
| `test_undo_redo.gd` | UndoRedoManager | 10 |
| **Total** | | **89** |

## Tests d'intégration (`tests/integration/`)

| Fichier | Description | Tests |
|---------|-------------|-------|
| `test_full_workflow.gd` | Cycle création → modules → sérialisation → undo/redo | 9 |
| `test_serialization.gd` | Round-trip `to_dict()` → `from_dict()` complet | 9 |
| **Total** | | **18** |

## Tests de performance (`tests/performance/`)

| Fichier | Description | Tests |
|---------|-------------|-------|
| `test_performance.gd` | Benchmarks création, sérialisation, évaluation | 10 |

Seuil par défaut : **500 ms**

## Total : 117 tests
