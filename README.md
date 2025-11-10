# Microwave Moisture Roguelike

A fast-paced roguelike game where you manage moisture levels while microwaving food combinations!

## Game Concept

Select 2 ingredients and cook them in the microwave for 15 seconds. Keep the moisture above 0 by using active items strategically. Each ingredient has unique stats that affect how fast moisture drains.

## Project Structure

```
Microwavr/
├── scenes/
│   └── main.tscn                    # Main game scene
├── scripts/
│   ├── main.gd                      # Main game controller
│   ├── models/
│   │   ├── ingredient_model.gd      # Ingredient data structure
│   │   └── active_item.gd           # Active item data structure
│   ├── managers/
│   │   ├── moisture_manager.gd      # Moisture drain calculation
│   │   ├── timer_manager.gd         # Cook timer management
│   │   └── active_item_manager.gd   # Item cooldown management
│   ├── ui/
│   │   ├── moisture_bar_ui.gd       # Moisture bar display
│   │   ├── timer_display_ui.gd      # Timer display
│   │   ├── active_item_button_ui.gd # Active item buttons
│   │   └── ingredient_selector.gd   # Ingredient selection screen
│   ├── data/
│   │   ├── ingredients.gd           # Ingredient pool data
│   │   └── active_items_data.gd     # Active item definitions
│   └── singletons/
│       └── event_bus.gd             # Signal hub (autoload)
├── project.godot                     # Godot project configuration
└── icon.svg                          # Project icon
```

## How to Run

1. Open Godot 4.x
2. Import this project (File → Import Project)
3. Open `project.godot`
4. Press F5 to run the game

## Gameplay

### Win Condition
Keep moisture above 0 when the 15-second timer completes

### Loss Condition
Moisture reaches 0 before timer completes

### Ingredients
Each ingredient has 4 stats:
- **Water Content**: Base moisture in food
- **Heat Resistance**: Resists drying
- **Density**: Holds moisture better
- **Spice Level**: Increases drain rate

**Drain Formula**: `(Spice × 0.5) - (Heat Resistance × 0.3) - (Density × 0.2)`

### Active Items
- **Cover** (8s cooldown): Reduce drain by 40% for 5 seconds
- **Stir** (6s cooldown): Restore 20 moisture instantly
- **Blow** (10s cooldown): Reduce drain by 60% for 3 seconds

## Available Ingredients

1. **Chicken Breast**: Balanced stats
2. **Lettuce**: High water, low resistance (dries fast!)
3. **Rice**: Low water, high resistance (stable)
4. **Broccoli**: High water, moderate stats
5. **Salmon**: Balanced, good for combos
6. **Potato**: High stats all around (easy mode)
7. **Bread**: Dry, moderate resistance
8. **Spinach**: High water, low resistance

## Code Architecture

### Signal-Based Communication
All systems communicate through `EventBus` (autoload):
- Loose coupling between managers and UI
- Easy to extend with new features
- Clear data flow

### Manager Pattern
- **MoistureManager**: Game logic for moisture
- **TimerManager**: Game logic for timer
- **ActiveItemManager**: Game logic for items

### UI Controllers
- Listen to EventBus signals
- Update visual display only
- Send button presses to Main

## Testing Strategies

1. **High Drain Test**: Lettuce + Broccoli (should fail ~8-10s without items)
2. **Low Drain Test**: Rice + Potato (should succeed easily)
3. **Item Test**: Use each item and verify effects
4. **Cooldown Test**: Spam buttons to verify cooldown works
5. **Edge Cases**: Moisture = 0 exactly, Timer = 0 with moisture

## Next Steps

- [ ] Add sound effects (microwave beep, ding)
- [ ] Add particle effects for moisture drain
- [ ] Add win/loss screen with stats
- [ ] Balance ingredient stats
- [ ] Add more ingredients
- [ ] Add difficulty scaling (shorter timers, more ingredients)

## Development Conventions

See the main design document for detailed conventions:
- Use `snake_case` for files and variables
- Use `PascalCase` for classes and nodes
- Use `UPPER_SNAKE_CASE` for constants
- Use signals for state changes
- Keep functions under 30 lines
- Add docstrings for complex logic

## License

Game Jam Project - 1 Month Development Cycle
