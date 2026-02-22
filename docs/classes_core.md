# Classes Core — HouseMaster 3D

## HouseCore (`scripts/core/house.gd`)

Conteneur principal de la maison.

### Propriétés

| Propriété | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `exterior_width` | `float` | `10.50` | Largeur extérieure (m) |
| `exterior_depth` | `float` | `6.70` | Profondeur extérieure (m) |
| `wall_height` | `float` | `2.50` | Hauteur des murs (m) |
| `wall_thickness` | `float` | `0.20` | Épaisseur des murs (m) |
| `rooms` | `Array[RoomCore]` | `[]` | Pièces de la maison |
| `walls` | `Array[WallCore]` | `[]` | Murs de la maison |

### Signaux

| Signal | Paramètres | Description |
|--------|-----------|-------------|
| `HOUSE_UPDATED` | — | Maison modifiée |
| `ROOM_ADDED` | `room: RoomCore` | Pièce ajoutée |
| `ROOM_REMOVED` | `room: RoomCore` | Pièce supprimée |
| `WALL_ADDED` | `wall: WallCore` | Mur ajouté |

### Méthodes

| Méthode | Retour | Description |
|---------|--------|-------------|
| `add_room(name, pos, size, type)` | `RoomCore` | Ajoute une pièce |
| `remove_room(room)` | `void` | Supprime une pièce |
| `to_dict()` | `Dictionary` | Sérialise la maison |
| `from_dict(data)` | `void` | Désérialise la maison |

---

## RoomCore (`scripts/core/room.gd`)

Pièce individuelle avec génération de mesh.

### Propriétés

| Propriété | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `room_name` | `String` | `""` | Nom de la pièce |
| `room_type` | `String` | `"other"` | Type (living, bedroom, bathroom, etc.) |
| `room_size` | `Vector2` | `Vector2(3, 3)` | Dimensions (largeur, profondeur) en m |
| `technical_points` | `Array` | `[]` | Points techniques (plomberie, élec, etc.) |

### Types de pièces

`living`, `bedroom`, `bathroom`, `wc`, `kitchen`, `storage`, `corridor`, `other`

### Signaux

| Signal | Paramètres | Description |
|--------|-----------|-------------|
| `ROOM_MODIFIED` | — | Pièce modifiée |

### Méthodes

| Méthode | Retour | Description |
|---------|--------|-------------|
| `get_surface()` | `float` | Surface en m² |
| `resize(new_size)` | `void` | Redimensionne la pièce |
| `generate_mesh()` | `void` | Régénère le mesh 3D |
| `add_technical_point(pos, type, label)` | `void` | Ajoute un point technique |
| `to_dict()` | `Dictionary` | Sérialise |
| `from_dict(data)` | `void` | Désérialise |

---

## WallCore (`scripts/core/wall.gd`)

Segment de mur avec ouvertures.

### Propriétés

| Propriété | Type | Description |
|-----------|------|-------------|
| `start_pos` | `Vector3` | Point de départ |
| `end_pos` | `Vector3` | Point de fin |
| `wall_height` | `float` | Hauteur (m) |
| `wall_thickness` | `float` | Épaisseur (m) |
| `is_exterior` | `bool` | Mur extérieur |
| `openings` | `Array` | Ouvertures (portes, fenêtres) |

### Signaux

| Signal | Paramètres | Description |
|--------|-----------|-------------|
| `WALL_MODIFIED` | — | Mur modifié |

### Méthodes

| Méthode | Retour | Description |
|---------|--------|-------------|
| `get_length()` | `float` | Longueur du mur |
| `add_opening(pos, width, height, type)` | `void` | Ajoute porte/fenêtre |
| `generate_mesh()` | `void` | Régénère le mesh |
| `to_dict()` | `Dictionary` | Sérialise |
| `from_dict(data)` | `void` | Désérialise |

---

## MaterialCore (`scripts/core/material.gd`)

Fabrique de matériaux prédéfinis.

### Presets disponibles

| Clé | Matériau | Couleur |
|-----|----------|---------|
| `meleze` | Mélèze bois | Brun chaud |
| `anthracite` | Anthracite | Gris foncé |
| `concrete` | Béton | Gris clair |
| `glass` | Verre | Transparent |
| `plaster` | Plâtre | Blanc |
| `wood` | Bois standard | Brun |
| `metal` | Métal | Argenté |
| `tile` | Carrelage | Beige |

### Méthodes statiques

| Méthode | Retour | Description |
|---------|--------|-------------|
| `get_material(key)` | `StandardMaterial3D` | Retourne un preset |
| `create_standard_material(color, metallic, roughness)` | `StandardMaterial3D` | Crée un matériau personnalisé |
