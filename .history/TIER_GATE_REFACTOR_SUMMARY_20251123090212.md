# Tier Gate Refactor - Summary

## What Changed

The tier system has been refactored to create a **clear progression gate**: players can only create 2-ingredient recipes until they've discovered 6 unique recipes, at which point 3+ ingredient recipes unlock.

## Key Changes

### 1. **Clear Tier Definitions** (`recipes.gd`)
- **Tier 1**: 2-ingredient recipes ONLY (available at game start)
- **Tier 2**: 3+ ingredient recipes (unlocks after 6 unique 2-ingredient recipes)
- Added `TIER_1_MAX_INGREDIENTS = 2` constant
- Added `TIER_2_MAX_INGREDIENTS = 99` constant

### 2. **Enforcement in Code** (`recipes.gd`)
- `combine_ingredients()` now takes `current_tier` parameter
- Blocks 3+ ingredient recipes if `current_tier < 2`
- Returns `null` with clear log message when blocked
- Formula remains: Water=sum, Heat Resistance=average, Volatility=average

### 3. **Tier Integration** (`main.gd`)
- Passes `progression_manager.current_tier` to `combine_ingredients()`
- Detects tier restrictions when recipe creation fails
- Calculates recipes remaining until Tier 2 unlock
- Shows popup notification to player when blocked

### 4. **User Feedback** (`main.gd`)
- New `_show_tier_restriction_message()` function
- Shows popup dialog with:
  - "⚠️ LOCKED: X-Ingredient Recipes"
  - Clear explanation of requirement
  - Exact count of recipes needed (e.g., "Create 3 more...")

### 5. **Updated Messages** (`progression_manager.gd`)
- Tier 1: "2-Ingredient Recipes!"
- Tier 2: "3+ Ingredient Recipes!"
- Console logs show clear capability unlocks

### 6. **UI Updates** (`tier_unlock_overlay.gd`)
- Tier descriptions updated to match new system
- Green notification for Tier 1 (2-ingredient)
- Blue notification for Tier 2 (3+ ingredient)

### 7. **Documentation** (`RECIPE_TIER_SYSTEM.md`)
- Complete rewrite with clear progression explanation
- Added "How the Gate Works" section with before/after scenarios
- Added test scenarios
- Listed key design benefits

## Testing the Gate

### Before Tier 2 (0-5 recipes):
1. Combine 2 ingredients → ✅ Works
2. Combine 3 ingredients → ❌ Blocked, popup shows
3. Create 6 total 2-ingredient recipes → Tier 2 unlocks

### After Tier 2 (6+ recipes):
1. Combine 2 ingredients → ✅ Works
2. Combine 3+ ingredients → ✅ Works
3. All future combinations work

## Files Modified

1. `scripts/data/recipes.gd`
2. `scripts/managers/progression_manager.gd`
3. `scripts/main.gd`
4. `scripts/ui/tier_unlock_overlay.gd`
5. `RECIPE_TIER_SYSTEM.md`

## Design Benefits

1. **Clear Learning Curve**: Forces players to master 2-ingredient basics first
2. **Prevents Overwhelming Complexity**: Limits early game decision paralysis
3. **Explicit Feedback**: Clear messages when blocked, shows progress needed
4. **Natural Tutorial**: Engages with core mechanics before advanced features
5. **Achievement Feel**: Tier 2 unlock is rewarding after 6 discoveries
