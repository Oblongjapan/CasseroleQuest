# Microwavr - AI Coding Agent Instructions

## Project Overview
Microwavr is a roguelike deckbuilding game built in **Godot 4.3** (GDScript). Players combine ingredient cards to create recipes in a microwave, managing moisture levels while progressing through increasingly complex combinations. Think "Slay the Spire meets cooking simulator."

**Core Loop**: Draw ingredients → Combine into recipes → Microwave → Shop → Repeat

## Architecture Overview

### Signal-Based Communication (Critical Pattern)
**Everything** communicates through `EventBus` (autoloaded singleton at `scripts/singletons/event_bus.gd`). Direct coupling between systems is avoided.

```gdscript
# CORRECT: Use EventBus for state changes
EventBus.round_started.emit(ingredient_1, ingredient_2)
EventBus.moisture_changed.emit(current, max_value, bonus)

# INCORRECT: Direct manager calls across boundaries
moisture_manager.update_display()  # UI should listen to signals instead
```

**Key signals to know**:
- `game_started`, `round_started`, `round_completed`
- `shop_opened`, `shop_closed`
- `moisture_changed`, `timer_updated`
- `deck_changed(cards_in_deck, total_cards)`

### Manager System (Single Responsibility)
Each manager handles ONE domain and is instantiated by `main.gd`:

- **FridgeManager**: Deck operations (draw, discard, reshuffle). Tracks persistent hand between rounds.
- **MoistureManager**: Moisture drain calculation based on ingredient stats + difficulty scaling
- **ProgressionManager**: Recipe tracking, tier unlocks (1-4), ingredient unlocking
- **RecipeBookManager**: Discovered recipes tracking and display
- **InventoryManager**: Relics (passive buffs like "Plastic Wrap")
- **ShopManager**: 3-sample shop system
- **GameStateManager**: FSM for game states (MAIN_MENU, COOKING, SHOP, etc.)

### Data Singletons (Autoloaded)
Godot autoloads at startup - these provide static data:
- `IngredientsData`: Base ingredient stats (8 base + 5 premium)
- `RecipesData`: Recipe combination logic, tier thresholds, naming
- `RelicsData`: Passive item definitions
- `MalfunctionsData`: Event modifiers

## Recipe System (Most Complex Component)

### Key Concept: Ingredient COUNT vs Tier PROGRESSION
**Recipes are classified by ingredient count** (2, 3, 4...8 max), NOT tier.  
**Tiers gate WHEN you can create those counts**, not how they're named.

```gdscript
# Example flow:
# Player has ["Chicken Breast", "Rice", "Broccoli"] cards
# Tier 1 (start): Can only make 2-ingredient recipes
# Player makes "Chicken+Rice" → "Chicken Rice Bowl" (NEW recipe discovered)
# After 6 unique 2-ingredient recipes → Tier 2 unlocks
# Now can combine 3+ ingredients: ["Chicken+Rice"] + [Broccoli] → "Chicken Broccoli Bowl"
```

### Recipe Combination Logic (`RecipesData.combine_ingredients`)
1. **Count base ingredients** - `"Chicken+Rice"` = 2 ingredients (split on `+`)
2. **Check tier gates**:
   - Tier 1: Max 2 ingredients
   - Tier 2: Max 4 ingredients (requires 6 unique tier-1 recipes)
   - Tier 3: Max 6 ingredients
   - Tier 4: Max 8 ingredients (absolute max)
3. **Calculate stats**:
   - Water: SUM of all unique base ingredients
   - Heat Resistance: AVERAGE
   - Volatility: AVERAGE if 2 ingredients, SUM if 3+ (more ingredients = more chaos)
4. **Generate identity**: Sort ingredient names alphabetically, join with `+` (internal name)
5. **Generate display name**: Use lookup table or fallback naming

**Critical**: Always strip `"Organic "` prefix when looking up base stats.

### Progression Thresholds
```gdscript
TIER_1_UNLOCK_THRESHOLD = 0   # Start here (2-ingredient recipes)
TIER_2_UNLOCK_THRESHOLD = 6   # Need 6 unique tier-1 recipes
TIER_3_UNLOCK_THRESHOLD = 12  # Need 12 total unique recipes
TIER_4_UNLOCK_THRESHOLD = 20  # Need 20 total unique recipes
```

## Deck Management (FridgeManager)

### Persistent Hand System
Unlike typical deckbuilders, some cards persist between rounds:
- **Shop samples**: 2 free samples per shop phase → added to persistent_hand
- **Organic upgrades**: Applied cards → persistent_hand
- These cards are **claimed** at start of next hand draw

```gdscript
# After shop phase
fridge_manager.add_to_persistent_hand(sampled_ingredient)

# When showing hand selector (next round)
var persistent_cards = fridge_manager.claim_persistent_hand()
# These cards are added to the new 5-card draw
```

### Reshuffle Behavior
- Draw from `deck`, discard to `discard_pile`
- When `deck` is empty → reshuffle `discard_pile` into `deck`
- Upgrades (from relics/shop) apply at draw time via `_apply_upgrades_to_card`

## UI Patterns

### Scene Structure
Main scene (`main.tscn`) contains:
- All UI screens as children (hidden by default)
- `_hide_all_ui()` called before showing new state
- Background sprite (microwave scene) with animated sprite

### Hand Selector (Most Complex UI)
Located at `scripts/ui/hand_selector.gd`. Handles:
1. Drawing 5 cards (or filling to 5 if persistent cards exist)
2. Drag-and-drop to 2 microwave overlay slots
3. Visual validation (can only start with 1-2 cards selected)
4. Emits `hand_selection_confirmed(ing1, ing2, discarded)` when START pressed

**Key**: Integrates with `ingredient_overlay.gd` for drag targets.

### Ingredient Card Display
Cards show:
- Name (with "⭐" prefix if organic)
- Texture(s) - combo recipes show multiple layered sprites
- Stats: Water, Heat Resistance, Volatility (with upgrade markers)

## Animation Patterns

### Recipe Reveal Flow
When a new recipe is created:
1. `_display_combo_in_microwave()` - Show combined ingredients
2. `RecipeCardReveal` scene - Animated card flies to recipe box
3. `_fade_out_combo_display()` - Clean up
4. Recipe added to deck AFTER animation completes

### Shop Flow
Camera pans from `main_camera_pos` to `shop_camera_pos`, applies phaser + low-pass filter to music.

## Testing & Debugging

### Python Generation Scripts
Root contains `generate_*.py` scripts for creating recipe data:
- `generate_5_batch.py` - Generates 5-ingredient recipe mappings
- Uses combinatorics to ensure coverage
- Output manually added to `recipes.gd`

### Debug Commands
In `_unhandled_input`:
```gdscript
if event.keycode == KEY_S:  # Force open shop
if event.keycode == KEY_SPACE:  # Toggle pause
```

### Common Issues
1. **Recipe won't combine**: Check tier restrictions in `combine_ingredients` logs
2. **Cards not appearing in hand**: Check `persistent_hand` wasn't cleared
3. **Moisture drains too fast**: Check difficulty multiplier in `moisture_manager.setup()`

## Code Conventions

### Naming
- Files: `snake_case` (e.g., `ingredient_model.gd`)
- Classes: `PascalCase` with `class_name` (e.g., `class_name IngredientModel`)
- Variables/functions: `snake_case`
- Constants: `UPPER_SNAKE_CASE`
- Signals: `snake_case_past_tense` (e.g., `round_completed`)

### Documentation
```gdscript
## Manager-level documentation for class purpose
## Uses double-hash for doc comments

# Single-hash for implementation comments

func example_function() -> void:
	## Optional function documentation
	pass
```

### Type Hints (Required)
Always use type hints for clarity:
```gdscript
var ingredients: Array[IngredientModel] = []
func draw_cards(count: int) -> Array[IngredientModel]:
```

## Project-Specific Gotchas

1. **Ingredient Duplication**: Always call `.duplicate()` when adding cards to deck - IngredientModel is `RefCounted`
2. **Organic Prefix**: Strip before stat lookups but preserve for display
3. **Combo Cards**: Use `"+"` separator internally, always sort alphabetically
4. **Wildcard Slots**: FridgeManager reserves 2 slots for newly unlocked ingredients
5. **Tier 0 vs Tier 1**: Tier 0 is "no recipes yet", Tier 1 unlocks with first recipe
6. **Hand Tracking**: `current_hand` tracks drawn cards, cleared on discard/consume
7. **Music Looping**: HTML5 export needs manual loop via `finished` signal

## Running the Game

1. Open `project.godot` in Godot 4.3+
2. Main scene: `scenes/main_menu.tscn` (auto-loads to `main.tscn`)
3. F5 to run
4. For web export: `Game Versions/Web/index.html`

## Key Files to Reference

- `scripts/main.gd` - Game orchestrator, 1200+ lines, handles all state transitions
- `scripts/data/recipes.gd` - Recipe system logic, 900+ lines of combinations
- `scripts/managers/fridge_manager.gd` - Deck operations
- `scripts/ui/hand_selector.gd` - Card selection UI
- `scenes/main.tscn` - Main game scene structure

## When Making Changes

1. **Adding ingredients**: Update `IngredientsData.INGREDIENTS`, add texture to `Assets/Food/`
2. **New recipes**: Add mapping to `recipes.gd` lookup table (generate with Python scripts)
3. **New relics**: Define in `RelicsData`, add to reward pools
4. **UI changes**: Ensure EventBus signals are preserved for loose coupling
5. **Balance changes**: Adjust tier thresholds in `RecipesData` or difficulty multipliers in `main.gd`

## Architecture Diagram
```
EventBus (Signals)
    ↓
Main.gd (Orchestrator)
    ↓
Managers (Single Responsibility)
    ↓
Models (Data Structures)
    ↓
UI Controllers (Listen to EventBus)
```
