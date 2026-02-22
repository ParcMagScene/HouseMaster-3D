# Signaux — HouseMaster 3D

## Convention

- **Nommage** : `SCREAMING_SNAKE_CASE`
- **Syntaxe** : `SIGNAL_NAME.emit(args)` (Godot 4 moderne)
- **Interdit** : `emit_signal("...")` (obsolète)

## Catalogue complet

### HouseCore

| Signal | Émis quand |
|--------|-----------|
| `HOUSE_UPDATED` | Structure maison modifiée |
| `ROOM_ADDED(room)` | Pièce ajoutée |
| `ROOM_REMOVED(room)` | Pièce supprimée |
| `WALL_ADDED(wall)` | Mur ajouté |

### RoomCore

| Signal | Émis quand |
|--------|-----------|
| `ROOM_MODIFIED` | Propriétés de pièce modifiées |

### WallCore

| Signal | Émis quand |
|--------|-----------|
| `WALL_MODIFIED` | Mur modifié (dimensions, ouvertures) |

### PlumbingModule

| Signal | Émis quand |
|--------|-----------|
| `PIPE_ADDED(pipe)` | Tuyau ajouté |
| `PIPE_REMOVED(index)` | Tuyau supprimé |
| `FIXTURE_ADDED(fixture)` | Appareil ajouté |
| `FIXTURE_REMOVED(index)` | Appareil supprimé |
| `PLUMBING_VALIDATED(results)` | Validation effectuée |

### ElectricityModule

| Signal | Émis quand |
|--------|-----------|
| `CIRCUIT_ADDED(circuit)` | Circuit ajouté |
| `CIRCUIT_REMOVED(index)` | Circuit supprimé |
| `ELEMENT_ADDED(element)` | Élément ajouté |
| `ELEMENT_REMOVED(circuit_idx, element_idx)` | Élément supprimé |
| `ELECTRICITY_VALIDATED(results)` | Validation effectuée |

### NetworkModule

| Signal | Émis quand |
|--------|-----------|
| `POINT_ADDED(point)` | Point réseau ajouté |
| `POINT_REMOVED(index)` | Point supprimé |
| `CABLE_ADDED(cable)` | Câble ajouté |
| `CABLE_REMOVED(index)` | Câble supprimé |
| `NETWORK_VALIDATED(results)` | Validation effectuée |

### DomoticsModule

| Signal | Émis quand |
|--------|-----------|
| `SENSOR_ADDED(sensor)` | Capteur ajouté |
| `SENSOR_REMOVED(index)` | Capteur supprimé |
| `ACTUATOR_ADDED(actuator)` | Actionneur ajouté |
| `ACTUATOR_REMOVED(index)` | Actionneur supprimé |
| `SCENARIO_ADDED(scenario)` | Scénario ajouté |
| `SCENARIO_REMOVED(index)` | Scénario supprimé |

### SelectionManager

| Signal | Émis quand |
|--------|-----------|
| `OBJECT_SELECTED(object)` | Objet sélectionné |
| `OBJECT_DESELECTED` | Sélection effacée |
| `SELECTION_CHANGED(object)` | Sélection changée |

### CameraController

| Signal | Émis quand |
|--------|-----------|
| `MODE_CHANGED(mode)` | Mode caméra changé |
| `ZOOM_CHANGED(level)` | Zoom modifié |
| `POSITION_CHANGED(pos)` | Position caméra changée |

### UndoRedoManager

| Signal | Émis quand |
|--------|-----------|
| `ACTION_PERFORMED(desc)` | Action effectuée |
| `UNDO_PERFORMED(desc)` | Undo effectué |
| `REDO_PERFORMED(desc)` | Redo effectué |

### SaveManager

| Signal | Émis quand |
|--------|-----------|
| `SAVE_COMPLETED(path)` | Sauvegarde terminée |
| `LOAD_COMPLETED(path)` | Chargement terminé |
| `EXPORT_COMPLETED(path)` | Export terminé |

### MainUI

| Signal | Émis quand |
|--------|-----------|
| `MODULE_SELECTED(module)` | Module sélectionné dans l'UI |
| `TOOL_CHANGED(tool)` | Outil changé |
| `VIEW_CHANGED(view)` | Vue changée |
