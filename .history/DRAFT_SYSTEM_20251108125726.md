# Roguelike Draft System - Implementation Summary

## Overview
The microwave game now features a roguelike progression system where players start with NO items and must draft their collection through multiple phases.

## Game Flow

### 1. Initial Draft (Game Start)
- Player sees 6 random ingredients
- Can choose 0-3 ingredients to start with
- No active items or relics available yet

### 2. Ingredient Selection
- Player selects up to 2 ingredients from their collection
- Can only use ingredients they've drafted
- Must have at least 1 ingredient to start cooking

### 3. Cooking Round
- 15-second timer (constant across all rounds)
- Moisture drains based on ingredient stats × difficulty multiplier
- Use owned active items (max 3) to manage moisture
- Difficulty increases 10% per round (affected by relics)

### 4. Post-Round Draft (On Success)
- 3 random items appear:
  - Ingredients (any from the pool)
  - Active Items (Cover, Stir, Blow) - max 3 total
  - Relics (passive effects)
- Choose 0-2 items to add to inventory
- Can skip and take nothing

### 5. Failure State
- Round counter resets to 1
- Inventory completely cleared
- Return to initial draft phase

## Item Types

### Ingredients
- Used for cooking (select 2 per round)
- Affect base moisture drain rate
- Stats: Water Content, Heat Resistance, Density, Spice Level

### Active Items (Max 3)
- **Cover**: Reduce drain by 40% for 5s (8s cooldown)
- **Stir**: Restore 20 moisture instantly (6s cooldown)
- **Blow**: Reduce drain by 60% for 3s (10s cooldown)
- Cooldowns affected by relic bonuses

### Relics (Unlimited)
Passive effects that stack:
- **Cooling Pad**: -15% moisture drain
- **Speed Gloves**: -25% item cooldowns
- **Water Reservoir**: +20 starting moisture
- **Training Manual**: -30% difficulty scaling
- **Insulated Bowl**: -20% moisture drain
- **Quick Hands**: -40% item cooldowns
- **Moisture Lock**: -25% moisture drain
- **Chef's Guide**: -50% difficulty scaling

## Key Features

### Progressive Difficulty
- Base: 10% increase per round
- Modified by "difficulty scaling" relics
- Only affects drain rate (timer stays at 15s)
- Formula: `difficulty = 1.0 + (round - 1) * 0.1 * (1 - scaling_reduction)`

### Inventory Limits
- Ingredients: Unlimited
- Active Items: Maximum 3
- Relics: Unlimited

### Relic Effects Stack
Multiple relics of the same type combine:
- 2× Cooling Pad = -30% drain
- 2× Quick Hands = -80% cooldowns
- Effects calculated additively

## Technical Implementation

### New Files Created
1. `scripts/models/relic_model.gd` - Relic data structure
2. `scripts/data/relics.gd` - Relic pool singleton
3. `scripts/managers/inventory_manager.gd` - Player inventory tracking
4. `scripts/ui/draft_selector.gd` - Draft phase UI

### Modified Files
1. `scripts/main.gd` - Game flow with draft phases
2. `scripts/managers/moisture_manager.gd` - Relic effect integration
3. `scripts/managers/active_item_manager.gd` - Dynamic item system
4. `scripts/ui/ingredient_selector.gd` - Inventory-based selection
5. `scripts/ui/active_item_button_ui.gd` - Dynamic button updates
6. `scripts/singletons/event_bus.gd` - Added draft_completed signal
7. `scenes/main.tscn` - Added DraftSelector UI panel
8. `project.godot` - Added RelicsData autoload

## Strategy Tips
- Early game: Focus on ingredients to have variety
- Mid game: Add active items for moisture control
- Late game: Stack relics for powerful combos
- Drain reduction relics scale with difficulty
- Cooldown reduction enables more item usage
