extends Node

## Main game controller - orchestrates the complete game flow

# Core managers
@onready var moisture_manager: MoistureManager = $CookRound/MoistureManager
@onready var timer_manager: TimerManager = $CookRound/TimerManager
@onready var item_manager: ActiveItemManager = $CookRound/ItemManager

# New managers for game flow
var game_state_manager: GameStateManager
var fridge_manager: FridgeManager
var currency_manager: CurrencyManager
var shop_manager: ShopManager
var inventory_manager: InventoryManager

# UI Screens
@onready var main_menu: Panel = $UI/MainMenu
@onready var hand_selector: Control = $UI/HandSelector
@onready var ingredient_selector: Panel = $UI/IngredientSelector
@onready var cooking_ui: Control = $UI/CookingUI
@onready var round_complete_screen: Panel = $UI/RoundCompleteScreen
@onready var round_failed_screen: Panel = $UI/RoundFailedScreen
@onready var shop_screen: Panel = $UI/ShopScreen

# UI Elements
@onready var status_label: Label = $UI/StatusLabel
@onready var item_button_1: Button = $UI/ActiveItemsContainer/ActiveItemButton_1
@onready var item_button_2: Button = $UI/ActiveItemsContainer/ActiveItemButton_2
@onready var item_button_3: Button = $UI/ActiveItemsContainer/ActiveItemButton_3

# Game state
var current_round_number: int = 1
var current_round_active: bool = false
var last_round_moisture: float = 0

func _ready():
	print("[Main] _ready() starting...")
	
	# Create managers
	game_state_manager = GameStateManager.new()
	add_child(game_state_manager)
	print("[Main] GameStateManager created")
	
	fridge_manager = FridgeManager.new()
	add_child(fridge_manager)
	print("[Main] FridgeManager created")
	
	currency_manager = CurrencyManager.new()
	add_child(currency_manager)
	print("[Main] CurrencyManager created")
	
	shop_manager = ShopManager.new()
	add_child(shop_manager)
	shop_manager.setup(fridge_manager, currency_manager, inventory_manager)
	print("[Main] ShopManager created")
	
	inventory_manager = InventoryManager.new()
	add_child(inventory_manager)
	print("[Main] InventoryManager created")
	
	# Connect signals
	EventBus.game_started.connect(_on_game_started)
	EventBus.round_started.connect(_on_round_started)
	EventBus.round_completed.connect(_on_round_completed)
	EventBus.shop_opened.connect(_on_shop_opened)
	EventBus.shop_closed.connect(_on_shop_closed)
	game_state_manager.state_changed.connect(_on_state_changed)
	print("[Main] All signals connected")
	
	# Connect hand selector signal
	if hand_selector:
		hand_selector.hand_selection_confirmed.connect(_on_hand_selected)
		print("[Main] HandSelector connected successfully")
	else:
		print("[Main] Warning: HandSelector node not found in scene tree!")
	
	# Connect round complete/failed screen signals
	if round_failed_screen:
		round_failed_screen.retry_requested.connect(_on_retry_requested)
		round_failed_screen.return_to_menu_requested.connect(_on_return_to_menu)
	
	# Auto-start game immediately (skip main menu)
	print("[Main] Auto-starting game...")
	_hide_all_ui()
	_on_game_started()
	print("[Main] _ready() complete")

func _process(delta: float) -> void:
	if not current_round_active:
		return
	
	# Update all systems during cooking
	moisture_manager.update_moisture(delta)
	timer_manager.update_timer(delta)
	item_manager.update_cooldowns(delta)
	
	# Check win/loss conditions
	if moisture_manager.check_failure():
		_end_round(false)
	elif timer_manager.check_complete():
		_end_round(true)

## STATE: MAIN_MENU
func _show_main_menu() -> void:
	print("[Main] _show_main_menu called")
	_hide_all_ui()
	if main_menu:
		print("[Main] Showing main_menu")
		main_menu.show()
	else:
		print("[Main] ERROR: main_menu is null!")
	game_state_manager.change_state(GameStateManager.GameState.MAIN_MENU)
	print("[Main] State changed to MAIN_MENU")

## STATE: FRIDGE_INIT (triggered by game_started signal)
func _on_game_started() -> void:
	print("[Main] ========================================")
	print("[Main] _on_game_started CALLED!")
	print("[Main] ========================================")
	print("[Main] Initializing fridge deck...")
	
	# Initialize all game systems
	fridge_manager.initialize_starting_deck()
	currency_manager.reset()
	current_round_number = 1
	
	print("[Main] About to call _show_hand_selector()...")
	# Show hand selector (draw 3 cards, pick 2)
	_show_hand_selector()
	print("[Main] _on_game_started complete")

## STATE: HAND_SELECTOR (first round only)
func _show_hand_selector() -> void:
	print("[Main] _show_hand_selector called")
	_hide_all_ui()
	print("[Main] All UI hidden")
	if hand_selector:
		print("[Main] hand_selector exists, calling show_hand_selection()")
		hand_selector.show_hand_selection(fridge_manager)
		status_label.text = "Starting Hand - Choose 2 ingredients"
		print("[Main] HandSelector should now be visible")
	else:
		# Fallback if hand_selector node doesn't exist
		print("[Main] ERROR: HandSelector node not found! Using fallback")
		status_label.text = "HandSelector missing - using fallback"
		# Draw 2 cards and go straight to cooking
		var cards = fridge_manager.draw_cards(2)
		if cards.size() >= 2:
			fridge_manager.discard_cards(cards)
			EventBus.round_started.emit(cards[0], cards[1])
		else:
			print("[Main] Error: Not enough cards to draw!")
			_show_main_menu()

## Handle hand selection
func _on_hand_selected(ing1: IngredientModel, ing2: IngredientModel, _discarded: IngredientModel) -> void:
	print("[Main] Hand selected: %s + %s" % [ing1.name, ing2.name])
	# Start cooking immediately with selected ingredients
	EventBus.round_started.emit(ing1, ing2)

## STATE: INGREDIENT_SELECTOR
func _show_ingredient_selector() -> void:
	_hide_all_ui()
	if ingredient_selector:
		ingredient_selector.show_selector(fridge_manager, currency_manager, current_round_number)
	status_label.text = "Round %d - Preview your ingredients" % current_round_number

## STATE: COOKING (triggered by round_started signal)
func _on_round_started(ingredient_1: IngredientModel, ingredient_2) -> void:
	current_round_active = true
	game_state_manager.change_state(GameStateManager.GameState.COOKING)
	
	_hide_all_ui()
	if cooking_ui:
		cooking_ui.show()
	status_label.text = "Round %d - Cooking..." % current_round_number
	
	# Initialize all managers
	moisture_manager.setup(ingredient_1, ingredient_2, 1.0, inventory_manager)
	timer_manager.start_timer(15.0)
	item_manager.setup(inventory_manager.get_active_items(), inventory_manager.get_total_cooldown_reduction())
	item_manager.reset_cooldowns()
	
	_update_item_buttons()
	
	# Change microwave background to "on"
	var on_tex = load("res://Assets/Microwave-ON.png")
	if on_tex and has_node("UI/Background"):
		get_node("UI/Background").texture = on_tex

## End the current round
func _end_round(success: bool) -> void:
	if not current_round_active:
		return  # Prevent double-ending
	
	current_round_active = false
	timer_manager.stop_timer()
	
	# Restore microwave background to "off"
	var off_tex = load("res://Assets/Microwave.png")
	if off_tex and has_node("UI/Background"):
		get_node("UI/Background").texture = off_tex
	
	var final_moisture = moisture_manager.current_moisture
	last_round_moisture = final_moisture
	
	EventBus.round_completed.emit(success, final_moisture)

func _on_round_completed(success: bool, final_moisture: float) -> void:
	if success:
		# Add moisture as currency
		currency_manager.add_currency(int(final_moisture))
		EventBus.round_success.emit(final_moisture)
		
		# Show round complete screen
		await get_tree().create_timer(1.0).timeout
		_show_round_complete(final_moisture)
	else:
		# Failed rounds also give 0 currency but still go to shop
		EventBus.round_failed.emit(final_moisture)
		
		# Show round failed screen briefly, then go to shop
		await get_tree().create_timer(1.5).timeout
		_show_shop_after_failure()

## STATE: ROUND_COMPLETE
func _show_round_complete(final_moisture: float) -> void:
	_hide_all_ui()
	if round_complete_screen:
		round_complete_screen.show_complete(final_moisture, currency_manager)

## Show shop after failure
func _show_shop_after_failure() -> void:
	# Go directly to shop (no success screen)
	EventBus.shop_opened.emit()

## STATE: ROUND_FAILED (no longer used - goes straight to shop)
func _show_round_failed(final_moisture: float) -> void:
	_hide_all_ui()
	if round_failed_screen:
		var time_remaining = timer_manager.time_remaining
		var max_moisture = moisture_manager.max_moisture
		round_failed_screen.show_failed(final_moisture, time_remaining, max_moisture)

## Handle retry from failed screen (no longer used)
func _on_retry_requested() -> void:
	# Go to shop instead
	EventBus.shop_opened.emit()

## Handle return to menu from failed screen
func _on_return_to_menu() -> void:
	# Reset everything
	current_round_number = 1
	currency_manager.reset()
	fridge_manager.initialize_starting_deck()
	inventory_manager.reset_inventory()
	_show_main_menu()

## STATE: SHOP
func _on_shop_opened() -> void:
	game_state_manager.change_state(GameStateManager.GameState.SHOP)
	_hide_all_ui()
	
	# Increment round number after completing a round
	current_round_number += 1
	
	# Refresh shop inventory
	shop_manager.refresh_shop(current_round_number - 1)
	
	# Show shop screen
	if shop_screen:
		shop_screen.show_shop(shop_manager, currency_manager, current_round_number - 1)

func _on_shop_closed() -> void:
	# Return to ingredient selector for next round
	_show_ingredient_selector()

## Handle state changes
func _on_state_changed(new_state: GameStateManager.GameState, _old_state: GameStateManager.GameState) -> void:
	match new_state:
		GameStateManager.GameState.MAIN_MENU:
			pass  # Already handled
		GameStateManager.GameState.FRIDGE_INIT:
			pass  # Handled by game_started signal
		GameStateManager.GameState.INGREDIENT_SELECTOR:
			_show_ingredient_selector()
		GameStateManager.GameState.COOKING:
			pass  # Handled by round_started signal
		GameStateManager.GameState.ROUND_COMPLETE:
			pass  # Handled by round_completed signal
		GameStateManager.GameState.ROUND_FAILED:
			pass  # Handled by round_completed signal
		GameStateManager.GameState.SHOP:
			pass  # Handled by shop_opened signal

## Hide all UI screens
func _hide_all_ui() -> void:
	if main_menu:
		main_menu.hide()
	if hand_selector:
		hand_selector.hide()
	if ingredient_selector:
		ingredient_selector.hide()
	if cooking_ui:
		cooking_ui.hide()
	if round_complete_screen:
		round_complete_screen.hide()
	if round_failed_screen:
		round_failed_screen.hide()
	if shop_screen:
		shop_screen.hide()

## Update item button UI
func _update_item_buttons() -> void:
	var owned_items = inventory_manager.get_active_items()
	var buttons = [item_button_1, item_button_2, item_button_3]
	
	for i in range(buttons.size()):
		if i < owned_items.size():
			buttons[i].set_item(owned_items[i], i)
			buttons[i].show()
		else:
			buttons[i].hide()

## Called from ActiveItemButtonUI when button pressed
func try_use_item(item_index: int) -> void:
	if current_round_active:
		item_manager.use_item(item_index, moisture_manager)
