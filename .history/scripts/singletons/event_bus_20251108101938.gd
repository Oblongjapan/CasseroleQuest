extends Node

## Centralized signal hub for loose coupling between game systems
## Use this autoload to communicate state changes across the game

# Round lifecycle signals
signal round_started(ingredient_1: IngredientModel, ingredient_2: IngredientModel)
signal round_completed(success: bool, final_moisture: float)

# Game state signals
signal moisture_changed(new_value: float)
signal timer_updated(time_remaining: float)
signal item_used(item_index: int)
signal item_cooldown_updated(item_index: int, cooldown_remaining: float)

# UI signals
signal ingredient_selected(ingredient: IngredientModel)
signal ingredient_deselected(ingredient: IngredientModel)
signal selection_confirmed(ingredient_1: IngredientModel, ingredient_2: IngredientModel)
