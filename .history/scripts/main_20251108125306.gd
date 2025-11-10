extends Node

## Main game controller - orchestrates round flow and state

@onready var moisture_manager: MoistureManager = $CookRound/MoistureManager
@ontml:parameter>
@onready var timer_manager: TimerManager = $CookRound/TimerManager
@onready var item_manager: ActiveItemManager = $CookRound/ItemManager
@onready var ingredient_selector: Panel = $UI/IngredientSelector
@onready var draft_selector: Panel = $UI/DraftSelector
@onready var status_label: Label = $UI/StatusLabel

var current_round_active: bool = false
var current_round_number: int = 1
var difficulty_multiplier: float = 1.0
var inventory_manager: InventoryManager
var has_completed_initial_draft: bool = false

func _ready():
	# Create inventory manager
	inventory_manager = InventoryManager.new()
	add_child(inventory_manager)
	
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
	else:
		status_label.text = "Round %d Failed! Food dried out!" % current_round_number
		current_round_number = 1  # Reset to round 1 on failure
	
	# Show restart option after delay
	await get_tree().create_timer(2.0).timeout
	if ingredient_selector:
		ingredient_selector.show_selector()
	_update_status_label()

## Handle round completion (for stats tracking, etc.)
func _on_round_completed(success: bool, final_moisture: float) -> void:
	print("Round ended - Success: %s, Final Moisture: %.1f" % [success, final_moisture])

## Calculate difficulty multiplier based on round number
func _calculate_difficulty() -> void:
	# Difficulty increases by 10% each round
	# Round 1: 1.0x, Round 2: 1.1x, Round 3: 1.2x, etc.
	difficulty_multiplier = 1.0 + (current_round_number - 1) * 0.1

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
