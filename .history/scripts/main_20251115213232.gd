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
var malfunction_manager: MalfunctionManager
var round_modifier_manager: RoundModifierManager

# UI Screens
@onready var main_menu: Panel = $UI/MainMenu
@onready var hand_selector: Control = $UI/HandSelector
@onready var ingredient_selector: Panel = $UI/IngredientSelector
@onready var cooking_ui: Control = $UI/CookingUI
@onready var round_complete_screen: Panel = $UI/RoundCompleteScreen
@onready var round_failed_screen: Panel = $UI/RoundFailedScreen
@onready var shop_screen: Panel = $UI/ShopScreen
@onready var game_over_screen: Panel = $UI/GameOverScreen

# Malfunction UI (will be added to scene)
var malfunction_popup: Control = null
var malfunction_relic_reward: Panel = null
var malfunction_macrowave_reward: Panel = null

# UI Elements
@onready var status_label: Label = $UI/StatusLabel
@onready var moisture_background: ColorRect = $UI/Moisturebackground
@onready var moisture_label: Label = $UI/MoistureBar/MoistureLabel
@onready var item_button_1: TextureButton = $UI/Background/Microwave/ActiveItemsContainer/ActiveItemButton_1
@onready var item_button_2: Button = $UI/Background/Microwave/ActiveItemsContainer/ActiveItemButton_2
@onready var item_button_3: Button = $UI/Background/Microwave/ActiveItemsContainer/ActiveItemButton_3
@onready var deck_tracker: Label = $UI/DeckTracker
@onready var currency_label: Label = $UI/CurrencyLabel
@onready var relic_display: HBoxContainer = $UI/RelicDisplay
@onready var microwave_sprite: AnimatedSprite2D = $UI/Background/Microwave
@onready var on_button: Button = $UI/Background/Microwave/ONButton
@onready var power_lvl_label: Label = $UI/Background/Microwave/PowerLVL/PowerLvl
@onready var ingredient_overlay_1: Sprite2D = $UI/Background/Microwave/IngredientOverlay1
@onready var ingredient_overlay_2: Sprite2D = $UI/Background/Microwave/IngredientOverlay2
@onready var round_modifier_label: Label = $UI/RoundModifierLabel

# Game state
var current_round_number: int = 1
var rounds_in_current_chunk: int = 0  # Track rounds in current 3-round chunk (0, 1, or 2)
var current_round_active: bool = false
var last_round_moisture: float = 0
var game_speed: float = 3.0  # Default to 3x speed
var current_malfunction: MalfunctionModel = null
var is_malfunction_round: bool = false
var malfunction_animation_tween: Tween = null  # Track special animations

func _ready():
	print("[Main] _ready() starting...")
	
	# Create managers in correct order
	game_state_manager = GameStateManager.new()
	add_child(game_state_manager)
	print("[Main] GameStateManager created")
	
	fridge_manager = FridgeManager.new()
	add_child(fridge_manager)
	print("[Main] FridgeManager created")
	
	currency_manager = CurrencyManager.new()
	add_child(currency_manager)
	print("[Main] CurrencyManager created")
	
	inventory_manager = InventoryManager.new()
	add_child(inventory_manager)
	print("[Main] InventoryManager created")
	
	shop_manager = ShopManager.new()
	add_child(shop_manager)
	shop_manager.setup(fridge_manager, currency_manager, inventory_manager)
	print("[Main] ShopManager created")
	
	malfunction_manager = MalfunctionManager.new()
	add_child(malfunction_manager)
	print("[Main] MalfunctionManager created")
	
	round_modifier_manager = RoundModifierManager.new()
	add_child(round_modifier_manager)
	print("[Main] RoundModifierManager created")
	
	shop_manager = ShopManager.new()
	add_child(shop_manager)
	shop_manager.setup(fridge_manager, currency_manager, inventory_manager, round_modifier_manager)
	print("[Main] ShopManager created")
	
	malfunction_manager = MalfunctionManager.new()
	add_child(malfunction_manager)
	print("[Main] MalfunctionManager created")
	
	# Connect signals
	EventBus.game_started.connect(_on_game_started)
	EventBus.round_started.connect(_on_round_started)
	EventBus.round_completed.connect(_on_round_completed)
	EventBus.shop_opened.connect(_on_shop_opened)
	EventBus.shop_closed.connect(_on_shop_closed)
	game_state_manager.state_changed.connect(_on_state_changed)
	
	# Connect currency changes
	if currency_manager:
		currency_manager.currency_changed.connect(_update_currency_display)
	
	# Connect inventory changes
	if inventory_manager:
		inventory_manager.inventory_updated.connect(_update_item_buttons)
	
	print("[Main] All signals connected")
	
	# Connect game over screen
	if game_over_screen:
		game_over_screen.restart_requested.connect(_on_restart_requested)
		game_over_screen.quit_requested.connect(_on_quit_requested)
		print("[Main] Game over screen connected")
	else:
		print("[Main] WARNING: game_over_screen is null! Check if GameOverScreen node exists in main.tscn")
	
	# Connect hand selector signal
	if hand_selector:
		hand_selector.hand_selection_confirmed.connect(_on_hand_selected)
		hand_selector.ingredient_selected.connect(_on_ingredient_selected)
		hand_selector.ingredient_deselected.connect(_on_ingredient_deselected)
		# Listen for selection_ready to show/hide the microwave ON button
		if hand_selector.has_signal("selection_ready"):
			hand_selector.selection_ready.connect(_on_selection_ready)
			# Start button should be hidden by default until selection is ready
			if on_button:
				on_button.hide()
		print("[Main] HandSelector connected successfully")
	else:
		print("[Main] Warning: HandSelector node not found in scene tree!")

	# The START/ON button is now owned by the HandSelector scene and
	# is shown/hidden and handled inside that scene. No local ON button
	# hookup is required here anymore.
	
	# Connect round complete/failed screen signals
	if round_complete_screen:
		round_complete_screen.continue_requested.connect(_check_map_progress)
	
	if round_failed_screen:
		round_failed_screen.retry_requested.connect(_on_retry_requested)
		round_failed_screen.return_to_menu_requested.connect(_on_return_to_menu)
	
	# Set game speed to 3x by default
	Engine.time_scale = game_speed
	print("[Main] Game speed set to: %.1fx" % game_speed)
	
	# Setup deck tracker
	if deck_tracker:
		deck_tracker.setup(fridge_manager)
		print("[Main] Deck tracker connected")
	else:
		print("[Main] Warning: Deck tracker not found")
	
	# Setup relic display
	if relic_display:
		relic_display.setup(inventory_manager)
		print("[Main] Relic display connected")
	else:
		print("[Main] Warning: Relic display not found")
	
	# Connect ingredient overlay signals
	if ingredient_overlay_1:
		ingredient_overlay_1.drag_out_requested.connect(_on_overlay_drag_out)
	if ingredient_overlay_2:
		ingredient_overlay_2.drag_out_requested.connect(_on_overlay_drag_out)
	
	# Try to find malfunction UI nodes (optional - will be null if not in scene)
	malfunction_popup = get_node_or_null("UI/MalfunctionPopup")
	malfunction_relic_reward = get_node_or_null("UI/MalfunctionRelicReward")
	malfunction_macrowave_reward = get_node_or_null("UI/MalfunctionMacrowaveReward")
	
	if malfunction_popup:
		print("[Main] Malfunction popup UI found")
	else:
		print("[Main] Warning: Malfunction popup UI not found - add UI/MalfunctionPopup node")
	
	if malfunction_relic_reward:
		print("[Main] Malfunction relic reward UI found")
	else:
		print("[Main] Warning: Malfunction relic reward UI not found - add UI/MalfunctionRelicReward node")
	
	if malfunction_macrowave_reward:
		print("[Main] Malfunction macrowave reward UI found")
	else:
		print("[Main] Warning: Malfunction macrowave reward UI not found - add UI/MalfunctionMacrowaveReward node")
	
	# Auto-start game immediately (skip main menu)
	print("[Main] Auto-starting game...")
	_hide_all_ui()
	_on_game_started()
	print("[Main] _ready() complete")

func _process(delta: float) -> void:
	# Debug: Press M to trigger malfunction
	if Input.is_action_just_pressed("ui_page_down") or Input.is_key_pressed(KEY_M):
		_debug_trigger_malfunction()
	
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

## Debug function to trigger malfunction for testing
func _debug_trigger_malfunction() -> void:
	# Only trigger if not already in a malfunction
	if is_malfunction_round:
		print("[Main] DEBUG: Already in malfunction round, ignoring")
		return
	
	# Trigger a random malfunction
	current_malfunction = MalfunctionsData.get_random_malfunction()
	is_malfunction_round = true
	print("[Main] DEBUG: Manually triggered malfunction: %s" % current_malfunction.name)
	
	# Show popup
	if malfunction_popup:
		malfunction_popup.show_malfunction(current_malfunction)
	
	# Apply effects if currently cooking
	if current_round_active:
		print("[Main] DEBUG: Applying malfunction effects mid-round")
		match current_malfunction.type:
			MalfunctionModel.MalfunctionType.OVERHEAT:
				moisture_manager.set_malfunction_multiplier(1.5)
				print("[Main] DEBUG: OVERHEAT applied - 1.5x drain")
			
			MalfunctionModel.MalfunctionType.BULB_OUT:
				moisture_manager.set_malfunction_multiplier(0.5)
				print("[Main] DEBUG: BULB OUT applied - 0.5x drain")
			
			MalfunctionModel.MalfunctionType.MACROWAVE:
				# Can't change timer mid-round, but can reset drain
				moisture_manager.reset_malfunction_multiplier()
				print("[Main] DEBUG: MACROWAVE (timer change only works on round start)")

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

func _update_power_level_display() -> void:
	if power_lvl_label:
		power_lvl_label.text = "PWR %d" % current_round_number

func _update_currency_display(new_amount: int) -> void:
	if currency_label:
		currency_label.text = "Currency: %d" % new_amount

func _update_ingredient_overlays(ingredient_1: IngredientModel, ingredient_2) -> void:
	# Load and show first ingredient
	if ingredient_overlay_1 and ingredient_1:
		# Strip "Organic " prefix to get base ingredient name for texture
		var base_name = ingredient_1.name.replace("Organic ", "")
		var texture_path = "res://Assets/Food/%s.png" % base_name
		var texture = load(texture_path)
		if texture:
			ingredient_overlay_1.texture = texture
			ingredient_overlay_1.show()
			print("[Main] Showing ingredient overlay 1: %s" % ingredient_1.name)
		else:
			print("[Main] WARNING: Could not load texture for ingredient 1: %s" % texture_path)
	
	# Load and show second ingredient if different from first
	if ingredient_overlay_2 and ingredient_2 and ingredient_2 != ingredient_1:
		# Strip "Organic " prefix to get base ingredient name for texture
		var base_name = ingredient_2.name.replace("Organic ", "")
		var texture_path = "res://Assets/Food/%s.png" % base_name
		var texture = load(texture_path)
		if texture:
			ingredient_overlay_2.texture = texture
			ingredient_overlay_2.show()
			print("[Main] Showing ingredient overlay 2: %s" % ingredient_2.name)
		else:
			print("[Main] WARNING: Could not load texture for ingredient 2: %s" % texture_path)
	else:
		# Hide second overlay if cooking solo
		if ingredient_overlay_2:
			ingredient_overlay_2.hide()

func _hide_ingredient_overlays() -> void:
	if ingredient_overlay_1:
		ingredient_overlay_1.hide()
	if ingredient_overlay_2:
		ingredient_overlay_2.hide()

## STATE: FRIDGE_INIT (triggered by game_started signal)
func _on_game_started() -> void:
	print("[Main] ========================================")
	print("[Main] _on_game_started CALLED!")
	print("[Main] ========================================")
	print("[Main] Initializing fridge deck...")
	
	# Initialize all game systems
	fridge_manager.initialize_starting_deck()
	currency_manager.reset()
	inventory_manager.reset_inventory()
	current_round_number = 1
	_update_power_level_display()
	_update_currency_display(currency_manager.get_currency())
	
	# Give player one starter active item to help with difficult situations
	print("[Main] Adding starter active item: Stir")
	var starter_item = ActiveItem.new(ActiveItem.Type.STIR, "Stir", "Add water, restore 20 moisture", 6.0)
	inventory_manager.add_active_item(starter_item)
	_update_item_buttons()
	
	# Show hand selector (draw 3 cards, pick 2) - start game directly
	_show_hand_selector()
	print("[Main] _on_game_started complete")

## STATE: HAND_SELECTOR (first round only)
func _show_hand_selector() -> void:
	print("[Main] _show_hand_selector called")
	
	# Select a new round modifier
	var modifier = round_modifier_manager.select_new_modifier()
	if round_modifier_label:
		round_modifier_label.set_modifier(modifier)
		print("[Main] Round modifier set: %s" % modifier.name)
	
	# Check if malfunction should trigger this round BEFORE showing hand
	is_malfunction_round = false
	current_malfunction = null
	
	if malfunction_manager.should_trigger_malfunction():
		current_malfunction = malfunction_manager.trigger_malfunction()
		is_malfunction_round = true
		print("[Main] MALFUNCTION TRIGGERED: %s" % current_malfunction.name)
		
		# Show malfunction popup if available
		if malfunction_popup:
			malfunction_popup.show_malfunction(current_malfunction)
			await malfunction_popup.popup_completed
		else:
			# If popup not available, just wait a moment
			print("[Main] Warning: malfunction_popup not found, skipping animation")
			await get_tree().create_timer(2.0).timeout
	
	_hide_all_ui()
	print("[Main] All UI hidden")
	
	# Play microwave Idle animation when choosing ingredients
	if microwave_sprite:
		microwave_sprite.play("Idle")
	
	# Show moisture background and reset display to 0/0
	if moisture_background:
		moisture_background.show()
	_update_moisture_display()
	
	if hand_selector:
		print("[Main] hand_selector exists, calling show_hand_selection()")
		hand_selector.show_hand_selection(fridge_manager, game_state_manager)
		status_label.text = "Round %d - Choose 1-2 ingredients" % current_round_number
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

## Update moisture display based on ingredients in microwave
func _update_moisture_display() -> void:
	var total_moisture = 0
	var max_moisture = 0
	
	# Check both overlays for ingredients
	if ingredient_overlay_1 and ingredient_overlay_1.current_ingredient_name != "":
		# Find the ingredient by name
		var ing1 = _find_ingredient_by_name(ingredient_overlay_1.current_ingredient_name)
		if ing1:
			total_moisture += ing1.water_content
			max_moisture += ing1.water_content  # Max is the ingredient's actual water content
	
	if ingredient_overlay_2 and ingredient_overlay_2.current_ingredient_name != "":
		var ing2 = _find_ingredient_by_name(ingredient_overlay_2.current_ingredient_name)
		if ing2:
			total_moisture += ing2.water_content
			max_moisture += ing2.water_content
	
	# Update label
	if moisture_label:
		moisture_label.text = "%d/%d" % [total_moisture, max_moisture]
		print("[Main] Updated moisture display: %d/%d" % [total_moisture, max_moisture])

## Find ingredient model by name from hand selector
func _find_ingredient_by_name(ingredient_name: String) -> IngredientModel:
	if hand_selector and hand_selector.selected_ingredients:
		var selected = hand_selector.selected_ingredients
		for ing in selected:
			if ing.name == ingredient_name:
				return ing
	return null

## Handle selection ready state (enable/disable ON button)
## Handle ingredient selection/deselection from hand
func _on_ingredient_selected(ingredient: IngredientModel, overlay_index: int) -> void:
	print("[Main] Ingredient selected: %s for overlay slot %d" % [ingredient.name, overlay_index])
	var overlay = ingredient_overlay_1 if overlay_index == 0 else ingredient_overlay_2
	if overlay:
		var texture_path = "res://Assets/Food/%s.png" % ingredient.name
		var texture = load(texture_path)
		if texture:
			overlay.set_ingredient(ingredient.name, texture)
			print("[Main] Showing ingredient overlay %d: %s" % [overlay_index + 1, ingredient.name])
	
	# Update moisture display
	_update_moisture_display()

func _on_ingredient_deselected(overlay_index: int) -> void:
	print("[Main] Ingredient deselected from overlay slot %d" % overlay_index)
	var overlay = ingredient_overlay_1 if overlay_index == 0 else ingredient_overlay_2
	if overlay:
		overlay.clear_overlay()
	
	# Update moisture display
	_update_moisture_display()

func _on_overlay_drag_out(ingredient_name: String) -> void:
	print("[Main] Overlay dragged out - deselecting ingredient: %s" % ingredient_name)
	
	# Find which overlay has this ingredient and clear it
	if ingredient_overlay_1 and ingredient_overlay_1.current_ingredient_name == ingredient_name:
		ingredient_overlay_1.clear_overlay()
	elif ingredient_overlay_2 and ingredient_overlay_2.current_ingredient_name == ingredient_name:
		ingredient_overlay_2.clear_overlay()
	
	# Tell hand selector to deselect this ingredient by name
	if hand_selector and hand_selector.visible:
		hand_selector.deselect_by_ingredient_name(ingredient_name)
	
	# Update moisture display
	_update_moisture_display()

## Handle hand selection
func _on_hand_selected(ing1: IngredientModel, ing2: IngredientModel, _discarded: IngredientModel) -> void:
	print("[Main] Hand selected: %s + %s" % [ing1.name, ing2.name])
	# Start cooking immediately with selected ingredients
	EventBus.round_started.emit(ing1, ing2)

## Called when hand selector emits selection_ready(can_start)
func _on_selection_ready(can_start: bool) -> void:
	print("[Main] _on_selection_ready called with can_start: %s" % can_start)
	if on_button:
		if can_start:
			on_button.show()
		else:
			on_button.hide()

## STATE: INGREDIENT_SELECTOR
func _show_ingredient_selector() -> void:
	_hide_all_ui()
	if ingredient_selector:
		ingredient_selector.show_selector(fridge_manager, currency_manager, current_round_number)
	status_label.text = "Round %d - Preview your ingredients" % current_round_number

## STATE: COOKING (triggered by round_started signal)
func _on_round_started(ingredient_1: IngredientModel, ingredient_2) -> void:
	print("[Main] _on_round_started called with ingredients:")
	print("[Main]   - Ingredient 1: %s" % ingredient_1.name)
	if ingredient_2 and ingredient_2 != ingredient_1:
		print("[Main]   - Ingredient 2: %s" % ingredient_2.name)
	else:
		print("[Main]   - Ingredient 2: (same as 1 - solo cooking)")
	
	# Clear malfunction popup when cooking starts
	if malfunction_popup and is_malfunction_round:
		malfunction_popup.reset_popup()
	
	# Malfunction check already happened in _show_hand_selector
	# is_malfunction_round and current_malfunction are already set
	
	current_round_active = true
	print("[Main] Set current_round_active = true")
	game_state_manager.change_state(GameStateManager.GameState.COOKING)
	
	_hide_all_ui()
	if cooking_ui:
		cooking_ui.show()
	# Show moisture background during cooking
	if moisture_background:
		moisture_background.show()
	status_label.text = "Round %d - Cooking..." % current_round_number
	
	# Initialize all managers
	print("[Main] Initializing moisture_manager...")
	moisture_manager.setup(ingredient_1, ingredient_2, 1.0, inventory_manager)
	
	# The setup() function already emits moisture_changed signal which updates the bar
	print("[Main] Moisture initialized: %.1f/%.1f" % [moisture_manager.current_moisture, moisture_manager.max_moisture])
	
	# Apply round modifier effects
	if round_modifier_manager and round_modifier_manager.get_current_modifier():
		var modifier = round_modifier_manager.get_current_modifier()
		print("[Main] Applying round modifier: %s" % modifier.name)
		
		# Apply moisture bonus/penalty
		if modifier.modifier_type == RoundModifierModel.ModifierType.MOISTURE_BONUS:
			moisture_manager.current_moisture += modifier.value
			moisture_manager.current_moisture = max(0.0, moisture_manager.current_moisture)
			print("[Main] Applied moisture modifier: %+.1f (new: %.1f)" % [modifier.value, moisture_manager.current_moisture])
		
		# Apply drain multiplier
		elif modifier.modifier_type == RoundModifierModel.ModifierType.DRAIN_MULTIPLIER:
			moisture_manager.base_drain_rate *= modifier.value
			moisture_manager.microwave_drain *= modifier.value
			moisture_manager.ingredient_drain *= modifier.value
			print("[Main] Applied drain multiplier: %.2fx (new drain: %.2f)" % [modifier.value, moisture_manager.base_drain_rate])
		
		# Apply volatility change (harder to do retroactively, but can adjust drain)
		elif modifier.modifier_type == RoundModifierModel.ModifierType.VOLATILITY_CHANGE:
			var volatility_drain_change = modifier.value * 0.4  # Same formula as setup
			moisture_manager.ingredient_drain += volatility_drain_change
			moisture_manager.base_drain_rate += volatility_drain_change
			print("[Main] Applied volatility change: %+.1f (added %.2f drain)" % [modifier.value, volatility_drain_change])
	
	# Apply malfunction effects if this is a malfunction round
	if is_malfunction_round and current_malfunction:
		print("[Main] Applying malfunction effects: %s" % current_malfunction.name)
		match current_malfunction.type:
			MalfunctionModel.MalfunctionType.OVERHEAT:
				# 1.5x base drain rate
				moisture_manager.set_malfunction_multiplier(1.5)
				var base_timer = round_modifier_manager.apply_timer_modifier(15.0)
				timer_manager.start_timer(base_timer)
				print("[Main] OVERHEAT: Drain rate 1.5x, Timer: %.1fs" % base_timer)
			
			MalfunctionModel.MalfunctionType.BULB_OUT:
				# 0.5x drain rate
				moisture_manager.set_malfunction_multiplier(0.5)
				var base_timer = round_modifier_manager.apply_timer_modifier(15.0)
				timer_manager.start_timer(base_timer)
				print("[Main] BULB OUT: Drain rate 0.5x, Timer: %.1fs" % base_timer)
			
			MalfunctionModel.MalfunctionType.MACROWAVE:
				# 1 second per card in total deck
				var total_cards = fridge_manager.get_total_deck_size()
				timer_manager.start_macrowave_timer(total_cards)
				moisture_manager.reset_malfunction_multiplier()
				print("[Main] MACROWAVE: Timer set to %d seconds (total deck size)" % total_cards)
	else:
		# Normal timer with round modifier
		var base_timer = round_modifier_manager.apply_timer_modifier(15.0)
		timer_manager.start_timer(base_timer)
		moisture_manager.reset_malfunction_multiplier()
		print("[Main] Normal timer: %.1fs" % base_timer)
	
	item_manager.setup(inventory_manager.get_active_items(), inventory_manager.get_total_cooldown_reduction())
	item_manager.reset_cooldowns()
	
	_update_item_buttons()
	
	# Play microwave animation based on malfunction type
	if microwave_sprite:
		if is_malfunction_round and current_malfunction:
			match current_malfunction.type:
				MalfunctionModel.MalfunctionType.BULB_OUT:
					# Keep microwave Idle (no animation during Bulb Out)
					microwave_sprite.play("Idle")
					print("[Main] BULB OUT: Microwave stays Idle")
				
				MalfunctionModel.MalfunctionType.OVERHEAT:
					# Play On animation with red throbbing effect
					microwave_sprite.play("On")
					_start_overheat_animation()
					print("[Main] OVERHEAT: Red throbbing animation started")
				
				MalfunctionModel.MalfunctionType.MACROWAVE:
					# Play On animation with wave undulation
					microwave_sprite.play("On")
					_start_macrowave_animation()
					print("[Main] MACROWAVE: Wave undulation started")
		else:
			# Normal animation
			microwave_sprite.play("On")
	
	# Show ingredient overlays
	_update_ingredient_overlays(ingredient_1, ingredient_2)
	
	print("[Main] Round started - current_round_active: %s" % current_round_active)

## End the current round
func _end_round(success: bool) -> void:
	if not current_round_active:
		return  # Prevent double-ending
	
	current_round_active = false
	timer_manager.stop_timer()
	
	# Stop any malfunction animations
	_stop_malfunction_animations()
	
	# Hide ingredient overlays
	_hide_ingredient_overlays()
	
	# Reset malfunction popup if it was visible
	if malfunction_popup and is_malfunction_round:
		malfunction_popup.reset_popup()
	
	# Play microwave Idle animation
	if microwave_sprite:
		microwave_sprite.play("Idle")
	
	var final_moisture = moisture_manager.current_moisture
	last_round_moisture = final_moisture
	
	# Check if it's game over (moisture reached 0)
	# EXCEPTION: Don't game over during malfunction rounds - they continue normally on failure
	if not success and final_moisture <= 0.0 and not is_malfunction_round:
		print("[Main] GAME OVER - moisture reached 0!")
		_show_game_over()
		return
	
	EventBus.round_completed.emit(success, final_moisture)

func _on_round_completed(success: bool, final_moisture: float) -> void:
	# Handle malfunction completion
	if is_malfunction_round and current_malfunction:
		malfunction_manager.complete_malfunction(success)
		
		# Add currency for successful malfunctions
		if success:
			var base_currency = int(final_moisture)
			var modified_currency = int(round_modifier_manager.apply_currency_modifier(base_currency))
			currency_manager.add_currency(modified_currency)
			EventBus.round_success.emit(final_moisture)
			print("[Main] Malfunction succeeded! Currency gained: %d" % modified_currency)
			print("[Main] Showing reward for: %s" % current_malfunction.name)
			await _show_malfunction_reward(current_malfunction)
		else:
			print("[Main] Malfunction failed - no reward")
		
		# Reset malfunction state
		is_malfunction_round = false
		current_malfunction = null
		
		# After malfunction, return to map
		print("[Main] Malfunction complete - returning to map")
		await get_tree().create_timer(1.0).timeout
		_check_map_progress()
		return
	
	if success:
		# Add moisture as currency with modifier
		var base_currency = int(final_moisture)
		var modified_currency = int(round_modifier_manager.apply_currency_modifier(base_currency))
		currency_manager.add_currency(modified_currency)
		EventBus.round_success.emit(final_moisture)
		
		# Show round complete screen
		await get_tree().create_timer(1.0).timeout
		_show_round_complete(final_moisture)
	else:
		# Failed rounds - show failure and return to map
		EventBus.round_failed.emit(final_moisture)
		
		# Show round failed screen briefly, then back to map
		await get_tree().create_timer(1.5).timeout
		_check_map_progress()

## STATE: ROUND_COMPLETE
func _show_round_complete(final_moisture: float) -> void:
	_hide_all_ui()
	if round_complete_screen:
		round_complete_screen.show_complete(final_moisture, currency_manager)

## Show shop after failure
func _show_shop_after_failure() -> void:
	# Go directly to shop (no success screen)
	EventBus.shop_opened.emit()

## STATE: GAME_OVER
func _show_game_over() -> void:
	print("[Main] _show_game_over() called")
	print("[Main] game_over_screen is: ", game_over_screen)
	_hide_all_ui()
	if game_over_screen:
		print("[Main] Calling game_over_screen.show_game_over(", current_round_number, ")")
		game_over_screen.show_game_over(current_round_number)
		print("[Main] Game over screen should now be visible")
	else:
		print("[Main] ERROR: game_over_screen is null!")

func _on_restart_requested() -> void:
	print("[Main] Restart requested - starting new game")
	get_tree().reload_current_scene()

func _on_quit_requested() -> void:
	print("[Main] Quit requested - returning to main menu")
	_show_main_menu()

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
	_update_power_level_display()
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
	_update_power_level_display()
	
	# Refresh shop inventory
	shop_manager.refresh_shop(current_round_number - 1)
	
	# Show shop screen
	if shop_screen:
		shop_screen.show_shop(shop_manager, currency_manager, fridge_manager, game_state_manager, current_round_number - 1)

## Show super shop (for Bulb Out malfunction reward)
func _show_super_shop() -> void:
	game_state_manager.change_state(GameStateManager.GameState.SHOP)
	_hide_all_ui()
	
	# Don't increment round for super shop
	# Super shop already has items from refresh_super_shop()
	
	# Show shop screen
	if shop_screen:
		shop_screen.show_shop(shop_manager, currency_manager, fridge_manager, game_state_manager, current_round_number - 1)

func _on_shop_closed() -> void:
	# Return to hand selector for next round
	print("[Main] Shop closed - starting next round")
	_show_hand_selector()

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

## Show malfunction reward based on type
func _show_malfunction_reward(malfunction: MalfunctionModel) -> void:
	print("[Main] Showing malfunction reward for: %s" % malfunction.name)
	
	match malfunction.type:
		MalfunctionModel.MalfunctionType.OVERHEAT:
			# Show relic selection
			if malfunction_relic_reward:
				malfunction_relic_reward.show_relic_selection(inventory_manager)
				var relic = await malfunction_relic_reward.relic_selected
				inventory_manager.add_relic(relic)
				print("[Main] Relic reward claimed: %s" % relic.name)
			else:
				print("[Main] Warning: malfunction_relic_reward UI not found")
		
		MalfunctionModel.MalfunctionType.BULB_OUT:
			# Show super shop
			print("[Main] BULB OUT reward: Opening super shop")
			shop_manager.refresh_super_shop()
			_show_super_shop()
			# Wait for shop to close
			await EventBus.shop_closed
			print("[Main] Super shop closed")
		
		MalfunctionModel.MalfunctionType.MACROWAVE:
			# Show action item + compost selection
			if malfunction_macrowave_reward:
				var current_hand = fridge_manager.get_current_hand()
				malfunction_macrowave_reward.show_macrowave_reward(current_hand)
				var result = await malfunction_macrowave_reward.reward_completed
				var selected_item = result[0]
				var composted_ingredient = result[1]
				
				# Add item to inventory
				inventory_manager.add_active_item(selected_item)
				
				# Update UI to show new item
				_update_item_buttons()
				
				# Remove ingredient from deck (compost it)
				fridge_manager.compost_ingredient(composted_ingredient)
				
				print("[Main] Macrowave reward claimed: Item=%s, Composted=%s" % [selected_item.name, composted_ingredient.name])
			else:
				print("[Main] Warning: malfunction_macrowave_reward UI not found")

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
	if game_over_screen:
		game_over_screen.hide()
	if malfunction_popup:
		malfunction_popup.hide()
	if malfunction_relic_reward:
		malfunction_relic_reward.hide()
	if malfunction_macrowave_reward:
		malfunction_macrowave_reward.hide()
	# Hide microwave ON button when UI is hidden
	if on_button:
		on_button.hide()
	# Hide moisture background by default
	if moisture_background:
		moisture_background.hide()

## Update item button UI
func _update_item_buttons() -> void:
	if not inventory_manager:
		print("[Main] WARNING: inventory_manager is null in _update_item_buttons")
		return
		
	var owned_items = inventory_manager.get_active_items()
	var buttons = [item_button_1, item_button_2, item_button_3]
	
	print("[Main] Updating item buttons. Owned items: %d" % owned_items.size())
	
	for i in range(buttons.size()):
		if not buttons[i]:
			print("[Main] WARNING: Button %d is null!" % i)
			continue
			
		if i < owned_items.size():
			print("[Main] Setting button %d to item: %s" % [i, owned_items[i].name])
			buttons[i].set_item(owned_items[i], i)
			buttons[i].show()
		else:
			print("[Main] Hiding button %d (no item)" % i)
			buttons[i].hide()

## Called from ActiveItemButtonUI when button pressed
func try_use_item(item_index: int) -> void:
	if current_round_active:
		item_manager.use_item(item_index, moisture_manager)

## Malfunction animation effects

## Start red throbbing effect for OVERHEAT
func _start_overheat_animation() -> void:
	if not microwave_sprite:
		return
	
	# Stop any existing tween
	if malfunction_animation_tween:
		malfunction_animation_tween.kill()
	
	# Create looping tween that throbs between red and normal
	malfunction_animation_tween = create_tween()
	malfunction_animation_tween.set_loops()
	malfunction_animation_tween.tween_property(microwave_sprite, "modulate", Color(1.5, 0.5, 0.5), 1.0)
	malfunction_animation_tween.tween_property(microwave_sprite, "modulate", Color.WHITE, 1.0)

## Start wave undulation effect for MACROWAVE
func _start_macrowave_animation() -> void:
	if not microwave_sprite:
		return
	
	# Stop any existing tween
	if malfunction_animation_tween:
		malfunction_animation_tween.kill()
	
	# Create looping tween that creates wave effect with scale
	malfunction_animation_tween = create_tween()
	malfunction_animation_tween.set_loops()
	malfunction_animation_tween.tween_property(microwave_sprite, "scale", Vector2(1.05, 0.95), 0.5)
	malfunction_animation_tween.tween_property(microwave_sprite, "scale", Vector2(0.95, 1.05), 0.5)
	malfunction_animation_tween.tween_property(microwave_sprite, "scale", Vector2.ONE, 0.5)

## Stop malfunction animations and reset sprite
func _stop_malfunction_animations() -> void:
	if malfunction_animation_tween:
		malfunction_animation_tween.kill()
		malfunction_animation_tween = null
	
	if microwave_sprite:
		microwave_sprite.modulate = Color.WHITE
		microwave_sprite.scale = Vector2.ONE

## Check if map is complete or show next choices
func _check_map_progress() -> void:
	# Go to shop after every round
	print("[Main] Round complete - opening shop")
	current_round_number += 1
	_open_shop(false)

## Open shop (regular or super)
func _open_shop(is_super: bool) -> void:
	game_state_manager.change_state(GameStateManager.GameState.SHOP)
	_hide_all_ui()
	
	# Refresh shop inventory
	if is_super:
		shop_manager.refresh_super_shop()
	else:
		shop_manager.refresh_shop(current_round_number)
	
	# Show shop screen
	if shop_screen:
		shop_screen.show_shop(shop_manager, currency_manager, fridge_manager, game_state_manager, current_round_number)
	
	# Reset sprite properties
	if microwave_sprite:
		microwave_sprite.modulate = Color.WHITE
		microwave_sprite.scale = Vector2.ONE
