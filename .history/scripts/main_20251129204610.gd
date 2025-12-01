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
var recipe_book_manager: RecipeBookManager

# UI Screens
@onready var main_menu: Panel = $UI/MainMenu
@onready var hand_selector: Control = $UI/HandSelector
@onready var ingredient_selector: Panel = $UI/IngredientSelector
@onready var cooking_ui: Control = $UI/CookingUI
@onready var round_failed_screen: Panel = $UI/RoundFailedScreen
# @onready var shop_screen: Panel = $UI/ShopScreen # Removed old shop
@onready var game_over_screen: Panel = $UI/GameOverScreen
@onready var recipe_card_reveal: Control = $UI/RecipeCardReveal
@onready var card_selector: CardSelector = $UI/CardSelector

# New Shop System
@onready var main_camera: Camera2D = $MainCamera
@onready var shop_ui: Control = $UI/ShopUI
@onready var sample_button_1: TextureButton = $UI/ShopUI/SampleButton1
@onready var sample_button_2: TextureButton = $UI/ShopUI/SampleButton2
@onready var sample_button_3: TextureButton = $UI/ShopUI/SampleButton3
@onready var make_organic_button: Button = $UI/ShopUI/MakeOrganicButton
@onready var exit_shop_button: Button = $UI/ShopUI/ExitButton

@export_group("Camera Settings")
@export var main_camera_pos: Vector2 = Vector2(640, 360)
@export var main_camera_zoom: Vector2 = Vector2(1.0, 1.0)
@export var shop_camera_pos: Vector2 = Vector2(1600, 360) # Pan right towards fridge area (stay within background bounds)
@export var shop_camera_zoom: Vector2 = Vector2(1.2, 1.2) # Slight zoom only

var current_shop_ingredients: Array[IngredientModel] = []

# Shop sample tracking
var samples_taken: int = 0
const MAX_SAMPLES: int = 2

# Organic upgrade tracking
var pending_organic_upgrade: Dictionary = {}
var organic_used: bool = false  # Track if Make Organic was used this shop phase

# Hover card for shop buttons
var hover_card: IngredientCard = null

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
@onready var tier_progress_label: Label = $UI/TierProgressLabel
@onready var relic_display: HBoxContainer = $UI/RelicDisplay
@onready var radio_overlay: TextureButton = $UI/RadioOverlay
@onready var game_background: Sprite2D = $Background
@onready var microwave_sprite: AnimatedSprite2D = $Background/Microwave
@onready var on_button: Button = $Background/Microwave/ONButton
@onready var power_lvl_label: Label = $Background/Microwave/PowerLVL/PowerLvl
@onready var ingredient_overlay_1: Sprite2D = $Background/Microwave/IngredientOverlay1
@onready var ingredient_overlay_2: Sprite2D = $Background/Microwave/IngredientOverlay2

# Store initial positions for centering combo result
var overlay_1_start_pos: Vector2
var overlay_2_start_pos: Vector2

# Audio
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var beep_player: AudioStreamPlayer = $BeepPlayer
@onready var hum_player: AudioStreamPlayer = $HumPlayer
var low_pass_filter: AudioEffectLowPassFilter = null
var phaser_filter: AudioEffectPhaser = null
var music_bus_index: int = -1
var lowpass_effect_index: int = -1
var phaser_effect_index: int = -1

# Game state
var current_round_number: int = 1
var rounds_in_current_chunk: int = 0  # Track rounds in current 3-round chunk (0, 1, or 2)
var current_round_active: bool = false
var last_round_moisture: float = 0
var game_speed: float = 3.0  # Default to 3x speed
var current_round_ingredients: Array[IngredientModel] = []  # Track ingredients used this round
var discovered_recipes_this_run: Array[String] = []  # Track which recipes have been shown this run
var recipe_created_this_round: bool = false  # Track if recipe was successfully created
var last_created_recipe: IngredientModel = null  # Store the last created recipe for notification

func _ready():
	print("[Main] _ready() starting...")
	
	# Create managers in correct order
	game_state_manager = GameStateManager.new()
	add_child(game_state_manager)
	print("[Main] GameStateManager created")
	
	progression_manager = ProgressionManager.new()
	add_child(progression_manager)
	print("[Main] ProgressionManager created")
	
	recipe_book_manager = RecipeBookManager.new()
	add_child(recipe_book_manager)
	print("[Main] RecipeBookManager created")
	
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
	
	# Connect shop buttons
	if sample_button_1:
		sample_button_1.pressed.connect(func(): _on_sample_selected(0))
		sample_button_1.mouse_entered.connect(func(): _on_shop_button_hover_start(0))
		sample_button_1.mouse_exited.connect(_on_shop_button_hover_end)
	if sample_button_2:
		sample_button_2.pressed.connect(func(): _on_sample_selected(1))
		sample_button_2.mouse_entered.connect(func(): _on_shop_button_hover_start(1))
		sample_button_2.mouse_exited.connect(_on_shop_button_hover_end)
	if sample_button_3:
		sample_button_3.pressed.connect(func(): _on_sample_selected(2))
		sample_button_3.mouse_entered.connect(func(): _on_shop_button_hover_start(2))
		sample_button_3.mouse_exited.connect(_on_shop_button_hover_end)
	if make_organic_button:
		make_organic_button.pressed.connect(_on_make_organic_pressed)
	if exit_shop_button:
		exit_shop_button.pressed.connect(_on_shop_closed)
	if radio_overlay:
		radio_overlay.pressed.connect(_on_radio_pressed)
	
	# Store initial positions of overlays
	if ingredient_overlay_1:
		overlay_1_start_pos = ingredient_overlay_1.position
		print("[Main] Stored overlay 1 start pos: %s" % overlay_1_start_pos)
	if ingredient_overlay_2:
		overlay_2_start_pos = ingredient_overlay_2.position
		print("[Main] Stored overlay 2 start pos: %s" % overlay_2_start_pos)
	
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
	
	# Connect card selector signals for organic upgrade
	if card_selector:
		card_selector.card_selected.connect(_on_card_selected_for_organic)
		card_selector.selection_cancelled.connect(_on_organic_upgrade_cancelled)
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
		# Make sure music continues playing when game is paused
		music_player.process_mode = Node.PROCESS_MODE_ALWAYS
		# Using pre-pitched audio file (bgm_fast.mp3) - no pitch scaling needed
		# Ensure looping is enabled for HTML5 export - set on AudioStreamMP3 directly
		if music_player.stream and music_player.stream is AudioStreamMP3:
			music_player.stream.loop = true
			print("[Main] AudioStreamMP3 loop enabled")
		
		# Connect finished signal for manual looping fallback (HTML5 sometimes needs this)
		if not music_player.finished.is_connected(_on_music_finished):
			music_player.finished.connect(_on_music_finished)
			print("[Main] Connected music_player.finished for manual looping")
		
		# Find existing effects in the bus layout or add new ones
		var effect_count = AudioServer.get_bus_effect_count(music_bus_index)
		print("[Main] Bus has %d existing effects" % effect_count)
		
		# Look for existing lowpass and phaser effects
		for i in range(effect_count):
			var effect = AudioServer.get_bus_effect(music_bus_index, i)
			if effect is AudioEffectLowPassFilter and lowpass_effect_index == -1:
				lowpass_effect_index = i
				low_pass_filter = effect
				print("[Main] Found existing lowpass filter at index %d" % i)
			elif effect is AudioEffectPhaser and phaser_effect_index == -1:
				phaser_effect_index = i
				phaser_filter = effect
				print("[Main] Found existing phaser filter at index %d" % i)
		
		# If no existing effects found, create and add new ones
		if lowpass_effect_index == -1:
			low_pass_filter = AudioEffectLowPassFilter.new()
			low_pass_filter.cutoff_hz = 800.0
			low_pass_filter.resonance = 1.0
			lowpass_effect_index = AudioServer.get_bus_effect_count(music_bus_index)
			AudioServer.add_bus_effect(music_bus_index, low_pass_filter, lowpass_effect_index)
			print("[Main] Created new lowpass filter at index %d" % lowpass_effect_index)
		
		if phaser_effect_index == -1:
			phaser_filter = AudioEffectPhaser.new()
			phaser_filter.range_min_hz = 600.0
			phaser_filter.range_max_hz = 1200.0
			phaser_filter.rate_hz = 0.5
			phaser_filter.depth = 0.4
			phaser_effect_index = AudioServer.get_bus_effect_count(music_bus_index)
			AudioServer.add_bus_effect(music_bus_index, phaser_filter, phaser_effect_index)
			print("[Main] Created new phaser filter at index %d" % phaser_effect_index)
		
		# Make sure filters start disabled
		AudioServer.set_bus_effect_enabled(music_bus_index, lowpass_effect_index, false)
		AudioServer.set_bus_effect_enabled(music_bus_index, phaser_effect_index, false)
		print("[Main] Audio effects initialized and disabled")
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
	# Debug: Press S to open shop
	if Input.is_key_pressed(KEY_S) and not shop_ui.visible:
		_open_shop(false)
	
	if not current_round_active:
		return
	
	# Update all systems during cooking
	moisture_manager.update_moisture(delta)
	timer_manager.update_timer(delta)
	
	# Check win/loss conditions
	if moisture_manager.check_failure():
		_end_round(false)
	elif timer_manager.check_complete():
		# Stop hum and play beep sequence
		if hum_player and hum_player.playing:
			hum_player.stop()
		await _play_completion_beeps()
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

func _update_power_level_display() -> void:
	if power_lvl_label:
		power_lvl_label.text = "PWR %d" % current_round_number

func _update_round_counter_display() -> void:
	if status_label:
		status_label.text = "Round %d/3" % (rounds_in_current_chunk + 1)

func _update_currency_display(new_amount: int) -> void:
	if currency_label:
		currency_label.text = "Currency: %d" % new_amount
		currency_label.hide()  # Hide for now

func _update_tier_progress_display() -> void:
	if tier_progress_label and progression_manager:
		var current_tier = progression_manager.current_tier
		var unique_recipes = progression_manager.unique_recipes_created
		
		# Hide tier label until first recipe is discovered
		if unique_recipes == 0:
			tier_progress_label.hide()
			return
		else:
			tier_progress_label.show()
		
		# Determine next tier threshold
		var next_threshold: int
		var tier_name: String
		
		if current_tier < 1:
			next_threshold = RecipesData.TIER_1_UNLOCK_THRESHOLD
			tier_name = "Tier 1"
		elif current_tier < 2:
			next_threshold = RecipesData.TIER_2_UNLOCK_THRESHOLD
			tier_name = "Tier 2"
		elif current_tier < 3:
			next_threshold = RecipesData.TIER_3_UNLOCK_THRESHOLD
			tier_name = "Tier 3"
		elif current_tier < 4:
			next_threshold = RecipesData.TIER_4_UNLOCK_THRESHOLD
			tier_name = "Tier 4"
		else:
			tier_progress_label.text = "MAX TIER!"
			return
		
		tier_progress_label.text = "%s: %d/%d" % [tier_name, unique_recipes, next_threshold]

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

	# Initialize camera position at game start
	if main_camera:
		main_camera.position = main_camera_pos
		main_camera.zoom = main_camera_zoom
		print("[Main] Camera initialized at position: %s" % main_camera_pos)

	# Initialize all game systems
	fridge_manager.initialize_starting_deck()
	currency_manager.reset()
	inventory_manager.reset_inventory()
	current_round_number = 1
	discovered_recipes_this_run.clear()  # Reset discovered recipes for new run
	_update_power_level_display()
	_update_currency_display(currency_manager.get_currency())
	
	# Initialize tier progress display
	_update_tier_progress_display()

	# Show hand selector (draw 5 cards for first round of game)
	print("[Main] Starting game - drawing initial 5 cards")
	_show_hand_selector(false)  # after_shop=false, but hand is empty so will draw cards
	print("[Main] _on_game_started complete")

## STATE: HAND_SELECTOR
## after_shop: true = draw 5 new cards, false = draw 1 card to add to hand
func _show_hand_selector(after_shop: bool = false) -> void:
	print("[Main] _show_hand_selector called (after_shop: %s)" % after_shop)
	
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
	
	# Clear ingredient overlays from previous round
	if ingredient_overlay_1:
		ingredient_overlay_1.clear_overlay()
	if ingredient_overlay_2:
		ingredient_overlay_2.clear_overlay()
	
	# Reset moisture bar to grey/empty state (0/0)
	EventBus.moisture_changed.emit(0.0, 0.0, 0.0)
	# Also reset the moisture label text to 0
	if moisture_label:
		moisture_label.text = "0"
	_update_moisture_display()
	
	if hand_selector:
		print("[Main] hand_selector exists, calling show_hand_selection()")
		hand_selector.show_hand_selection(fridge_manager, game_state_manager, progression_manager, after_shop)
		
		# Show instruction label
		if status_label:
			status_label.text = "Drag ingredients here to start!"
			status_label.show()
			
		# Show currency and deck tracker
		if currency_label:
			currency_label.hide()  # Hidden for now
		if tier_progress_label:
			_update_tier_progress_display()
		if deck_tracker:
			deck_tracker.show()
			
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
		moisture_label.text = "%d" % total_moisture
		print("[Main] Updated moisture display: %d" % total_moisture)

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
	
	# Show currency and deck tracker
	if currency_label:
		currency_label.hide()  # Hidden for now
	if tier_progress_label:
		_update_tier_progress_display()
	if deck_tracker:
		deck_tracker.show()

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
	
	# Show currency and deck tracker
	if currency_label:
		currency_label.hide()  # Hidden for now
	if tier_progress_label:
		_update_tier_progress_display()
	if deck_tracker:
		deck_tracker.show()
	
	# Initialize all managers
	print("[Main] Initializing moisture_manager...")
	
	# Scale difficulty based on tier progression
	# Tier 1: 1.0x (base difficulty)
	# Tier 2: 1.6x (60% harder)
	# Tier 3: 2.2x (120% harder)
	var current_tier = progression_manager.current_tier
	var difficulty_multiplier = 1.0
	if current_tier >= 2:
		# Reduced from previous aggressive scaling
		difficulty_multiplier = 1.0 + ((current_tier - 1) * 0.6)
	print("[Main] Current tier: %d, Difficulty multiplier: %.2fx" % [current_tier, difficulty_multiplier])
	
	moisture_manager.setup(ingredient_1, ingredient_2, difficulty_multiplier, inventory_manager)
	
	# The setup() function already emits moisture_changed signal which updates the bar
	print("[Main] Moisture initialized: %.1f/%.1f" % [moisture_manager.current_moisture, moisture_manager.max_moisture])
	
	# Start normal timer
	timer_manager.start_timer(15.0)
	print("[Main] Timer: 15s")
	
	# Play start beep sound
	if beep_player:
		beep_player.play()
		# Start hum sound after 0.05 seconds
		await get_tree().create_timer(0.05).timeout
		if hum_player:
			hum_player.play()
	
	# Play microwave animation
	if microwave_sprite:
		microwave_sprite.play("On")
	
	# Show ingredient overlays
	_update_ingredient_overlays(ingredient_1, ingredient_2)
	
	print("[Main] Round started - current_round_active: %s" % current_round_active)

## Play completion beeps (3 beeps with 0.5 second delay between each)
func _play_completion_beeps() -> void:
	if not beep_player:
		return
	
	for i in range(3):
		beep_player.play()
		if i < 2:  # Don't wait after the last beep
			await get_tree().create_timer(0.5).timeout

## End the current round
func _end_round(success: bool) -> void:
	if not current_round_active:
		return  # Prevent double-ending
	
	current_round_active = false
	timer_manager.stop_timer()
	
	# Stop hum sound if playing
	if hum_player and hum_player.playing:
		hum_player.stop()
	
	# Hide ingredient overlays
	_hide_ingredient_overlays()
	
	# Play microwave Idle animation
	if microwave_sprite:
		microwave_sprite.play("Idle")
	
	var final_moisture = moisture_manager.current_moisture
	last_round_moisture = final_moisture
	
	# Check if it's game over (moisture reached 0)
	if not success and final_moisture <= 0.0:
		print("[Main] GAME OVER - moisture reached 0!")
		_show_game_over()
		return
	
	EventBus.round_completed.emit(success, final_moisture)

func _on_round_completed(success: bool, final_moisture: float) -> void:
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
	
	# Reset the flag at the start
	recipe_created_this_round = false
	last_created_recipe = null
	
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
	
	# Pass current tier to enforce tier restrictions (e.g., 3+ ingredients require Tier 2)
	var current_tier = progression_manager.current_tier
	var combined_ingredient = RecipesData.combine_ingredients(current_round_ingredients, current_tier)
	if combined_ingredient:
		print("[Main] Recipe created successfully: %s" % combined_ingredient.name)
		
		# Mark that recipe was successfully created
		recipe_created_this_round = true
		last_created_recipe = combined_ingredient  # Store for notification
		
		# Track discovery in recipe book
		var display_name = combined_ingredient.get_meta("display_name", combined_ingredient.name)
		if recipe_book_manager:
			print("[Main] Calling recipe_book_manager.discover_recipe() for: %s" % combined_ingredient.name)
			recipe_book_manager.discover_recipe(combined_ingredient.name, display_name)
		else:
			print("[Main] ERROR: recipe_book_manager is null!")
		
		# Generate a unique recipe ID for tracking
		var sorted_names = ingredient_names.duplicate()
		sorted_names.sort()
		var recipe_id = "combo_" + "_".join(sorted_names).replace(" ", "_").replace("+", "_").to_lower()
		
		print("[Main] Recipe ID for tracking: %s" % recipe_id)
		
		# Register in progression manager
		progression_manager.register_recipe(recipe_id, combined_ingredient.name)
		
		# Update tier progress display
		_update_tier_progress_display()
		
		# Consume the original ingredients immediately
		fridge_manager.consume_cards(current_round_ingredients)
		
		# NOTE: Recipe will be added to deck AFTER the reveal animation completes
		# This happens in _show_recipe_notification() after the card slides to the recipe box
		
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
		# Recipe creation failed - could be tier restriction or other error
		print("[Main] Failed to create combo")
		
		# Count total base ingredients (accounting for combined cards)
		var total_base_ingredients = RecipesData.count_total_base_ingredients(current_round_ingredients)
		
		# Check if it was a tier restriction
		if current_tier < 2 and total_base_ingredients > RecipesData.TIER_1_MAX_INGREDIENTS:
			var recipes_needed = RecipesData.TIER_2_UNLOCK_THRESHOLD - progression_manager.unique_recipes_created
			print("[Main] ⚠️ TIER RESTRICTION: Need Tier 2 to create %d-ingredient recipes!" % total_base_ingredients)
			print("[Main] ⚠️ Create %d more unique 2-ingredient recipes to unlock Tier 2" % recipes_needed)
			
			# Show notification to player
			_show_tier_restriction_message(total_base_ingredients, recipes_needed)
		
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
	
	# Only show notification if recipe was actually created this round
	if not recipe_created_this_round or not last_created_recipe:
		print("[Main] No recipe was created this round (blocked or failed), skipping notification")
		return
	
	# Check if a recipe was created this round (must be 2+ ingredients)
	if current_round_ingredients.size() < 2:
		print("[Main] Not enough ingredients for recipe notification. Size: %d" % current_round_ingredients.size())
		return
	
	# Use the internal identity (with + signs) for tracking
	var recipe_identity = last_created_recipe.name
	print("[Main] Recipe identity: %s" % recipe_identity)
	
	# Get the display name for showing to player
	var display_name = last_created_recipe.get_meta("display_name", recipe_identity)
	print("[Main] Recipe display name: %s" % display_name)
	
	# Check if this exact combo has already been discovered this run
	if recipe_identity in discovered_recipes_this_run:
		print("[Main] Recipe '%s' already discovered this run, skipping notification" % recipe_identity)
		return
	
	# Mark as discovered
	discovered_recipes_this_run.append(recipe_identity)
	print("[Main] First discovery of '%s' this run!" % recipe_identity)
	
	# Show the combo recipe in the microwave overlays (on plates with both ingredients)
	_display_combo_in_microwave(recipe_identity)
	
	# Show animated recipe card reveal
	if recipe_card_reveal and last_created_recipe:
		print("[Main] Showing animated recipe card reveal for: %s" % display_name)
		recipe_card_reveal.show_reveal(last_created_recipe)
		await recipe_card_reveal.reveal_completed
		print("[Main] Recipe card reveal completed")
		
		# NOW add the recipe to the deck (after animation shows it going to recipe box)
		print("[Main] Adding recipe to deck after animation: %s" % last_created_recipe.name)
		fridge_manager.add_ingredient_to_deck(last_created_recipe)
		print("[Main] Recipe added to deck successfully")
		
		# Reset moisture label to 0
		if moisture_label:
			moisture_label.text = "0"
			print("[Main] Reset moisture label to 0")
	else:
		print("[Main] ERROR: recipe_card_reveal or last_created_recipe is null!")
		# Fallback wait if reveal doesn't exist
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
	var center_position = (overlay_1_start_pos + overlay_2_start_pos) / 2.0
	print("[Main] Calculated center position: %s" % center_position)
	
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
		ingredient_overlay_1.position = overlay_1_start_pos
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
	print("[Main] Quit requested - returning to main menu scene")
	# Actually change to the main menu scene
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

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
	# Remove low pass filter when resuming
	_remove_pause_music_filter()
	# Pause menu handles unpausing itself

func _on_pause_restart() -> void:
	print("[Main] Restart from pause menu")
	get_tree().paused = false
	# Remove the low pass filter before restarting
	_remove_pause_music_filter()
	get_tree().reload_current_scene()

func _on_pause_exit_to_menu() -> void:
	print("[Main] Exit to menu from pause menu")
	get_tree().paused = false
	# Remove the low pass filter before exiting
	_remove_pause_music_filter()
	# Actually return to the main menu scene
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

## Tier unlock handler
func _on_tier_unlocked(tier_number: int) -> void:
	# Don't show popup for tier 1 (it's the starting tier)
	if tier_number == 1:
		print("[Main] Tier 1 unlocked (skipping popup - starting tier)")
		return
	
	print("[Main] Tier %d unlocked! Showing achievement overlay..." % tier_number)
	if tier_unlock_overlay:
		tier_unlock_overlay.show_tier_unlock(tier_number)

## STATE: SHOP
func _on_shop_opened() -> void:
	game_state_manager.change_state(GameStateManager.GameState.SHOP)
	_hide_all_ui()
	
	# Keep background visible for shop
	if game_background:
		game_background.show()
	
	# Hide radio overlay during shop
	if radio_overlay:
		radio_overlay.hide()
	
	# Apply phaser and low pass filter to music
	_apply_shop_music_filter()
	
	# Increment round number after completing a round
	current_round_number += 1
	_update_power_level_display()
	
	# Populate buttons
	_populate_shop_buttons()
	
	# Reset organic upgrade usage
	organic_used = false
	if make_organic_button:
		make_organic_button.disabled = false
		make_organic_button.text = "Make Organic"
	
	# Smooth camera transition - pan first, then zoom
	if main_camera:
		var tween = create_tween()
		# Pan to shop position first
		tween.tween_property(main_camera, "position", shop_camera_pos, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		# Then zoom in
		tween.tween_property(main_camera, "zoom", shop_camera_zoom, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await tween.finished
	
	# Show shop UI with fade in AFTER camera transition
	if shop_ui:
		shop_ui.modulate.a = 0.0
		shop_ui.show()
		var fade_tween = create_tween()
		fade_tween.tween_property(shop_ui, "modulate:a", 1.0, 0.5)

func _on_shop_closed() -> void:
	# Remove phaser and low pass filter from music
	_remove_shop_music_filter()
	
	# Fade out shop UI
	if shop_ui:
		var fade_tween = create_tween()
		fade_tween.tween_property(shop_ui, "modulate:a", 0.0, 0.3)
		await fade_tween.finished
		shop_ui.hide()
		shop_ui.modulate.a = 1.0  # Reset for next time
		
	# Smooth camera transition back - zoom out first, then pan
	if main_camera:
		var tween = create_tween()
		# Zoom out first
		tween.tween_property(main_camera, "zoom", main_camera_zoom, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		# Then pan back to main position
		tween.tween_property(main_camera, "position", main_camera_pos, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
	
	# Show radio overlay only after camera is back to main scene
	if radio_overlay:
		radio_overlay.show()
	
	# Return to hand selector for next round (draw 5 new cards after shop)
	print("[Main] Shop closed - starting next round with fresh hand")
	_show_hand_selector(true)

## Handle radio button pressed - toggle music on/off
func _on_radio_pressed() -> void:
	music_enabled = !music_enabled
	
	if music_enabled:
		# Turn music back on
		if music_player:
			music_player.play()
		if radio_animation:
			radio_animation.play("radio_throb/throb")
		print("[Main] Music and radio animation enabled")
	else:
		# Turn music off
		if music_player:
			music_player.stop()
		if radio_animation:
			radio_animation.stop()
		print("[Main] Music and radio animation disabled")

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
		# var display_max = int(max_value + bonus)
		moisture_label.text = "%d" % display_current
		moisture_label.show()
	
	print("[Main] Moisture updated: %d (bonus: %d)" % [int(current), int(bonus)])

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
	if round_failed_screen:
		round_failed_screen.hide()
	if shop_ui:
		shop_ui.hide()
	if game_over_screen:
		game_over_screen.hide()
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
	# Hide currency and deck tracker
	if currency_label:
		currency_label.hide()
	if tier_progress_label:
		tier_progress_label.hide()
	if deck_tracker:
		deck_tracker.hide()

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
		print("[Main] Remaining cards in hand will persist through shop")
		
		# Go to shop after 3 rounds
		_open_shop(false)
	else:
		# Continue to next round in chunk (draw cards to fill to 5)
		print("[Main] Continuing to next round in chunk")
		_update_round_counter_display()
		_show_hand_selector(false)

## Open shop (regular or super)
func _open_shop(_is_super: bool) -> void:
	# Just call the regular shop open handler
	_on_shop_opened()
	
	# Reset sprite properties
	if microwave_sprite:
		microwave_sprite.modulate = Color.WHITE
		microwave_sprite.scale = Vector2.ONE

## Populate shop buttons with current ingredients
func _populate_shop_buttons() -> void:
	current_shop_ingredients = shop_manager.get_shop_samples(3)
	samples_taken = 0  # Reset sample counter
	
	var buttons: Array[TextureButton] = [sample_button_1, sample_button_2, sample_button_3]
	
	for i in range(buttons.size()):
		var btn = buttons[i]
		if btn:
			btn.disabled = false # Reset state
			btn.modulate = Color.WHITE # Reset color
			if i < current_shop_ingredients.size():
				var ing = current_shop_ingredients[i]
				# Load the food texture
				var texture_path = "res://Assets/Food/%s.png" % ing.name
				var texture = load(texture_path)
				if texture:
					btn.texture_normal = texture
					print("[Main] Loaded texture for %s" % ing.name)
				else:
					print("[Main] WARNING: Could not load texture: %s" % texture_path)
				# Update the label
				var label = btn.get_node_or_null("Label")
				if label:
					label.text = ing.name
				btn.show()
			else:
				btn.hide()

## Handle shop button hover start - show ingredient card preview
func _on_shop_button_hover_start(index: int) -> void:
	if index >= current_shop_ingredients.size():
		return
	
	var ingredient = current_shop_ingredients[index]
	var buttons: Array[TextureButton] = [sample_button_1, sample_button_2, sample_button_3]
	var btn = buttons[index]
	
	if btn and not btn.disabled:
		_show_hover_card(ingredient, btn)

## Handle shop button hover end - hide ingredient card preview
func _on_shop_button_hover_end() -> void:
	_hide_hover_card()

## Show a hover card above the button
func _show_hover_card(ingredient: IngredientModel, btn: TextureButton) -> void:
	_hide_hover_card()  # Remove any existing hover card
	
	# Instantiate the ingredient card
	var card_scene = preload("res://scenes/ingredient_card.tscn")
	hover_card = card_scene.instantiate()
	
	# Add it to the UI layer
	shop_ui.add_child(hover_card)
	
	# Set up the card with the ingredient data
	await get_tree().process_frame  # Wait for card to be ready
	hover_card.setup(ingredient)
	
	# Position the card centered on the button itself
	var btn_global_pos = btn.global_position
	var btn_center = btn_global_pos + (btn.size / 2)
	var card_size = hover_card.size
	
	# Center the hover card both horizontally and vertically on the button
	hover_card.global_position = Vector2(
		btn_center.x - (card_size.x / 2),
		btn_center.y - (card_size.y / 2)
	)
	
	# Scale the card for preview
	hover_card.scale = Vector2(0.9, 0.9)
	
	# Make the entire card and all its children non-interactive
	hover_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_mouse_filter_recursive(hover_card, Control.MOUSE_FILTER_IGNORE)

## Recursively set mouse filter on all children
func _set_mouse_filter_recursive(node: Node, filter: Control.MouseFilter) -> void:
	if node is Control:
		node.mouse_filter = filter
	for child in node.get_children():
		_set_mouse_filter_recursive(child, filter)

## Hide the hover card
func _hide_hover_card() -> void:
	if hover_card and is_instance_valid(hover_card):
		hover_card.queue_free()
		hover_card = null

## Apply low pass filter to music when entering shop
func _apply_shop_music_filter() -> void:
	if not music_player or music_bus_index < 0:
		print("[Main] Cannot apply shop filter - music_player: %s, bus_index: %d" % [music_player != null, music_bus_index])
		return
	
	print("[Main] Applying shop music filters...")
	print("[Main] Lowpass index: %d, Phaser index: %d" % [lowpass_effect_index, phaser_effect_index])
	
	# Enable the effects
	if lowpass_effect_index >= 0:
		AudioServer.set_bus_effect_enabled(music_bus_index, lowpass_effect_index, true)
		print("[Main] Enabled lowpass filter")
	
	if phaser_effect_index >= 0:
		AudioServer.set_bus_effect_enabled(music_bus_index, phaser_effect_index, true)
		print("[Main] Enabled phaser filter")
	
	# Verify they're enabled
	if lowpass_effect_index >= 0:
		var is_enabled = AudioServer.is_bus_effect_enabled(music_bus_index, lowpass_effect_index)
		print("[Main] Lowpass enabled: %s" % is_enabled)
	if phaser_effect_index >= 0:
		var is_enabled = AudioServer.is_bus_effect_enabled(music_bus_index, phaser_effect_index)
		print("[Main] Phaser enabled: %s" % is_enabled)

## Remove low pass filter from music when leaving shop
func _remove_shop_music_filter() -> void:
	if not music_player or music_bus_index < 0:
		return
	
	print("[Main] Removing shop music filters...")
	
	# Disable the effects instead of removing them
	if lowpass_effect_index >= 0:
		AudioServer.set_bus_effect_enabled(music_bus_index, lowpass_effect_index, false)
		print("[Main] Disabled lowpass filter")
	
	if phaser_effect_index >= 0:
		AudioServer.set_bus_effect_enabled(music_bus_index, phaser_effect_index, false)
		print("[Main] Disabled phaser filter")

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

## Show a tier restriction message when player tries to combine 3+ ingredients before Tier 2
func _show_tier_restriction_message(ingredient_count: int, recipes_needed: int) -> void:
	# Create a simple popup dialog
	var popup = AcceptDialog.new()
	popup.dialog_text = "⚠️ LOCKED: %d-Ingredient Recipes\n\nYou need Tier 2 to create recipes with %d or more ingredients.\n\nCreate %d more unique 2-ingredient recipes to unlock!" % [ingredient_count, ingredient_count, recipes_needed]
	add_child(popup)
	popup.popup_centered()

## Handle sample selection
func _on_sample_selected(index: int) -> void:
	if index < 0 or index >= current_shop_ingredients.size():
		return
	
	# Check if sample limit reached
	if samples_taken >= MAX_SAMPLES:
		print("[Main] Cannot take more samples - limit reached (%d/%d)" % [samples_taken, MAX_SAMPLES])
		return
	
	var buttons: Array[TextureButton] = [sample_button_1, sample_button_2, sample_button_3]
	var btn = buttons[index]
	
	# Check if already taken
	if btn and btn.disabled:
		return
		
	var selected_ingredient = current_shop_ingredients[index]
	print("[Main] Selected sample: %s" % selected_ingredient.name)
	
	# Clear hover card immediately
	_hide_hover_card()
	
	# Disable button and grey it out to show it's taken
	if btn:
		btn.disabled = true
		btn.modulate = Color(0.4, 0.4, 0.4, 0.7) # Grey out
		var label = btn.get_node_or_null("Label")
		if label:
			label.text = "TAKEN"
	
	# Get button position for animation origin
	var button_pos = btn.global_position + (btn.size / 2) if btn else get_viewport().get_visible_rect().size / 2.0
	
	# Show spring-in and slide animation for the sample
	await _show_sample_animation(selected_ingredient, button_pos)
	
	# Add to persistent hand (will be in next hand draw)
	fridge_manager.add_to_persistent_hand(selected_ingredient)
	
	# Increment counter
	samples_taken += 1
	print("[Main] Samples taken: %d/%d" % [samples_taken, MAX_SAMPLES])
	
	# If limit reached, disable all remaining buttons
	if samples_taken >= MAX_SAMPLES:
		for i in range(buttons.size()):
			var b = buttons[i]
			if b and not b.disabled:
				b.disabled = true
				b.modulate = Color(0.5, 0.5, 0.5, 0.5)
				var lbl = b.get_node_or_null("Label")
				if lbl:
					lbl.text = "UNAVAILABLE"

## Manual loop fallback for HTML5
func _on_music_finished() -> void:
	print("[Main] Music finished - restarting loop manually")
	if music_player:
		music_player.play()

## Show sample animation - spring in and slide to recipe box (same as organic)
func _show_sample_animation(ingredient: IngredientModel, start_pos: Vector2) -> void:
	print("[Main] Showing sample animation for: %s" % ingredient.name)
	
	# Create ingredient card for animation
	var card_scene = preload("res://scenes/ingredient_card.tscn")
	var card = card_scene.instantiate()
	
	# Add to UI layer so it's visible above everything
	var ui_layer = $UI
	if ui_layer:
		ui_layer.add_child(card)
	else:
		add_child(card)
	
	# Wait for card to be ready
	await get_tree().process_frame
	card.setup(ingredient)
	
	# Start position - from the ingredient button
	card.position = start_pos - (card.size / 2.0)
	card.z_index = 1000
	
	# Phase 1: Spring in (scale from 0 to 1 with bounce)
	card.scale = Vector2.ZERO
	card.modulate.a = 1.0
	
	var spring_tween = create_tween()
	spring_tween.set_ease(Tween.EASE_OUT)
	spring_tween.set_trans(Tween.TRANS_BACK)
	spring_tween.tween_property(card, "scale", Vector2.ONE, 0.5)
	
	await spring_tween.finished
	print("[Main] Sample spring animation complete")
	
	# Hold for a moment
	await get_tree().create_timer(0.5).timeout
	
	# Phase 2: Slide to recipe box (deck tracker position)
	var recipe_box_position = deck_tracker.global_position + (deck_tracker.size / 2) if deck_tracker else Vector2(784, 180)
	
	var slide_tween = create_tween()
	slide_tween.set_parallel(true)
	slide_tween.set_ease(Tween.EASE_IN)
	slide_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Slide to the recipe box
	slide_tween.tween_property(card, "position", recipe_box_position - (card.size / 2), 0.8)
	
	# Scale down as it approaches
	slide_tween.tween_property(card, "scale", Vector2(0.3, 0.3), 0.8)
	
	# Fade out
	slide_tween.tween_property(card, "modulate:a", 0.0, 0.8)
	
	await slide_tween.finished
	print("[Main] Sample slide animation complete")
	
	# Clean up
	if card and is_instance_valid(card):
		card.queue_free()
	
	print("[Main] Sample animation complete")

## Handle Make Organic button pressed - open card selector to choose card
func _on_make_organic_pressed() -> void:
	print("[Main] Make Organic button pressed")
	
	# Check if already used
	if organic_used:
		print("[Main] Make Organic already used this shop phase")
		return
	
	# Get all cards from deck and discard pile
	var all_cards = fridge_manager.deck + fridge_manager.discard_pile
	
	if all_cards.is_empty():
		print("[Main] No cards in deck to upgrade!")
		return
	
	# Generate random upgrade stats
	var stats = ["water", "heat_resistance", "volatility"]
	var chosen_stat = stats[randi() % stats.size()]
	
	# Generate balanced random amount based on the stat
	var amount: int
	match chosen_stat:
		"water":
			# Water: +5 to +15 (more water is good)
			amount = randi_range(5, 15)
		"heat_resistance":
			# Heat Resistance: +5 to +15 (more resistance is good)
			amount = randi_range(5, 15)
		"volatility":
			# Volatility: -3 to -10 (lower volatility is good, but cap the reduction)
			amount = -randi_range(3, 10)
	
	print("[Main] Generated organic upgrade: %s %+d" % [chosen_stat, amount])
	
	# Store the upgrade data
	pending_organic_upgrade = {chosen_stat: amount}
	
	# Open card selector to let player choose which card to upgrade
	if card_selector:
		card_selector.open_with_upgrade(pending_organic_upgrade, fridge_manager)
		print("[Main] Opened card selector for organic upgrade")

## Handle card selected for organic upgrade
func _on_card_selected_for_organic(ingredient_name: String) -> void:
	print("[Main] Card selected for organic upgrade: %s" % ingredient_name)
	
	if pending_organic_upgrade.is_empty():
		print("[Main] Error: No pending organic upgrade")
		return
	
	# Apply upgrade to the selected card
	fridge_manager.upgrade_ingredient_stats(ingredient_name, pending_organic_upgrade)
	
	# Mark as used and disable button
	organic_used = true
	if make_organic_button:
		make_organic_button.disabled = true
		make_organic_button.text = "USED"
	
	# Get the upgraded ingredient to show animation
	var upgraded_ingredient: IngredientModel = null
	var all_cards = fridge_manager.deck + fridge_manager.discard_pile
	for card in all_cards:
		if card.name == ingredient_name or card.name == "Organic " + ingredient_name:
			upgraded_ingredient = card.duplicate()
			break
	
	if upgraded_ingredient:
		# Hide card selector before animation
		if card_selector:
			card_selector.hide()
		
		# Get center of viewport as fallback (card selector is full screen)
		var start_pos = get_viewport().get_visible_rect().size / 2.0
		
		# Show spring-in and slide animation
		await _show_organic_upgrade_animation(upgraded_ingredient, start_pos)
	
	# Clear pending upgrade
	pending_organic_upgrade.clear()
	
## Show organic upgrade animation - spring in and slide to recipe box
func _show_organic_upgrade_animation(ingredient: IngredientModel, start_pos: Vector2) -> void:
	print("[Main] Showing organic upgrade animation for: %s" % ingredient.name)
	
	# Create ingredient card for animation
	var card_scene = preload("res://scenes/ingredient_card.tscn")
	var card = card_scene.instantiate()
	
	# Add to UI layer so it's visible above everything
	var ui_layer = $UI
	if ui_layer:
		ui_layer.add_child(card)
	else:
		add_child(card)
	
	# Wait for card to be ready
	await get_tree().process_frame
	card.setup(ingredient)
	
	# Start position - from the selected card in card selector
	card.position = start_pos - (card.size / 2.0)
	card.z_index = 1000
	
	# Phase 1: Spring in (scale from 0 to 1 with bounce)
	card.scale = Vector2.ZERO
	card.modulate.a = 1.0
	
	var spring_tween = create_tween()
	spring_tween.set_ease(Tween.EASE_OUT)
	spring_tween.set_trans(Tween.TRANS_BACK)
	spring_tween.tween_property(card, "scale", Vector2.ONE, 0.5)
	
	await spring_tween.finished
	print("[Main] Spring animation complete")
	
	# Phase 2: Animate the star on the upgraded stat, then hold for 4 seconds
	await _animate_upgrade_star(card, pending_organic_upgrade)
	await get_tree().create_timer(4.0).timeout
	
	# Phase 3: Slide to recipe box (deck tracker position)
	var recipe_box_position = deck_tracker.global_position + (deck_tracker.size / 2) if deck_tracker else Vector2(784, 180)
	
	var slide_tween = create_tween()
	slide_tween.set_parallel(true)
	slide_tween.set_ease(Tween.EASE_IN)
	slide_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Slide to the recipe box
	slide_tween.tween_property(card, "position", recipe_box_position - (card.size / 2), 0.8)
	
	# Scale down as it approaches
	slide_tween.tween_property(card, "scale", Vector2(0.3, 0.3), 0.8)
	
	# Fade out
	slide_tween.tween_property(card, "modulate:a", 0.0, 0.8)
	
	await slide_tween.finished
	print("[Main] Slide animation complete")
	
	# Clean up
	if card and is_instance_valid(card):
		card.queue_free()
	
	print("[Main] Organic upgrade animation complete")

## Animate the star on upgraded stat - scales from 3x down to normal size
func _animate_upgrade_star(card: Control, upgrade_data: Dictionary) -> void:
	print("[Main] Animating upgrade star")
	
	# Determine which stat was upgraded
	var target_label_name = ""
	
	for key in upgrade_data.keys():
		match key:
			"water":
				target_label_name = "WaterLabel"
			"heat_resistance":
				target_label_name = "ResistLabel"
			"volatility":
				target_label_name = "VolatilityLabel"
	
	# Find the specific stat label
	var stats_container = card.get_node_or_null("CardPanel/VBoxContainer/StatsContainer")
	var target_label = stats_container.get_node_or_null(target_label_name) if stats_container else null
	
	if not target_label:
		print("[Main] Could not find target stat label: %s" % target_label_name)
		return
	
	# Animate the label scale from 3x to 1x
	target_label.pivot_offset = target_label.size / 2.0  # Scale from center
	target_label.scale = Vector2(3.0, 3.0)
	
	var star_tween = create_tween()
	star_tween.set_ease(Tween.EASE_OUT)
	star_tween.set_trans(Tween.TRANS_BACK)
	star_tween.tween_property(target_label, "scale", Vector2.ONE, 2.0)
	
	await star_tween.finished
	print("[Main] Star animation complete")

## Handle organic upgrade cancelled
func _on_organic_upgrade_cancelled() -> void:
	print("[Main] Organic upgrade cancelled")
	pending_organic_upgrade.clear()

## Show organic upgrade message popup
func _show_organic_message(message: String) -> void:
	var popup = AcceptDialog.new()
	popup.dialog_text = message
	popup.ok_button_text = "Nice!"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())
	popup.close_requested.connect(func(): popup.queue_free())
