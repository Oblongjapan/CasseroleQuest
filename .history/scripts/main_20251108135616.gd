extends Node

## Main game controller - orchestrates round flow and state

@onready var moisture_manager: MoistureManager = $CookRound/MoistureManager
@onready var timer_manager: TimerManager = $CookRound/TimerManager
@onready var item_manager: ActiveItemManager = $CookRound/ItemManager
@onready var ingredient_selector: Panel = $UI/IngredientSelector
@onready var draft_selector: Panel = $UI/DraftSelector
@onready var status_label: Label = $UI/StatusLabel
@onready var item_button_1: Button = $UI/ActiveItemsContainer/ActiveItemButton_1
@onready var item_button_2: Button = $UI/ActiveItemsContainer/ActiveItemButton_2
@onready var item_button_3: Button = $UI/ActiveItemsContainer/ActiveItemButton_3
@onready var relic_display: HBoxContainer = $UI/RelicDisplay
@onready var speed_button: Button = $UI/SpeedButton

var current_round_active: bool = false
var current_round_number: int = 1
var difficulty_multiplier: float = 1.0
var inventory_manager: InventoryManager
var has_completed_initial_draft: bool = false
var game_speed: float = 1.0

func _ready():
	# Create inventory manager
	inventory_manager = InventoryManager.new()
	add_child(inventory_manager)
	
	# Connect inventory updates
	inventory_manager.inventory_updated.connect(_on_inventory_updated)
	
	# Setup relic display
	if relic_display:
		relic_display.setup(inventory_manager)
	
	# Setup speed button
	if speed_button:
		speed_button.pressed.connect(_toggle_speed)
		speed_button.text = "Speed: 1x"
	
	EventBus.round_started.connect(_on_round_started)
	EventBus.round_completed.connect(_on_round_completed)
	EventBus.draft_completed.connect(_on_draft_completed)
	
	# Start with NO items - show initial draft to pick starting ingredients
	status_label.text = "Welcome! Choose your starting ingredients..."
	if draft_selector:
		draft_selector.show_draft(inventory_manager, true)

func _process(delta: float) -> void:
	if not current_round_active:
		return
	
	# Update all systems
	moisture_manager.update_moisture(delta)
	timer_manager.update_timer(delta)
	item_manager.update_cooldowns(delta)
	
	# Check win/loss conditions
	if moisture_manager.check_failure():
		_end_round(false)
	elif timer_manager.check_complete():
		_end_round(true)

## Called when ingredients are selected and round begins
func _on_round_started(ingredient_1: IngredientModel, ingredient_2: IngredientModel) -> void:
	current_round_active = true
	status_label.text = "Round %d - Cooking..." % current_round_number
	
	# Calculate difficulty scaling (with relic modifiers)
	_calculate_difficulty()
	
	# Initialize all managers with difficulty scaling and relic effects
	moisture_manager.setup(ingredient_1, ingredient_2, difficulty_multiplier, inventory_manager)
	# Keep cook time constant; only moisture drain scales with difficulty
	timer_manager.start_timer(15.0)
	
	# Setup active items from inventory with cooldown reduction
	item_manager.setup(inventory_manager.get_active_items(), inventory_manager.get_total_cooldown_reduction())
	item_manager.reset_cooldowns()
	
	# Update UI buttons to show owned items
	_update_item_buttons()

## End the current round
func _end_round(success: bool) -> void:
	if not current_round_active:
		return  # Prevent double-ending
	
	current_round_active = false
	timer_manager.stop_timer()
	
	var final_moisture = moisture_manager.current_moisture
	EventBus.round_completed.emit(success, final_moisture)
	
	# Update status display
	if success:
		status_label.text = "Round %d Complete! Moisture: %.0f" % [current_round_number, final_moisture]
		current_round_number += 1  # Advance to next round on success
		
		# Show draft selector for reward picks after delay
		await get_tree().create_timer(2.0).timeout
		status_label.text = "Choose your rewards!"
		if draft_selector:
			draft_selector.show_draft(inventory_manager, false)
	else:
		status_label.text = "Round %d Failed! Food dried out!" % current_round_number
		current_round_number = 1  # Reset to round 1 on failure
		inventory_manager.reset_inventory()  # Reset inventory on failure
		has_completed_initial_draft = false
		
		# Show initial draft again after delay
		await get_tree().create_timer(2.0).timeout
		status_label.text = "Game Over! Starting fresh..."
		if draft_selector:
			draft_selector.show_draft(inventory_manager, true)

## Handle round completion (for stats tracking, etc.)
func _on_round_completed(success: bool, final_moisture: float) -> void:
	print("Round ended - Success: %s, Final Moisture: %.1f" % [success, final_moisture])

## Calculate difficulty multiplier based on round number
func _calculate_difficulty() -> void:
	# Difficulty increases by 10% each round
	# Round 1: 1.0x, Round 2: 1.1x, Round 3: 1.2x, etc.
	var base_scaling = 0.1
	
	# Apply relic modifier to slow difficulty scaling
	var scaling_reduction = inventory_manager.get_difficulty_scaling_reduction()
	var adjusted_scaling = base_scaling * (1.0 - scaling_reduction)
	
	difficulty_multiplier = 1.0 + (current_round_number - 1) * adjusted_scaling

## Handle draft completion - show ingredient selector
func _on_draft_completed() -> void:
	if not has_completed_initial_draft:
		has_completed_initial_draft = true
		status_label.text = "Draft complete! Now select ingredients to cook..."
	else:
		status_label.text = "Round %d - Select ingredients to start!" % current_round_number
	
	# Show ingredient selector with owned ingredients
	if ingredient_selector:
		ingredient_selector.show_selector_from_inventory(inventory_manager)

## Update status label with round info
func _update_status_label() -> void:
	if current_round_number == 1:
		status_label.text = "Round 1 - Select ingredients to start!"
	else:
		status_label.text = "Round %d - Ready for next challenge!" % current_round_number

## Called from ActiveItemButtonUI when button pressed
func try_use_item(item_index: int) -> void:
	if current_round_active:
		item_manager.use_item(item_index, moisture_manager)

## Update item button UI to show owned items
func _update_item_buttons() -> void:
	var owned_items = inventory_manager.get_active_items()
	var buttons = [item_button_1, item_button_2, item_button_3]
	
	# Update each button
	for i in range(buttons.size()):
		if i < owned_items.size():
			buttons[i].set_item(owned_items[i], i)
		else:
			buttons[i].hide()

## Called when inventory changes (items added/removed)
func _on_inventory_updated() -> void:
	_update_item_buttons()

## Toggle game speed between 1x and 3x
func _toggle_speed() -> void:
	if game_speed == 1.0:
		game_speed = 3.0
		speed_button.text = "Speed: 3x"
	else:
		game_speed = 1.0
		speed_button.text = "Speed: 1x"
	
	Engine.time_scale = game_speed
