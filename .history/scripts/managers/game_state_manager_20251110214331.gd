extends Node
class_name GameStateManager

## Manages game state transitions and flow

enum GameState {
	MAIN_MENU,
	FRIDGE_INIT,
	INGREDIENT_SELECTOR,
	COOKING,
	ROUND_COMPLETE,
	ROUND_FAILED,
	SHOP
}

var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.MAIN_MENU

signal state_changed(new_state: GameState, old_state: GameState)

func _ready():
	# Connect to relevant signals
	EventBus.game_started.connect(_on_game_started)
	EventBus.round_started.connect(_on_round_started)
	EventBus.round_completed.connect(_on_round_completed)
	EventBus.shop_closed.connect(_on_shop_closed)

## Transition to a new state
func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	
	previous_state = current_state
	current_state = new_state
	print("[GameStateManager] State: %s → %s" % [_state_name(previous_state), _state_name(new_state)])
	state_changed.emit(new_state, previous_state)

## Get current state
func get_current_state() -> GameState:
	return current_state

## State transition handlers
func _on_game_started() -> void:
	change_state(GameState.FRIDGE_INIT)

func _on_round_started(_ing1, _ing2) -> void:
	change_state(GameState.COOKING)

func _on_round_completed(success: bool, _final_moisture: float) -> void:
	if success:
		change_state(GameState.ROUND_COMPLETE)
	else:
		change_state(GameState.ROUND_FAILED)

func _on_shop_closed() -> void:
	change_state(GameState.INGREDIENT_SELECTOR)

## Helper to get state name for debugging
func _state_name(state: GameState) -> String:
	match state:
		GameState.MAIN_MENU: return "MAIN_MENU"
		GameState.FRIDGE_INIT: return "FRIDGE_INIT"
		GameState.INGREDIENT_SELECTOR: return "INGREDIENT_SELECTOR"
		GameState.COOKING: return "COOKING"
		GameState.ROUND_COMPLETE: return "ROUND_COMPLETE"
		GameState.ROUND_FAILED: return "ROUND_FAILED"
		GameState.SHOP: return "SHOP"
		_: return "UNKNOWN"
