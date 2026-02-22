# Règles Métier — HouseMaster 3D

## Dimensions générales

| Paramètre | Valeur |
|-----------|--------|
| Largeur extérieure | 10,50 m |
| Profondeur extérieure | 6,70 m |
| Hauteur sous plafond | 2,50 m |
| Épaisseur murs extérieurs | 0,20 m |
| Épaisseur cloisons | 0,10 m |

## Pièces — Dimensions par défaut

| Pièce | Dimensions | Surface | Type |
|-------|-----------|---------|------|
| Séjour + Cuisine | 5,50 × 6,70 m | 36,85 m² | living |
| Chambre 1 | 3,00 × 4,00 m | 12,00 m² | bedroom |
| Chambre 2 | 2,75 × 4,00 m | 11,00 m² | bedroom |
| SdB | 2,00 × 3,00 m | 6,00 m² | bathroom |
| WC | 1,00 × 2,00 m | 2,00 m² | wc |
| Cellier | 1,50 × 2,00 m | 3,00 m² | storage |

## Plomberie

- Pente minimale évacuation : **1%** (`MIN_SLOPE = 0.01`)
- Diamètres évacuation : 40, 50, 63, 75, 100 mm
- Diamètres alimentation : 12, 14, 16 mm
- Types de tuyaux : `evacuation`, `supply_cold`, `supply_hot`
- Appareils : `sink`, `toilet`, `shower`, `bathtub`, `washing_machine`, `dishwasher`

## Électricité (NF C 15-100)

- Max **8 prises** par circuit 16A
- Max **8 points lumineux** par circuit 10A
- Calibres disjoncteurs : 10A, 16A, 20A, 32A
- Interrupteur différentiel **30 mA** obligatoire
- Hauteur prises : 0,30 m minimum
- Hauteur interrupteurs : 1,10 m

## Réseau

- Grade minimal câblage : **Cat 6**
- Types câbles : cat5e, cat6, cat6a, cat7, fibre
- Arrivée fibre obligatoire validée
- Baie de brassage : 1 port par point + réserve 20%

## Domotique

### Capteurs

| Type | État par défaut | Unité |
|------|----------------|-------|
| motion | `false` | booléen |
| temperature | `20.0` | °C |
| opening | `false` | booléen |
| humidity | `50.0` | % |
| light_level | `500.0` | lux |

### Actionneurs

| Type | État par défaut | Plage |
|------|----------------|-------|
| light | `false` | on/off |
| shutter | `100` | 0-100% |
| heating | `20.0` | °C |
| alarm | `false` | on/off |
| lock | `true` | verrouillé/déverrouillé |

### Opérateurs de scénarios

`==`, `!=`, `<`, `>`, `<=`, `>=`

### Actions de scénarios

`turn_on`, `turn_off`, `set_value`, `toggle`
