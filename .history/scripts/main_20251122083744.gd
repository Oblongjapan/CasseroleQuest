extends Node

## Main game controller - orchestrates the complete game flow

# Core managers
@onready var moisture_manager: MoistureManager = $CookRound/MoistureManager
@onready var timer_manager: TimerManager = $CookRound/TimerManager

# New managers for game flow
var game_state_manager: GameStateManager
var fridge_manager: FridgeManager
var currency_manager: CurrencyManager
var shop_manager: ShopManager
var inventory_manager: InventoryManager
var progression_manager: ProgressionManager

# UI Screens
@onready var main_menu: Panel = $UI/MainMenu
@onready var hand_selector: Control = $UI/HandSelector
@onready var ingredient_selector: Panel = $UI/IngredientSelector
@onready var cooking_ui: Control = $UI/CookingUI
@onready var round_failed_screen: Panel = $UI/RoundFailedScreen
@onready var shop_screen: Panel = $UI/ShopScreen
@onready var game_over_screen: Panel = $UI/GameOverScreen
@onready var recipe_notification: Panel = $UI/RecipeNotification

# Tier unlock overlay
var tier_unlock_overlay: Panel = null

# Try to get pause menu (may not exist in scene)
var pause_menu: Control = null

# UI Elements
@onready var status_label: Label = $UI/StatusLabel
@onready var moisture_bar: ProgressBar = $UI/MoistureBar
@onready var moisture_background: ColorRect = $UI/Moisturebackground
@onready var moisture_label: Label = $UI/MoistureBar/MoistureLabel
@onready var deck_tracker: Label = $UI/DeckTracker
@onready var currency_label: Label = $UI/CurrencyLabel
@onready var relic_display: HBoxContainer = $UI/RelicDisplay
@onready var game_background: Sprite2D = $UI/Background
@onready var microwave_sprite: AnimatedSprite2D = $UI/Background/Microwave
@onready var on_button: Button = $UI/Background/Microwave/ONButton
@onready var power_lvl_label: Label = $UI/Background/Microwave/PowerLVL/PowerLvl
@onready var ingredient_overlay_1: Sprite2D = $UI/Background/Microwave/IngredientOverlay1
@onready var ingredient_overlay_2: Sprite2D = $UI/Background/Microwave/IngredientOverlay2

# Audio
@onready var music_player: AudioStreamPlayer = $MusicPlayer
var low_pass_filter: AudioEffectLowPassFilter = null
var phaser_filter: AudioEffectPhaser = null
var music_bus_index: int = -1

# Game state
var current_round_number: int = 1
var rounds_in_current_chunk: int = 0  # Track rounds in current 3-round chunk (0, 1, or 2)
var current_round_active: bool = false
var last_round_moisture: float = 0
var game_speed: float = 3.0  # Default to 3x speed
var current_round_ingredients: Array[IngredientModel] = []  # Track ingredients used this round
var discovered_recipes_this_run: Array[String] = []  # Track which recipes have been shown this run

func _ready():
	print("[Main] _ready() starting...")
	
	# Create managers in correct order
	game_state_manager = GameStateManager.new()
	add_child(game_state_manager)
	print("[Main] GameStateManager created")
	
	progression_manager = ProgressionManager.new()
	add_child(progression_manager)
	print("[Main] ProgressionManager created")
	
	fridge_manager = FridgeManager.new()
	add_child(fridge_manager)
	fridge_manager.set_progression_manager(progression_manager)
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
	
	# Connect signals
	EventBus.game_started.connect(_on_game_started)
	EventBus.round_started.connect(_on_round_started)
	EventBus.round_completed.connect(_on_round_completed)
	EventBus.shop_opened.connect(_on_shop_opened)
	EventBus.shop_closed.connect(_on_shop_closed)
	EventBus.moisture_changed.connect(_on_moisture_changed)
	game_state_manager.state_changed.connect(_on_state_changed)
	
	# Connect currency changes
	if currency_manager:
		currency_manager.currency_changed.connect(_update_currency_display)
	
	print("[Main] All signals connected")
	
	# Connect game over screen
	if game_over_screen:
		game_over_screen.restart_requested.connect(_on_restart_requested)
		game_over_screen.quit_requested.connect(_on_quit_requested)
		print("[Main] Game over screen connected")
	else:
		print("[Main] WARNING: game_over_screen is null! Check if GameOverScreen node exists in main.tscn")
	
	# Get pause menu (may not exist yet)
	pause_menu = get_node_or_null("UI/PauseMenu")
	
	# Connect pause menu
	if pause_menu:
		pause_menu.resume_requested.connect(_on_pause_resume)
		pause_menu.restart_requested.connect(_on_pause_restart)
		pause_menu.exit_to_menu_requested.connect(_on_pause_exit_to_menu)
		print("[Main] Pause menu connected")
	else:
		print("[Main] WARNING: pause_menu is null! Add PauseMenu scene to UI node in main.tscn")
	
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
	
	# Connect round failed screen signals
	if round_failed_screen:
		round_failed_screen.retry_requested.connect(_on_retry_requested)
		round_failed_screen.return_to_menu_requested.connect(_on_return_to_menu)
	
	# Set game speed to 3x by default
	Engine.time_scale = game_speed
	print("[Main] Game speed set to: %.1fx" % game_speed)
	
	# Setup deck tracker
	if deck_tracker:
		deck_tracker.setup(fridge_manager)
		# Force initial update to ensure display is correct
		deck_tracker._update_display()
		print("[Main] Deck tracker connected and initialized")
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
	# Create and add tier unlock overlay
	var tier_overlay_scene = load("res://scenes/tier_unlock_overlay.tscn")
	if tier_overlay_scene:
		tier_unlock_overlay = tier_overlay_scene.instantiate()
		$UI.add_child(tier_unlock_overlay)
		
		# Position in bottom right corner
		tier_unlock_overlay.anchors_preset = Control.PRESET_BOTTOM_RIGHT
		tier_unlock_overlay.anchor_left = 1.0
		tier_unlock_overlay.anchor_top = 1.0
		tier_unlock_overlay.anchor_right = 1.0
		tier_unlock_overlay.anchor_bottom = 1.0
		tier_unlock_overlay.offset_left = -320  # 300 width + 20 margin
		tier_unlock_overlay.offset_top = -120   # 100 height + 20 margin
		tier_unlock_overlay.offset_right = -20
		tier_unlock_overlay.offset_bottom = -20
		
		print("[Main] Tier unlock overlay created and positioned")
		
		# Connect tier unlock signal
		if progression_manager:
			progression_manager.tier_unlocked.connect(_on_tier_unlocked)
			print("[Main] Tier unlock signal connected")
	else:
		print("[Main] Warning: Could not load tier_unlock_overlay.tscn")
	
	# Setup audio low pass filter for shop
	if music_player:
		music_bus_index = AudioServer.get_bus_index(music_player.bus)
		print("[Main] Music player found on bus index: %d" % music_bus_index)
	else:
		print("[Main] Warning: MusicPlayer not found")
	
	# Auto-start game immediately (skip main menu)
	print("[Main] Auto-starting game...")
	_hide_all_ui()
	_on_game_started()
	print("[Main] _ready() complete")

func _unhandled_input(event: InputEvent) -> void:
	# Toggle pause menu with spacebar or escape
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE:
			print("[Main] Pause key pressed (keycode: %d)" % event.keycode)
			if pause_menu:
				if pause_menu.visible:
					print("[Main] Hiding pause menu")
					_remove_pause_music_filter()
					pause_menu.hide_pause_menu()
				else:
					print("[Main] Showing pause menu")
					_apply_pause_music_filter()
					pause_menu.show_pause_menu()
				get_viewport().set_input_as_handled()
			else:
				print("[Main] WARNING: pause_menu is null!")

func _process(delta: float) -> void:
	# Debug: Press M to trigger malfunction
	if Input.is_action_just_pressed("ui_page_down") or Input.is_key_pressed(KEY_M):
		_debug_trigger_malfunction()
	
	# Debug: Press S to open shop
	if Input.is_key_pressed(KEY_S) and not shop_screen.visible:
		_debug_open_shop()
	
	if not current_round_active:
		return
	
	# Update all systems during cooking
	moisture_manager.update_moisture(delta)
	timer_manager.update_timer(delta)
	
	# Check win/loss conditions
	if moisture_manager.check_failure():
		_end_round(false)
	elif timer_manager.check_complete():
		_end_round(true)

## Debug function to open shop for testing
func _debug_open_shop() -> void:
	print("[Main] DEBUG: Opening shop with S key")
	EventBus.shop_opened.emit()

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

func _update_round_counter_display() -> void:
	if status_label:
		status_label.text = "Round %d/3" % (rounds_in_current_chunk + 1)

func _update_currency_display(new_amount: int) -> void:
	if currency_label:
		currency_label.text = "Currency: %d" % new_amount

func _update_ingredient_overlays(ingredient_1: IngredientModel, ingredient_2) -> void:
	# Load and show first ingredient
	if ingredient_overlay_1 and ingredient_1:
		# Strip "Organic " prefix to get base ingredient name for texture
		var base_name = ingredient_1.name.replace("Organic ", "")
		
		# Array to hold all textures for this ingredient
		var textures: Array = []
		
		# Check if this is a combo recipe (contains "+")
		if "+" in base_name:
			# For combo recipes, load all ingredient textures
			var ingredient_names = base_name.split("+")
			for ing_name in ingredient_names:
				var texture_path = "res://Assets/Food/%s.png" % ing_name
				var texture = load(texture_path)
				if texture:
					textures.append(texture)
				else:
					print("[Main] WARNING: Could not load texture for combo ingredient: %s" % texture_path)
			
			if textures.size() > 0:
				ingredient_overlay_1.set_ingredient(ingredient_1.name, textures)
				print("[Main] Showing ingredient overlay 1: %s (combo with %d layers)" % [ingredient_1.name, textures.size()])
		else:
			# Single ingredient - normal handling
			# Map recipe names to actual PNG filenames
			var recipe_name_map = {
				"Chicken+Rice": "Chicken and RIce",
				"Steak+Potato": "Steak and Potato"
			}
			
			if recipe_name_map.has(base_name):
				base_name = recipe_name_map[base_name]
			
			var texture_path = "res://Assets/Food/%s.png" % base_name
			var texture = load(texture_path)
			if texture:
				textures.append(texture)
				ingredient_overlay_1.set_ingredient(ingredient_1.name, textures)
				print("[Main] Showing ingredient overlay 1: %s" % ingredient_1.name)
			else:
				print("[Main] WARNING: Could not load texture for ingredient 1: %s" % texture_path)
	
	# Load and show second ingredient if different from first
	if ingredient_overlay_2 and ingredient_2 and ingredient_2 != ingredient_1:
		# Strip "Organic " prefix to get base ingredient name for texture
		var base_name = ingredient_2.name.replace("Organic ", "")
		
		# Array to hold all textures for this ingredient
		var textures: Array = []
		
		# Check if this is a combo recipe (contains "+")
		if "+" in base_name:
			# For combo recipes, load all ingredient textures
			var ingredient_names = base_name.split("+")
			for ing_name in ingredient_names:
				var texture_path = "res://Assets/Food/%s.png" % ing_name
				var texture = load(texture_path)
				if texture:
					textures.append(texture)
				else:
					print("[Main] WARNING: Could not load texture for combo ingredient: %s" % texture_path)
			
			if textures.size() > 0:
				ingredient_overlay_2.set_ingredient(ingredient_2.name, textures)
				print("[Main] Showing ingredient overlay 2: %s (combo with %d layers)" % [ingredient_2.name, textures.size()])
		else:
			# Single ingredient - normal handling
			# Map recipe names to actual PNG filenames
			var recipe_name_map = {
				"Chicken+Rice": "Chicken and RIce",
				"Steak+Potato": "Steak and Potato"
			}
			
			if recipe_name_map.has(base_name):
				base_name = recipe_name_map[base_name]
			
			var texture_path = "res://Assets/Food/%s.png" % base_name
			var texture = load(texture_path)
			if texture:
				textures.append(texture)
				ingredient_overlay_2.set_ingredient(ingredient_2.name, textures)
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
	discovered_recipes_this_run.clear()  # Reset discovered recipes for new run
	_update_power_level_display()
	_update_currency_display(currency_manager.get_currency())
	
	# Show hand selector (draw 5 cards for first round)
	_show_hand_selector(true)
	print("[Main] _on_game_started complete")

## STATE: HAND_SELECTOR
## after_shop: true = draw 5 new cards, false = draw 1 card to add to hand
func _show_hand_selector(after_shop: bool = false) -> void:
	print("[Main] _show_hand_selector called (after_shop: %s)" % after_shop)
	
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
	
	# Show game background (microwave scene)
	if game_background:
		game_background.show()
	
	# Play microwave Idle animation when choosing ingredients
	if microwave_sprite:
		microwave_sprite.play("Idle")
	
	# Show moisture background and reset display to 0/0
	if moisture_background:
		moisture_background.show()
	# Reset moisture bar to grey/empty state (0/0)
	EventBus.moisture_changed.emit(0.0, 0.0, 0.0)
	# Also reset the moisture label text to 0/0
	if moisture_label:
		moisture_label.text = "0/0"
	_update_moisture_display()
	
	if hand_selector:
		print("[Main] hand_selector exists, calling show_hand_selection()")
		hand_selector.show_hand_selection(fridge_manager, game_state_manager, progression_manager, after_shop)
		_update_round_counter_display()
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
		# Strip "Organic " prefix to get base ingredient name for texture
		var base_name = ingredient.name.replace("Organic ", "")
		
		# Array to hold all textures for this ingredient
		var textures: Array = []
		
		# Check if this is a combo recipe (contains "+")
		if "+" in base_name:
			print("[Main] Combo recipe detected: %s" % base_name)
			# For combo recipes, load all ingredient textures
			var ingredient_names = base_name.split("+")
			for ing_name in ingredient_names:
				var texture_path = "res://Assets/Food/%s.png" % ing_name
				var texture = load(texture_path)
				if texture:
					textures.append(texture)
					print("[Main] Loaded texture for %s" % ing_name)
				else:
					print("[Main] WARNING: Could not load texture: %s" % texture_path)
			
			if textures.size() > 0:
				overlay.set_ingredient(ingredient.name, textures)
				print("[Main] Showing combo ingredient overlay %d: %s with %d layers" % [overlay_index + 1, ingredient.name, textures.size()])
			else:
				print("[Main] ERROR: No textures loaded for combo recipe: %s" % base_name)
		else:
			# Single ingredient - normal handling
			# Map recipe names to actual PNG filenames
			var recipe_name_map = {
				"Chicken+Rice": "Chicken and RIce",
				"Steak+Potato": "Steak and Potato"
			}
			
			if recipe_name_map.has(base_name):
				base_name = recipe_name_map[base_name]
			
			var texture_path = "res://Assets/Food/%s.png" % base_name
			var texture = load(texture_path)
			if texture:
				textures.append(texture)
				overlay.set_ingredient(ingredient.name, textures)
				print("[Main] Showing ingredient overlay %d: %s" % [overlay_index + 1, ingredient.name])
			else:
				print("[Main] WARNING: Could not load texture: %s" % texture_path)
	
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
	
	# Remove selected cards from fridge manager's hand tracking
	var selected_cards: Array[IngredientModel] = [ing1]
	if ing2 and ing2 != ing1:
		selected_cards.append(ing2)
	
	for card in selected_cards:
		var hand_index = fridge_manager.current_hand.find(card)
		if hand_index != -1:
			fridge_manager.current_hand.remove_at(hand_index)
			print("[Main] Removed %s from fridge manager's hand" % card.name)
	
	# Emit deck changed signal to update counter
	fridge_manager._emit_deck_changed()
	
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
	
	# Track ingredients for recipe checking
	current_round_ingredients.clear()
	current_round_ingredients.append(ingredient_1)
	if ingredient_2 and ingredient_2 != ingredient_1:
		current_round_ingredients.append(ingredient_2)
	
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
	# Show game background during cooking
	if game_background:
		game_background.show()
	# Show moisture background during cooking
	if moisture_background:
		moisture_background.show()
	status_label.text = "Round %d - Cooking..." % current_round_number
	
	# Initialize all managers
	print("[Main] Initializing moisture_manager...")
	moisture_manager.setup(ingredient_1, ingredient_2, 1.0, inventory_manager)
	
	# The setup() function already emits moisture_changed signal which updates the bar
	print("[Main] Moisture initialized: %.1f/%.1f" % [moisture_manager.current_moisture, moisture_manager.max_moisture])
	
	# Apply malfunction effects if this is a malfunction round
	if is_malfunction_round and current_malfunction:
		print("[Main] Applying malfunction effects: %s" % current_malfunction.name)
		match current_malfunction.type:
			MalfunctionModel.MalfunctionType.OVERHEAT:
				# 1.5x base drain rate
				moisture_manager.set_malfunction_multiplier(1.5)
				timer_manager.start_timer(15.0)
				print("[Main] OVERHEAT: Drain rate 1.5x, Timer: 15s")
			
			MalfunctionModel.MalfunctionType.BULB_OUT:
				# 0.5x drain rate
				moisture_manager.set_malfunction_multiplier(0.5)
				timer_manager.start_timer(15.0)
				print("[Main] BULB OUT: Drain rate 0.5x, Timer: 15s")
	else:
		# Normal timer
		timer_manager.start_timer(15.0)
		moisture_manager.reset_malfunction_multiplier()
		print("[Main] Normal timer: 15s")
	
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
			currency_manager.add_currency(base_currency)
			EventBus.round_success.emit(final_moisture)
			print("[Main] Malfunction succeeded! Currency gained: %d" % base_currency)
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
		# Check for recipe creation
		_check_and_create_recipe()
		
		# Add moisture as currency
		var base_currency = int(final_moisture)
		currency_manager.add_currency(base_currency)
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

## Check if the current round ingredients form a recipe and add it to the deck
func _check_and_create_recipe() -> void:
	print("[Main] === _check_and_create_recipe called ===")
	print("[Main] current_round_ingredients count: %d" % current_round_ingredients.size())
	
	if current_round_ingredients.size() < 2:
		print("[Main] Not enough ingredients for a recipe (need 2+)")
		# Single ingredient - discard it back to deck
		if current_round_ingredients.size() == 1:
			fridge_manager.discard_cards(current_round_ingredients)
			print("[Main] Single ingredient used - returned to discard pile")
		return
	
	# Debug: Print all ingredients being combined
	print("[Main] Ingredients to combine:")
	for i in range(current_round_ingredients.size()):
		var ing = current_round_ingredients[i]
		print("[Main]   %d: %s (Water:%d, RST:%d, Vol:%d)" % [
			i, ing.name, ing.water_content, ing.heat_resistance, ing.volatility
		])
	
	# Get ingredient names
	var ingredient_names: Array[String] = []
	for ingredient in current_round_ingredients:
		ingredient_names.append(ingredient.name)
	
	print("[Main] Calling RecipesData.combine_ingredients()...")
	
	# Always create dynamic combo - this allows any ingredients to combine
	var combined_ingredient = RecipesData.combine_ingredients(current_round_ingredients)
	if combined_ingredient:
		print("[Main] Recipe created successfully: %s" % combined_ingredient.name)
		
		# Generate a unique recipe ID for tracking
		var sorted_names = ingredient_names.duplicate()
		sorted_names.sort()
		var recipe_id = "combo_" + "_".join(sorted_names).replace(" ", "_").replace("+", "_").to_lower()
		
		print("[Main] Recipe ID for tracking: %s" % recipe_id)
		
		# Register in progression manager
		progression_manager.register_recipe(recipe_id, combined_ingredient.name)
		
		# Add combo to deck and consume the original ingredients
		fridge_manager.add_ingredient_to_deck(combined_ingredient)
		fridge_manager.consume_cards(current_round_ingredients)
		
		# The original ingredients are consumed (permanently removed from deck)
		# This means net deck size goes down by (ingredients used - 1)
		# Example: 2 ingredients → 1 combo = deck shrinks by 1
		
		print("[Main] Added %s to deck (Water: %d, RST: %d, Vol: %d)" % [
			combined_ingredient.name,
			combined_ingredient.water_content,
			combined_ingredient.heat_resistance,
			combined_ingredient.volatility
		])
		print("[Main] Original %d ingredients consumed (permanently removed)" % current_round_ingredients.size())
	else:
		print("[Main] Failed to create combo")
		# Failsafe - discard ingredients back
		fridge_manager.discard_cards(current_round_ingredients)
		print("[Main] Ingredients returned to discard pile")

## STATE: ROUND_COMPLETE
func _show_round_complete(_final_moisture: float) -> void:
	print("[Main] _show_round_complete called")
	
	# Don't hide all UI - keep the cooking view visible
	# Just fade out the ingredient overlays
	print("[Main] Starting ingredient fade out")
	await _fade_out_ingredients()
	print("[Main] Ingredient fade out complete")
	
	# Check and show recipe notification if applicable
	print("[Main] Checking for recipe notification")
	await _show_recipe_notification()
	print("[Main] Recipe notification complete")
	
	# Show round transition animation
	print("[Main] Starting round transition")
	await _show_round_transition()
	print("[Main] Round transition complete")
	
	# Continue to next round/shop
	print("[Main] Calling _check_map_progress")
	_check_map_progress()

## Fade out ingredient overlays
func _fade_out_ingredients() -> void:
	print("[Main] _fade_out_ingredients called")
	print("[Main] overlay_1 exists: %s, visible: %s" % [ingredient_overlay_1 != null, ingredient_overlay_1.visible if ingredient_overlay_1 else false])
	print("[Main] overlay_2 exists: %s, visible: %s" % [ingredient_overlay_2 != null, ingredient_overlay_2.visible if ingredient_overlay_2 else false])
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	var has_animations = false
	
	if ingredient_overlay_1 and ingredient_overlay_1.visible:
		print("[Main] Adding fade animation for overlay_1")
		tween.tween_property(ingredient_overlay_1, "modulate:a", 0.0, 0.5)
		has_animations = true
	
	if ingredient_overlay_2 and ingredient_overlay_2.visible:
		print("[Main] Adding fade animation for overlay_2")
		tween.tween_property(ingredient_overlay_2, "modulate:a", 0.0, 0.5)
		has_animations = true
	
	if has_animations:
		print("[Main] Waiting for tween to finish...")
		await tween.finished
		print("[Main] Tween finished!")
	else:
		print("[Main] No animations to run, skipping tween")
	
	# Reset overlays for next round
	if ingredient_overlay_1:
		ingredient_overlay_1.hide()
		ingredient_overlay_1.modulate.a = 1.0
		print("[Main] Reset overlay_1")
	if ingredient_overlay_2:
		ingredient_overlay_2.hide()
		ingredient_overlay_2.modulate.a = 1.0
		print("[Main] Reset overlay_2")
	
	print("[Main] _fade_out_ingredients complete")

## Show recipe notification if a recipe was created
func _show_recipe_notification() -> void:
	print("[Main] _show_recipe_notification called")
	
	# Check if a recipe was created this round (must be 2+ ingredients)
	if current_round_ingredients.size() < 2:
		print("[Main] Not enough ingredients for recipe notification. Size: %d" % current_round_ingredients.size())
		return
	
	# Create the combined recipe name
	var ingredient_names: Array[String] = []
	for ingredient in current_round_ingredients:
		ingredient_names.append(ingredient.name)
	
	var recipe_name = "+".join(ingredient_names)
	print("[Main] Recipe created: %s" % recipe_name)
	
	# Check if this exact combo has already been discovered this run
	if recipe_name in discovered_recipes_this_run:
		print("[Main] Recipe '%s' already discovered this run, skipping notification" % recipe_name)
		return
	
	# Mark as discovered
	discovered_recipes_this_run.append(recipe_name)
	print("[Main] First discovery of '%s' this run!" % recipe_name)
	
	# Show the combo recipe in the microwave overlays (on plates with both ingredients)
	_display_combo_in_microwave(recipe_name)
	
	# Show recipe notification using the scene
	if recipe_notification:
		print("[Main] Showing recipe notification panel for: %s" % recipe_name)
		recipe_notification.show_notification(recipe_name)
		await recipe_notification.notification_closed
		print("[Main] Recipe notification closed")
	else:
		print("[Main] ERROR: recipe_notification is null!")
		# Fallback wait if notification doesn't exist
		await get_tree().create_timer(2.0).timeout
	
	# Fade out the combo display
	await _fade_out_combo_display()
	
	print("[Main] Recipe notification complete")

## Display the combo recipe in the microwave overlays
func _display_combo_in_microwave(recipe_name: String) -> void:
	print("[Main] Displaying combo in microwave: %s" % recipe_name)
	
	# Parse the recipe name to get individual ingredients
	var ingredient_names = recipe_name.split("+")
	
	# Load textures for all ingredients
	var textures: Array = []
	for ing_name in ingredient_names:
		var texture_path = "res://Assets/Food/%s.png" % ing_name
		var texture = load(texture_path)
		if texture:
			textures.append(texture)
			print("[Main] Loaded texture for %s" % ing_name)
		else:
			print("[Main] WARNING: Could not load texture: %s" % texture_path)
	
	# Calculate center position between the two overlays
	# Overlay 1 is at Vector2(-171.666, 135.482)
	# Overlay 2 is at Vector2(7.46371, 135.482)
	var center_position = Vector2(-82.1, 135.482)
	
	# Display in overlay 1 (centered between both overlays)
	if ingredient_overlay_1 and textures.size() > 0:
		ingredient_overlay_1.position = center_position
		ingredient_overlay_1.set_ingredient(recipe_name, textures)
		ingredient_overlay_1.modulate.a = 1.0
		ingredient_overlay_1.show()
		print("[Main] Combo displayed in overlay 1 with %d layers at center position" % textures.size())
	
	# Hide overlay 2
	if ingredient_overlay_2:
		ingredient_overlay_2.hide()

## Fade out the combo display after notification is closed
func _fade_out_combo_display() -> void:
	print("[Main] Fading out combo display")
	
	if ingredient_overlay_1 and ingredient_overlay_1.visible:
		var tween = create_tween()
		tween.tween_property(ingredient_overlay_1, "modulate:a", 0.0, 0.5)
		await tween.finished
		
		ingredient_overlay_1.hide()
		ingredient_overlay_1.modulate.a = 1.0
		ingredient_overlay_1.clear_overlay()
		# Restore original position for next round
		ingredient_overlay_1.position = Vector2(-171.666, 135.482)
		print("[Main] Combo display faded out and position restored")
	else:
		print("[Main] No combo to fade out")

## Show round transition animation (large "Round X" that scales down)
func _show_round_transition() -> void:
	# Create a large centered label
	var round_label = Label.new()
	# Show the round that was just completed (rounds_in_current_chunk is 0-based, so +1)
	round_label.text = "Round %d/3" % (rounds_in_current_chunk + 1)
	round_label.add_theme_font_size_override("font_size", 128)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Add to UI layer and center it
	var ui_layer = $UI
	ui_layer.add_child(round_label)
	round_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	round_label.z_index = 100
	
	# Start large and fade in
	round_label.scale = Vector2(2.0, 2.0)
	round_label.modulate.a = 0.0
	
	# Animate: fade in + scale down
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(round_label, "modulate:a", 1.0, 0.3)
	tween.tween_property(round_label, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	# Hold for a moment
	await get_tree().create_timer(0.8).timeout
	
	# Fade out
	var fade_out = create_tween()
	fade_out.tween_property(round_label, "modulate:a", 0.0, 0.3)
	await fade_out.finished
	
	round_label.queue_free()

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

## Pause menu callbacks
func _on_pause_resume() -> void:
	print("[Main] Resume from pause menu")
	# Pause menu handles unpausing itself

func _on_pause_restart() -> void:
	print("[Main] Restart from pause menu")
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_pause_exit_to_menu() -> void:
	print("[Main] Exit to menu from pause menu")
	get_tree().paused = false
	_on_return_to_menu()

## Tier unlock handler
func _on_tier_unlocked(tier_number: int) -> void:
	print("[Main] Tier %d unlocked! Showing achievement overlay..." % tier_number)
	if tier_unlock_overlay:
		tier_unlock_overlay.show_tier_unlock(tier_number)

## STATE: SHOP
func _on_shop_opened() -> void:
	game_state_manager.change_state(GameStateManager.GameState.SHOP)
	_hide_all_ui()
	
	# Apply low pass filter to music
	_apply_shop_music_filter()
	
	# Increment round number after completing a round
	current_round_number += 1
	_update_power_level_display()
	
	# Refresh shop inventory
	shop_manager.refresh_shop(current_round_number - 1)
	
	# Show shop screen
	if shop_screen:
		shop_screen.show_shop(shop_manager, currency_manager, fridge_manager, game_state_manager, progression_manager, current_round_number - 1)

## Show super shop (for Bulb Out malfunction reward)
func _show_super_shop() -> void:
	game_state_manager.change_state(GameStateManager.GameState.SHOP)
	_hide_all_ui()
	
	# Apply low pass filter to music
	_apply_shop_music_filter()
	
	# Don't increment round for super shop
	# Super shop already has items from refresh_super_shop()
	
	# Show shop screen
	if shop_screen:
		shop_screen.show_shop(shop_manager, currency_manager, fridge_manager, game_state_manager, progression_manager, current_round_number - 1)

func _on_shop_closed() -> void:
	# Remove low pass filter from music
	_remove_shop_music_filter()
	
	# Return to hand selector for next round (draw 5 new cards after shop)
	print("[Main] Shop closed - starting next round with fresh hand")
	_show_hand_selector(true)

## Handle moisture changed from MoistureManager
func _on_moisture_changed(current: float, max_value: float, bonus: float) -> void:
	# Update progress bar
	if moisture_bar:
		moisture_bar.max_value = max_value + bonus
		moisture_bar.value = current
		moisture_bar.show()
	
	# Update label
	if moisture_label:
		var display_current = int(current)
		var display_max = int(max_value + bonus)
		moisture_label.text = "%d/%d" % [display_current, display_max]
		moisture_label.show()
	
	print("[Main] Moisture updated: %d/%d (bonus: %d)" % [int(current), int(max_value), int(bonus)])

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
	# Hide microwave ON button when UI is hidden
	if on_button:
		on_button.hide()
	# Hide moisture background by default
	if moisture_background:
		moisture_background.hide()
	# Hide moisture bar and label
	if moisture_bar:
		moisture_bar.hide()
	if moisture_label:
		moisture_label.hide()
	# Hide status label (round marker)
	if status_label:
		status_label.hide()
	# Hide game background (microwave scene)
	if game_background:
		game_background.hide()

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
	# Track rounds in current chunk (0, 1, 2)
	rounds_in_current_chunk += 1
	print("[Main] Round %d of 3 complete" % rounds_in_current_chunk)
	
	# Check if we've completed 3 rounds
	if rounds_in_current_chunk >= 3:
		# Reset chunk counter and increment power level
		rounds_in_current_chunk = 0
		current_round_number += 1
		_update_power_level_display()
		print("[Main] 3-round chunk complete - power level now %d" % current_round_number)
		
		# Go to shop after 3 rounds
		_open_shop(false)
	else:
		# Continue to next round in chunk (draw 1 card between rounds)
		print("[Main] Continuing to next round in chunk")
		_update_round_counter_display()
		_show_hand_selector(false)

## Open shop (regular or super)
func _open_shop(is_super: bool) -> void:
	game_state_manager.change_state(GameStateManager.GameState.SHOP)
	_hide_all_ui()
	
	# Apply low pass filter to music
	_apply_shop_music_filter()
	
	# Refresh shop inventory
	if is_super:
		shop_manager.refresh_super_shop()
	else:
		shop_manager.refresh_shop(current_round_number)
	
	# Show shop screen
	if shop_screen:
		shop_screen.show_shop(shop_manager, currency_manager, fridge_manager, game_state_manager, progression_manager, current_round_number)
	
	# Reset sprite properties
	if microwave_sprite:
		microwave_sprite.modulate = Color.WHITE
		microwave_sprite.scale = Vector2.ONE

## Apply low pass filter to music when entering shop
func _apply_shop_music_filter() -> void:
	if not music_player or music_bus_index < 0:
		return
	
	# Create low pass filter if it doesn't exist
	if not low_pass_filter:
		low_pass_filter = AudioEffectLowPassFilter.new()
		low_pass_filter.cutoff_hz = 800.0  # Lower frequencies only (muffled effect)
		low_pass_filter.resonance = 1.0
	
	# Create phaser filter if it doesn't exist
	if not phaser_filter:
		phaser_filter = AudioEffectPhaser.new()
		phaser_filter.range_min_hz = 440.0
		phaser_filter.range_max_hz = 1600.0
		phaser_filter.rate_hz = 0.5  # Slow phasing effect
		phaser_filter.depth = 1.0
	
	# Add filters to the music bus
	AudioServer.add_bus_effect(music_bus_index, low_pass_filter)
	AudioServer.add_bus_effect(music_bus_index, phaser_filter)
	print("[Main] Applied low pass + phaser filters to shop music")

## Remove low pass filter from music when leaving shop
func _remove_shop_music_filter() -> void:
	if not music_player or music_bus_index < 0:
		return
	
	# Find and remove both filters from the bus
	var effect_count = AudioServer.get_bus_effect_count(music_bus_index)
	for i in range(effect_count - 1, -1, -1):  # Iterate backwards to avoid index issues
		var effect = AudioServer.get_bus_effect(music_bus_index, i)
		if effect is AudioEffectLowPassFilter or effect is AudioEffectPhaser:
			AudioServer.remove_bus_effect(music_bus_index, i)
			print("[Main] Removed audio filter from music (index %d)" % i)

## Apply low pass filter only for pause menu
func _apply_pause_music_filter() -> void:
	if not music_player or music_bus_index < 0:
		return
	
	# Create low pass filter if it doesn't exist
	if not low_pass_filter:
		low_pass_filter = AudioEffectLowPassFilter.new()
		low_pass_filter.cutoff_hz = 800.0
		low_pass_filter.resonance = 1.0
	
	# Add only low pass filter to the music bus
	AudioServer.add_bus_effect(music_bus_index, low_pass_filter)
	print("[Main] Applied low pass filter for pause menu")

## Remove pause music filter
func _remove_pause_music_filter() -> void:
	if not music_player or music_bus_index < 0:
		return
	
	# Find and remove low pass filter from the bus
	var effect_count = AudioServer.get_bus_effect_count(music_bus_index)
	for i in range(effect_count - 1, -1, -1):
		var effect = AudioServer.get_bus_effect(music_bus_index, i)
		if effect is AudioEffectLowPassFilter:
			AudioServer.remove_bus_effect(music_bus_index, i)
			print("[Main] Removed low pass filter from pause menu")
