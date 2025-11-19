# Visual Examples of Ingredient Sprite Spreading

## How Overlap Works

### Without Overlap (Normal HBoxContainer)
```
Separation: 0 (default)

┌─────┐  ┌─────┐  ┌─────┐
│  🥬 │  │  🥔 │  │  🍞 │
│     │  │     │  │     │
└─────┘  └─────┘  └─────┘
```

### With Overlap (Negative Separation: -15px)
```
Separation: -15

┌─────┐
│  🥬 ┌┴────┐
│    │  🥔 ┌┴────┐
└────┤     │  🍞 │
     └─────┤     │
           └─────┘

Result: Ingredients appear stacked/layered
```

## Card Display Examples

### Draft Card with Ingredient Sprite
```
┌──────────────────────┐
│  ┌────┐ ┌────┐       │ ← Sprite Container (40px height)
│  │ 🥬 │ │ 🥔 │       │   Two ingredients overlapping
│  └────┘ └────┘       │
├──────────────────────┤
│                      │
│   [INGREDIENT]       │
│   Potato & Lettuce   │ ← Button (100px height)
│                      │
│   Water: 80          │
│   Heat Res: 60       │
└──────────────────────┘
```

### Single Ingredient Card
```
┌──────────────────────┐
│      ┌────┐          │ ← Sprite Container
│      │ 🥬 │          │   One ingredient centered
│      └────┘          │
├──────────────────────┤
│                      │
│   [INGREDIENT]       │
│   Lettuce            │ ← Button
│                      │
│   Water: 95          │
│   Heat Res: 20       │
└──────────────────────┘
```

## Plate Display During Cooking

### Microwave View with Plate
```
┌────────────────────────────────────┐
│  MOISTURE: ████████░░ 80%          │
│  TIMER: 00:12                      │
│                                    │
│  ┌──────────────────────────┐     │
│  │                          │     │
│  │      ┌─────────┐         │     │
│  │      │ ┌───┐   │         │     │ ← Microwave door
│  │      │ │🥬🥔│   │ ← Plate│     │   with visible plate
│  │      │ └───┘   │         │     │
│  │      └─────────┘         │     │
│  │                          │     │
│  └──────────────────────────┘     │
│                                    │
│  [Cover] [Stir] [Blow]            │
└────────────────────────────────────┘
```

### Close-up of Plate with Overlapping Ingredients
```
     Plate Area (200x80px)
┌────────────────────────┐
│                        │
│   ┌───┐ ┌───┐ ┌───┐   │ ← 3 ingredients
│   │🥬 │ │🥔 │ │🍞 │   │   overlapping by 15px each
│   └───┘ └───┘ └───┘   │
│                        │
└────────────────────────┘
```

## Color Examples

Each ingredient gets a unique color based on:
- **Hue**: Derived from ingredient name (consistent)
- **Saturation**: Based on water content (more water = more saturated)
- **Value**: Based on density (more dense = brighter)

### Example Ingredients:
```
Lettuce:
  Name Hash: → Hue (green range)
  Water: 95% → Saturation: 0.98
  Density: 25% → Value: 0.625
  Result: Light green color □

Chicken:
  Name Hash: → Hue (yellow/orange range)
  Water: 65% → Saturation: 0.86
  Density: 75% → Value: 0.875
  Result: Orange-yellow color □

Rice:
  Name Hash: → Hue (blue/purple range)
  Water: 15% → Saturation: 0.66
  Density: 85% → Value: 0.925
  Result: Light purple-blue □
```

## Configuration Options

### Adjusting Overlap
```gdscript
# More overlap (more stacking)
ingredient_container.set_overlap(30.0)  # 30px overlap

# Less overlap (more spread out)
ingredient_container.set_overlap(10.0)  # 10px overlap

# No overlap (side by side)
ingredient_container.set_overlap(0.0)   # 0px overlap
```

### Adjusting Sprite Size
```gdscript
# Larger sprites
ingredient_container.set_sprite_size(Vector2(100, 100))

# Smaller sprites
ingredient_container.set_sprite_size(Vector2(40, 40))

# Rectangular sprites (wider than tall)
ingredient_container.set_sprite_size(Vector2(80, 50))
```

## Integration Examples

### Example 1: Show ingredients in custom UI
```gdscript
# In your custom UI script
extends Control

@onready var ingredient_display = $IngredientSpriteContainer

func show_recipe(ingredients: Array[IngredientModel]):
    ingredient_display.display_ingredients(ingredients)
```

### Example 2: Dynamic ingredient list
```gdscript
# Update display when ingredients change
func _on_ingredients_changed(new_ingredients: Array[IngredientModel]):
    ingredient_display.clear_ingredients()
    ingredient_display.display_ingredients(new_ingredients)
```

### Example 3: Microwave display with custom styling
```gdscript
# In microwave display script
func setup_display():
    var container = IngredientSpriteContainer.new()
    container.overlap_amount = 25.0  # More overlap in microwave
    container.sprite_size = Vector2(60, 60)  # Smaller sprites
    add_child(container)
```

## Technical Notes

### HBoxContainer Separation
The overlap is achieved by using a negative value for the `separation` theme constant:
- Positive separation: Adds space between children
- Zero separation: Children touch edge-to-edge
- Negative separation: Children overlap by that amount

### Z-Order
Children added later appear on top of earlier children, creating a natural layering effect:
```
First ingredient:  Z-index 0 (bottom)
Second ingredient: Z-index 1 (middle)
Third ingredient:  Z-index 2 (top)
```

This creates a visual "stack" effect where later ingredients appear to be placed on top of earlier ones.
