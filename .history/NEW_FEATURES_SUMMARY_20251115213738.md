# New Features Implementation Summary

## Overview
This document summarizes the new features implemented for the 3-round progression system, fixed starting deck, 5-card hands, and deck editor.

## Changes Made

### 1. Fixed Starting Deck (12 cards)
**File**: `scripts/managers/fridge_manager.gd`
- Modified `initialize_starting_deck()` function
- New starting deck composition:
  - 2x Rice
  - 2x Bread
  - 1x Chicken Breast
  - 2x Broccoli
  - 2x Potato
  - 1x Steak
  - 2x Peas
- Total: 12 cards (up from 10 random cards)

### 2. 3-Round Progression System
**File**: `scripts/main.gd`
- Added `rounds_in_current_chunk` variable to track progress (0, 1, 2)
- Modified `_check_map_progress()` to:
  - Count rounds (1/3, 2/3, 3/3)
  - Only open shop after completing 3 rounds
  - Increment power level after shop (not after each round)
  - Continue to next round if chunk incomplete
- Added `_update_round_counter_display()` function
- Updated `_show_hand_selector()` to display round counter
- Round counter displays as "Round X/3" in status label

**Flow**: 
- Round 1 → Round 2 → Round 3 → Shop → Power Level +1 → Round 1 (new chunk)

### 3. 5-Card Hand System
**File**: `scripts/ui/hand_selector.gd`
- Changed `show_hand_selection()` to draw 5 cards instead of 3
- Updated from: `var cards_to_draw = 3 - hand_ingredients.size()`
- Updated to: `var cards_to_draw = 5 - hand_ingredients.size()`
- Players now select 2 ingredients from a hand of 5 cards
- Unused cards remain in hand for next round (existing behavior)

### 4. Deck Editor Scene
**New Files**:
- `scenes/deck_editor.tscn` - Standalone deck editor UI scene
- `scripts/ui/deck_editor.gd` - Deck editor logic

**Features**:
- Left panel: List of all available ingredients with "+" buttons
- Right panel: Current deck composition with "-" buttons
- Shows ingredient counts (e.g., "Rice x2")
- Total card counter
- Deck name input field
- Save/Load/Close buttons

**Signals**:
- `deck_saved(deck_name, deck_composition)` - Emitted when deck is saved
- `deck_loaded(deck_name, deck_composition)` - Emitted when deck is loaded
- `editor_closed()` - Emitted when editor is closed

### 5. Deck Save/Load System
**File**: `scripts/data/ingredients.gd`

**New Functions**:
- `save_custom_deck(deck_name: String, composition: Dictionary) -> bool`
  - Saves deck to `user://custom_decks/{deck_name}.json`
  - Stores composition as JSON with metadata
  - Creates directory if needed
  
- `load_custom_deck(deck_name: String) -> Dictionary`
  - Loads deck from `user://custom_decks/{deck_name}.json`
  - Returns composition dictionary
  - Returns empty dict if file not found
  
- `get_saved_deck_names() -> Array[String]`
  - Lists all saved deck files
  - Scans `user://custom_decks/` directory

**Save Format**:
```json
{
    "deck_name": "My Custom Deck",
    "composition": {
        "Rice": 2,
        "Bread": 3,
        "Chicken Breast": 1
    },
    "created_at": "2024-01-01 12:00:00"
}
```

## Usage

### Opening the Deck Editor
Add this code to open the deck editor (e.g., from main menu):
```gdscript
var deck_editor = preload("res://scenes/deck_editor.tscn").instantiate()
add_child(deck_editor)
deck_editor.show_editor()
```

### Loading a Custom Deck in FridgeManager
To use a custom deck instead of the default starting deck:
```gdscript
# In fridge_manager.gd or wherever you initialize
var custom_composition = IngredientsData.load_custom_deck("My Custom Deck")
if not custom_composition.is_empty():
    # Use custom composition
    for ingredient_name in custom_composition.keys():
        var count = custom_composition[ingredient_name]
        # Add ingredients...
```

### Listing Available Decks
```gdscript
var deck_names = IngredientsData.get_saved_deck_names()
for deck_name in deck_names:
    print("Available deck: %s" % deck_name)
```

## Testing Checklist

- [x] Compile errors fixed in fridge_manager.gd
- [ ] Start game and verify 12-card starting deck loads correctly
- [ ] Verify hand shows 5 cards
- [ ] Complete round 1/3 and verify it continues to round 2/3
- [ ] Complete round 2/3 and verify it continues to round 3/3
- [ ] Complete round 3/3 and verify shop opens
- [ ] Verify power level increases after shop
- [ ] Open deck editor scene and test UI
- [ ] Add ingredients to deck and verify count updates
- [ ] Remove ingredients from deck and verify count updates
- [ ] Save a custom deck and verify file is created
- [ ] Load a saved deck and verify composition is restored

## File Locations

### Modified Files
- `scripts/managers/fridge_manager.gd` - Starting deck composition
- `scripts/main.gd` - Round progression logic
- `scripts/ui/hand_selector.gd` - 5-card hand system
- `scripts/data/ingredients.gd` - Save/load functions

### New Files
- `scenes/deck_editor.tscn` - Deck editor scene
- `scripts/ui/deck_editor.gd` - Deck editor script

### Save Directory
- `user://custom_decks/*.json` - Custom deck save files

## Notes

1. **Round Counter Display**: Uses the existing `status_label` from main.tscn. If this label is used for other purposes, consider adding a dedicated round counter label.

2. **Power Level**: Now increments only after completing a 3-round chunk and visiting the shop, not after each individual round.

3. **Hand Persistence**: The hand selector keeps unused cards from previous rounds. This means if you draw 5 cards and use 2, the remaining 3 stay in your hand for the next round.

4. **Water Cup**: The special "Water Cup" ingredient is still added through the first shop visit and is excluded from the deck editor's available ingredients list.

5. **Deck Validation**: The deck editor does not enforce minimum/maximum deck sizes. You can create decks of any size.

## Future Enhancements (Optional)

- Add deck size validation (e.g., min 10 cards, max 20 cards)
- Add "Delete Deck" button in deck editor
- Add deck preview when loading (show composition before applying)
- Add "Apply as Starting Deck" button to use custom deck immediately
- Add deck import/export functionality
- Add deck statistics (total moisture, average heat resistance, etc.)
