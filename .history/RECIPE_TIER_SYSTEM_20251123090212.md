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

### Files Modified:

1. **`scripts/data/recipes.gd`**
   - Added clear tier constants with ingredient count limits
   - `TIER_1_MAX_INGREDIENTS = 2` enforces the 2-ingredient limit
   - `TIER_2_UNLOCK_THRESHOLD = 6` requires 6 unique recipes
   - Updated `combine_ingredients()` to accept `current_tier` parameter
   - Blocks 3+ ingredient recipes if current tier < 2
   - Returns null and logs block message when tier restriction applies

2. **`scripts/managers/progression_manager.gd`**
   - Tracks `current_tier` starting at 0
   - `_check_tier_unlocks()` evaluates tier progression after each new recipe
   - Updated tier unlock messages to clearly indicate capability unlocks:
     - Tier 1: "2-Ingredient Recipes!"
     - Tier 2: "3+ Ingredient Recipes!"
   - Emits `tier_unlocked` signal when thresholds reached

3. **`scripts/ui/tier_unlock_overlay.gd`**
   - Updated tier descriptions to match new system:
     - "2-Ingredient Recipes!" (Tier 1)
     - "3+ Ingredient Recipes!" (Tier 2)
   - Achievement overlay animated slide-in from bottom-right
   - Auto-dismisses after 4 seconds
   - Color-coded by tier (Green → Blue → Purple → Gold)

4. **`scripts/main.gd`**
   - Updated `_check_and_create_recipe()` to pass `current_tier` to `combine_ingredients()`
   - Added tier restriction detection when recipe creation fails
   - Logs helpful messages showing recipes remaining until Tier 2 unlock
   - Ingredients returned to discard pile when blocked by tier restriction

## How It Works

### Recipe Creation Flow:
1. Player selects 2+ ingredients and completes a round
2. System calls `RecipesData.combine_ingredients(ingredients, current_tier)`
3. **TIER CHECK:** If ingredients.size() > 2 and current_tier < 2:
   - Recipe creation BLOCKED
   - Returns null
   - Logs: "❌ BLOCKED: X-ingredient recipe requires Tier 2!"
   - Ingredients returned to discard pile
4. If tier check passes:
   - Dynamic combo created using merge rules (Water=sum, RST=avg, Vol=avg)
   - Recipe registered in `progression_manager`
   - Progression manager checks if tier threshold reached
   - If new tier unlocked, achievement overlay appears for 4 seconds

### Tier Unlock Notification:
- Appears in bottom-right corner
- Displays tier number and description
- Color changes based on tier:
  - **Tier 1:** Green - "2-Ingredient Recipes!"
  - **Tier 2:** Blue - "3+ Ingredient Recipes!"
  - **Tier 3:** Purple - "Advanced Recipes!"
  - **Tier 4:** Gold - "Legendary Recipes!"

## Testing the Tier Gate

### Test Scenario 1: Pre-Tier 2 (0-5 recipes created)
1. Start game (Tier 0)
2. Create first 2-ingredient recipe → Tier 1 unlocks (green notification)
3. Try combining 3 ingredients → **BLOCKED** ❌
   - Console shows: "BLOCKED: 3-ingredient recipe requires Tier 2!"
   - Ingredients returned to discard
4. Create 5 more 2-ingredient recipes (6 total unique)
5. On 6th recipe → Tier 2 unlocks (blue notification: "3+ Ingredient Recipes!")

### Test Scenario 2: Post-Tier 2 (6+ recipes created)
1. Combine 3 ingredients → ✅ Success! Recipe created
2. Combine 4 ingredients → ✅ Success! Recipe created
3. Combine any number of ingredients → ✅ All work now

## Key Design Benefits

1. **Clear Learning Progression:** Players learn 2-ingredient combinations before complex recipes
2. **Prevents Overwhelming Choices:** Limits early game complexity
3. **Explicit Gate:** Clear message when blocked, shows progress needed
4. **Natural Tutorial:** Forces engagement with core mechanics before advanced features
5. **Achievement Feel:** Unlocking Tier 2 feels rewarding after 6 discoveries
   - 30 recipes (Tier 3)
   - 42 recipes (Tier 4)

## Future Enhancements
- Add specific tier-gated predefined recipes
- Track unique vs repeated recipes
- Add recipe discovery journal/codex
- Victory condition when final legendary recipe is created
