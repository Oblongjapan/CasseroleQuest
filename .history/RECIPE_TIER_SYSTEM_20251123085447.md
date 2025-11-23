# Recipe Tier System - Implementation Guide

## Overview
The recipe tier system has been implemented with a clear progression gate: **players can only create 2-ingredient recipes until they've discovered 6 unique recipes, at which point 3+ ingredient recipes unlock.**

This creates a natural learning curve where players master simple combinations before moving to complex multi-ingredient recipes.

## Tier Structure

### TIER 0: Foundation (Base Ingredients)
- **Unlock Requirement:** Always available from game start
- **Ingredients:** Chicken Breast, Steak, Tofu, Potato, Rice, Peas, Bread, Lettuce, Spinach, Asparagus, Carrot
- **Total:** 11 base ingredients
- **Purpose:** The building blocks for all recipes

### TIER 1: 2-Ingredient Recipes ONLY
- **Unlock Requirement:** Available at game start
- **Restriction:** Can ONLY combine exactly 2 ingredients
- **Recipe Count:** 55 possible two-ingredient combinations (11 choose 2)
- **Examples:** 
  - Chicken Breast + Rice
  - Steak + Potato
  - Bread + Lettuce
  - Carrot + Peas
- **Goal:** Create 6 unique 2-ingredient recipes to unlock Tier 2

### TIER 2: 3+ Ingredient Recipes Unlocked
- **Unlock Requirement:** 6 unique 2-ingredient recipes created
- **New Capability:** Can now combine 3, 4, 5, or more ingredients
- **Examples:** 
  - Chicken Breast + Rice + Steak (3 ingredients)
  - Steak + Potato + Rice + Peas (4 ingredients)
  - Any combination of 3+ ingredients
- **Why 6 recipes?** This ensures players understand the basic mechanics before adding complexity

### TIER 3: Advanced Recipes
- **Unlock Requirement:** 30 total recipes created
- **Purpose:** Future advanced recipe mechanics (currently same as Tier 2)

### TIER 4: Legendary Recipes
- **Unlock Requirement:** 42 total recipes created
- **Purpose:** Endgame/legendary recipe mechanics (currently same as Tier 2)

## How the Gate Works

### Before Creating 6 Recipes (Tier 1):
```
Player puts 3 ingredients in microwave → System blocks it
Message: "❌ BLOCKED: 3-ingredient recipe requires Tier 2!"
         "You must create 6 unique 2-ingredient recipes first!"
Ingredients returned to discard pile
```

### After Creating 6 Recipes (Tier 2):
```
Player puts 3 ingredients in microwave → Recipe created successfully!
Tier 2 unlock notification appears
All future combinations (2, 3, 4+ ingredients) now work
```

## Recipe Combination Rules

When two or more ingredients are combined in the microwave:

1. **Water Content:** SUM of all ingredient water values
2. **Heat Resistance (RST):** AVERAGE of all ingredient heat resistance values (rounded)
3. **Volatility (Vol):** AVERAGE of all ingredient volatility values (rounded)

### Example:
- Chicken (Water: 50, RST: 55, Vol: 15)
- Rice (Water: 30, RST: 70, Vol: 4)

**Result:** Chicken+Rice (Water: 80, RST: 63, Vol: 10)

## Implementation Details

### Files Modified/Created:

1. **`scripts/data/recipes.gd`**
   - Added tier constants and thresholds
   - Added `combine_ingredients()` function for dynamic recipe creation
   - Added `get_unlocked_tier()` function

2. **`scripts/managers/progression_manager.gd`**
   - Added tier tracking variables
   - Added `_check_tier_unlocks()` function
   - Tier 1 unlocked by default at game start
   - Emits `tier_unlocked` signal when new tiers are reached

3. **`scripts/ui/tier_unlock_overlay.gd`** (NEW)
   - Achievement overlay UI component
   - Animated slide-in from bottom-right
   - Auto-dismisses after 4 seconds
   - Color-coded by tier (Green → Blue → Purple → Gold)

4. **`scenes/tier_unlock_overlay.tscn`** (NEW)
   - Scene file for achievement overlay
   - Positioned in bottom-right corner

5. **`scripts/main.gd`**
   - Integrated tier unlock overlay
   - Updated `_check_and_create_recipe()` to support dynamic combos
   - Connected progression manager tier unlock signal

## How It Works

### Recipe Creation Flow:
1. Player selects 2+ ingredients and completes a round
2. System first checks for predefined recipes (hardcoded combos)
3. If no match, creates dynamic combo using `combine_ingredients()`
4. Dynamic combo follows the merge rules (Water=sum, RST=avg, Vol=avg)
5. Recipe is registered in `progression_manager`
6. Progression manager checks if tier threshold reached
7. If new tier unlocked, achievement overlay appears for 4 seconds

### Tier Unlock Notification:
- Appears in bottom-right corner
- Displays tier number and description
- Color changes based on tier:
  - **Tier 1:** Green - "Simple Combos Unlocked!"
  - **Tier 2:** Blue - "Advanced Combos Unlocked!"
  - **Tier 3:** Purple - "Expert Recipes Unlocked!"
  - **Tier 4:** Gold - "Legendary Recipes Unlocked!"

## Testing
To test the system:
1. Start the game
2. Create combinations of ingredients
3. Watch the bottom-right corner for tier unlock notifications at:
   - 15 recipes (Tier 2)
   - 30 recipes (Tier 3)
   - 42 recipes (Tier 4)

## Future Enhancements
- Add specific tier-gated predefined recipes
- Track unique vs repeated recipes
- Add recipe discovery journal/codex
- Victory condition when final legendary recipe is created
