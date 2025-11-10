extends Node

## Main game controller - orchestrates round flow and state

@onready var moisture_manager: MoistureManager = $CookRound/MoistureManager
@onready var timer_manager: TimerManager = $CookRound/TimerManager
@onready var item_manager: ActiveItemManager = $CookRound/ItemManager
@onready var ingredient_selector: Panel = $UI/IngredientSelector
@onready var status_label: Label = $UI/StatusLabel

var current_round_active: bool = false
var current_round_number: int = 1
var difficulty_multiplier: float = 1.0

func _ready():
	EventBus.round_started.connect(_on_round_started)
	EventBus.round_completed.connect(_on_round_completed)
	
	# Setup active items
	item_manager.setup(ActiveItemsData.get_all_items())
	
	# Start with ingredient selection
	if ingredient_selector:
		ingredient_selector.show_selector()
	
	_update_status_label()

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
	status_label.text = "Cooking..."
	
	# Initialize all managers
	moisture_manager.setup(ingredient_1, ingredient_2)
	timer_manager.start_timer(15.0)
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
		status_label.text = "Round Complete! Moisture: %.0f" % final_moisture
	else:
		status_label.text = "Round Failed! Food dried out!"
	
	# Show restart option after delay
	await get_tree().create_timer(2.0).timeout
	if ingredient_selector:
		ingredient_selector.show_selector()
	status_label.text = "Select ingredients to start!"

## Handle round completion (for stats tracking, etc.)
func _on_round_completed(success: bool, final_moisture: float) -> void:
	print("Round ended - Success: %s, Final Moisture: %.1f" % [success, final_moisture])

## Called from ActiveItemButtonUI when button pressed
func try_use_item(item_index: int) -> void:
	if current_round_active:
		item_manager.use_item(item_index, moisture_manager)
