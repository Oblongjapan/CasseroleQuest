extends Node

## Centralized signal hub for loose coupling between game systems
## Use this autoload to communicate state changes across the game

# Game lifecycle signals
signal game_started()
signal game_over()

# Round lifecycle signals
signal round_started(ingredient_1: IngredientModel, ingredient_2)
signal round_completed(success: bool, final_moisture: float)
signal round_success(moisture_earned: float)
signal round_failed(final_moisture: float)
signal draft_completed()

# Shop signals
signal shop_opened()
signal shop_closed()
signal shop_refreshed(inventory: Array)
signal item_purchased(item: Dictionary)

# Game state signals
signal moisture_changed(current: float, max_value: float, bonus: float)
signal timer_updated(time_remaining: float)
signal item_used(item_index: int)
signal item_cooldown_updated(item_index: int, cooldown_remaining: float)
signal currency_changed(amount: int)
signal deck_changed(cards_in_deck: int, total_cards: int)

# UI signals
signal ingredient_selected(ingredient: IngredientModel)
signal ingredient_deselected(ingredient: IngredientModel)
signal selection_confirmed(ingredient_1: IngredientModel, ingredient_2)
