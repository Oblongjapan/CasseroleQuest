# Ingredient Sprite Spreading Implementation

## Overview
This implementation adds visual representation of ingredients spread along the x-axis with overlap, as requested in the issue. The same method is used in cards (draft/ingredient selector), the plate display, and can be used in the microwave view.

## Key Components

### 1. IngredientSpriteContainer (`scripts/ui/ingredient_sprite_container.gd`)
A reusable HBoxContainer component that displays ingredient sprites horizontally with overlap.

**Features:**
- Configurable overlap amount (default: 20 pixels)
- Configurable sprite size (default: 80x80)
- Color-coded placeholders based on ingredient properties
- Can be used anywhere ingredients need to be displayed

**How overlap works:**
- Uses negative `separation` theme constant on HBoxContainer
- Example: `separation = -15` means sprites overlap by 15 pixels
- This creates the visual effect of ingredients stacked on each other

### 2. PlateDisplay (`scripts/ui/plate_display.gd`)
A specialized component for showing ingredients during the cooking round.

**Features:**
- Shows/hides based on round state (via EventBus signals)
- Displays up to 2 ingredients (or the same ingredient twice if selected twice)
- Positioned in the center of the game view (inside microwave area)

### 3. Card Integration
Both `draft_selector.gd` and `ingredient_selector.gd` now create visual sprite displays above ingredient cards.

**Implementation:**
- Ingredient cards now use a VBoxContainer
- Sprite display is at the top (40px height)
- Button is below
- Sprites overlap by 15 pixels
- Each ingredient gets a unique, deterministic color

## Color Generation Algorithm
Colors are generated based on ingredient properties to make them distinctive and recognizable:

```gdscript
# HSV color space for better visual variety
hue = hash(ingredient.name) mod 360 / 360.0  # Unique per ingredient
saturation = 0.6 + (water_content / 100) * 0.4  # More water = more saturated
value = 0.5 + (density / 100) * 0.5  # More dense = brighter
```

## Visual Layout

### Card Layout (Draft/Ingredient Selector)
```
┌─────────────────┐
│ [Sprite Display]│ ← Ingredient visual (40px height)
│  ▓▓▓▓▓          │   Colored panels overlapping by 15px
├─────────────────┤
│                 │
│  [INGREDIENT]   │ ← Button with text info
│  Chicken Breast │
│                 │
│  Stats...       │
└─────────────────┘
```

### Plate Display (During Cooking)
```
     Microwave Background
     ┌─────────────────┐
     │                 │
     │   ┌─────────┐   │
     │   │ ▓▓▓ ▓▓▓ │   │ ← Ingredients overlapping
     │   └─────────┘   │
     │                 │
     └─────────────────┘
```

## Configuration

### Adjusting Overlap Amount
In `ingredient_sprite_container.gd`:
```gdscript
@export var overlap_amount: float = 20.0  # Increase for more overlap
```

Or programmatically:
```gdscript
sprite_container.set_overlap(30.0)  # 30 pixel overlap
```

### Adjusting Sprite Size
```gdscript
@export var sprite_size: Vector2 = Vector2(80, 80)  # Width x Height
```

Or programmatically:
```gdscript
sprite_container.set_sprite_size(Vector2(100, 100))
```

### Card Sprite Display
In draft_selector.gd and ingredient_selector.gd:
```gdscript
# Overlap for card displays (line ~194/~72)
container.add_theme_constant_override("separation", -15)  # Adjust this value

# Sprite size for card displays (line ~198/~76)
panel.custom_minimum_size = Vector2(50, 35)  # Adjust width/height
```

## Scene Hierarchy
```
UI (CanvasLayer)
├─ Background (Sprite2D) - Microwave image
├─ PlateDisplay (Control) - NEW
│  └─ IngredientContainer (HBoxContainer) - NEW
│     └─ [Ingredient sprites added dynamically]
├─ MoistureBar (ProgressBar)
├─ ...other UI elements
├─ IngredientSelector (Panel)
│  └─ VBoxContainer
│     └─ IngredientGrid (GridContainer)
│        └─ [Cards with sprite displays]
└─ DraftSelector (Panel)
   └─ VBoxContainer
      └─ DraftGrid (GridContainer)
         └─ [Cards with sprite displays]
```

## Usage Examples

### Using IngredientSpriteContainer Directly
```gdscript
# Create and configure
var sprite_container = preload("res://scripts/ui/ingredient_sprite_container.gd").new()
add_child(sprite_container)

# Display ingredients
var ingredients: Array[IngredientModel] = [ing1, ing2]
sprite_container.display_ingredients(ingredients)

# Adjust appearance
sprite_container.set_overlap(25.0)  # More overlap
sprite_container.set_sprite_size(Vector2(60, 60))  # Smaller sprites
```

### Adding to New UI Elements
To add ingredient sprite display to any new component:
1. Add an HBoxContainer node
2. Attach `ingredient_sprite_container.gd` script
3. Call `display_ingredients()` with your ingredient array
4. The sprites will automatically arrange with overlap

## Future Enhancements
When actual ingredient sprite images are available:
1. Replace `use_colored_placeholders = true` with `false`
2. Add texture loading in `_create_ingredient_sprite()`:
   ```gdscript
   var texture_rect = TextureRect.new()
   texture_rect.texture = load("res://Assets/ingredients/%s.png" % ingredient.name.to_lower())
   panel.add_child(texture_rect)
   ```
3. Ensure all ingredient images are named consistently (e.g., "chicken.png", "lettuce.png")

## Testing Checklist
When testing in Godot editor:
- [ ] Ingredient cards in selector show colored sprite boxes
- [ ] Draft cards for ingredients show colored sprite boxes
- [ ] Multiple ingredients overlap correctly (negative separation visible)
- [ ] PlateDisplay appears during cooking round
- [ ] PlateDisplay hides when round ends
- [ ] Colors are consistent for the same ingredient
- [ ] Different ingredients have different colors
- [ ] Two of the same ingredient shows two sprites

## Notes
- The overlap effect is achieved using negative separation on HBoxContainer
- Colors are deterministic (same ingredient always gets same color)
- The system is designed to work with placeholder colors now, real sprites later
- All positioning is relative to parent containers for proper scaling
