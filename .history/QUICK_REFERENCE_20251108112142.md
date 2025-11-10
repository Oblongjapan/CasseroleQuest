# Quick Reference Guide

## File Locations Quick Reference

### Core Models
- `scripts/models/ingredient_model.gd` - Ingredient data with drain calculation
- `scripts/models/active_item.gd` - Active item data with effect application

### Managers (Game Logic)
- `scripts/managers/moisture_manager.gd` - Moisture tracking & drain
- `scripts/managers/timer_manager.gd` - Cook timer countdown
- `scripts/managers/active_item_manager.gd` - Item cooldowns & usage

### UI Controllers (Display Only)
- `scripts/ui/moisture_bar_ui.gd` - Moisture bar visual
- `scripts/ui/timer_display_ui.gd` - Timer display
- `scripts/ui/active_item_button_ui.gd` - Item button behavior
- `scripts/ui/ingredient_selector.gd` - Ingredient selection screen

### Data Files
- `scripts/data/ingredients.gd` - All ingredient definitions
- `scripts/data/active_items_data.gd` - All active item definitions

### Singletons (Autoloaded)
- `scripts/singletons/event_bus.gd` - Signal hub

### Main
- `scripts/main.gd` - Game controller, orchestrates everything
- `scenes/main.tscn` - Main scene with all UI nodes

## Common Tasks

### Adding a New Ingredient
1. Open `scripts/data/ingredients.gd`
2. Add new entry to INGREDIENTS dict:
```gdscript
"new_food": {
    "name": "New Food",
    "water_content": 50,
    "heat_resistance": 50,
    "density": 50,
    "spice_level": 50
}
```

### Adjusting Drain Rate Formula
Edit `calculate_drain_rate()` in `scripts/models/ingredient_model.gd`

### Changing Active Item Effects
Edit `apply_effect()` in `scripts/models/active_item.gd`

### Adjusting Timer Duration
In `scripts/main.gd`, find `_on_round_started()`:
```gdscript
timer_manager.start_timer(15.0)  # Change 15.0 to desired seconds
```

### Adding New Signals
1. Add to `scripts/singletons/event_bus.gd`
2. Emit from managers
3. Connect in UI controllers

## Signal Flow Examples

### Moisture Updates
```
MoistureManager.update_moisture()
  → EventBus.moisture_changed.emit()
    → MoistureBarUI._on_moisture_changed()
      → Update bar visual
```

### Item Usage
```
ActiveItemButton pressed
  → Main.try_use_item()
    → ActiveItemManager.use_item()
      → ActiveItem.apply_effect()
        → MoistureManager.restore_moisture() or apply_drain_modifier()
      → EventBus.item_used.emit()
        → ActiveItemButtonUI._on_item_used()
          → Start cooldown visual
```

### Round Start
```
IngredientSelector: Start button pressed
  → EventBus.round_started.emit()
    → Main._on_round_started()
      → MoistureManager.setup()
      → TimerManager.start_timer()
      → ActiveItemManager.reset_cooldowns()
```

## Key Variables to Tweak

### Balance
- `MoistureManager.max_moisture = 100.0` - Starting moisture
- `ActiveItem.cooldown_duration` - How long items take to recharge
- Item effect values in `ActiveItem.apply_effect()`
- Drain formula coefficients in `IngredientModel.calculate_drain_rate()`

### Visuals
- `MoistureBarUI` color thresholds (60, 30)
- `TimerDisplayUI` red flash threshold (5.0 seconds)
- Button sizes in `main.tscn`

## Debugging Tips

### Check Current Drain Rate
Add to `MoistureManager._process()`:
```gdscript
print("Drain rate: ", base_drain_rate + sum_of_modifiers)
```

### Check Ingredient Stats
Add to `Main._on_round_started()`:
```gdscript
print("Ingredient 1 drain: ", ingredient_1.calculate_drain_rate())
print("Ingredient 2 drain: ", ingredient_2.calculate_drain_rate())
```

### Check Item Usage
In `ActiveItemManager.use_item()`:
```gdscript
print("Item %d used, cooldown: %f" % [item_index, cooldowns[item_index]])
```

## Testing Checklist

- [ ] Select 2 ingredients and press Start
- [ ] Timer counts down from 15 seconds
- [ ] Moisture bar drains over time
- [ ] Cover button reduces drain (green indicator)
- [ ] Stir button restores moisture (bar jumps up)
- [ ] Blow button reduces drain (green indicator)
- [ ] Items show cooldown timer after use
- [ ] Moisture = 0 triggers failure
- [ ] Timer = 0 with moisture > 0 triggers success
- [ ] Can restart after round ends

## Performance Notes

- All calculations happen in `_process(delta)` when `current_round_active = true`
- Signal emissions are lightweight
- No physics calculations needed
- 60 FPS target easily achievable

## Architecture Diagram

```
Main (Orchestrator)
 ├─ CookRound
 │   ├─ MoistureManager ──signals──> EventBus
 │   ├─ TimerManager ──signals──> EventBus
 │   └─ ItemManager ──signals──> EventBus
 └─ UI (CanvasLayer)
     ├─ MoistureBar ──listens──> EventBus
     ├─ TimerDisplay ──listens──> EventBus
     ├─ ActiveItemButtons ──listens──> EventBus
     └─ IngredientSelector ──signals──> EventBus

Autoloads (Global Access):
 ├─ EventBus (signals)
 ├─ IngredientsData (ingredient pool)
 └─ ActiveItemsData (item definitions)
```
