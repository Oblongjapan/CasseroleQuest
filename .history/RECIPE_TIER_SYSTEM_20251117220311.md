# Recipe Tier System - Implementation Guide

## Overview
The recipe tier system has been successfully implemented with 5 tiers (0-4) that unlock as players create more recipes. The system includes:
- Automatic recipe combination based on card merging rules
- Tier unlock tracking and notifications
- Achievement overlay in the bottom-right corner

## Tier Structure

### TIER 0: Foundation (Base Ingredients)
- **Unlock Requirement:** Always available
- **Ingredients:** Chicken Breast, Steak, Tofu, Potato, Rice, Peas, Bread, Lettuce, Spinach, Asparagus, Carrot
- **Total:** 11 base ingredients

### TIER 1: Simple Combos
- **Unlock Requirement:** Available at game start
- **Recipe Count:** 45 two-ingredient combinations
- **Examples:** Chicken + Steak, Chicken + Rice, Steak + Potato, etc.

### TIER 2: Advanced Combos
- **Unlock Requirement:** 15 total recipes created
- **Recipe Count:** 10 multi-ingredient recipes
- **Examples:** Chicken + Steak + Chicken + Rice, Steak + Potato + Steak + Rice

### TIER 3: Expert Recipes
- **Unlock Requirement:** 30 total recipes created
- **Recipe Count:** 7 complex recipes
- **Examples:** Potato + Lettuce + Potato + Carrot + Potato + Carrot

### TIER 4: Legendary Recipes
- **Unlock Requirement:** 42 total recipes created
- **Recipe Count:** 3 legendary recipes
- **Victory Recipe:** 17-ingredient ultimate combo

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
