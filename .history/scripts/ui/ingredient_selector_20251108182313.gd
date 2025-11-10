extends Panel

## UI controller for ingredient selection screen

@onready var ingredient_grid: GridContainer = $VBoxContainer/IngredientGrid
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var drain_preview_label: Label = $VBoxContainer/DrainPreviewLabel

var available_ingredients: Array[IngredientModel] = []
var selected_ingredients: Array[IngredientModel] = []
const MAX_SELECTIONS: int = 2

var current_inventory: InventoryManager  # Store reference to remove ingredients later

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	hide()

## Show selector with random ingredient pool
func show_selector() -> void:
	selected_ingredients.clear()
	available_ingredients = IngredientsData.get_random_ingredient_pool(6)
	_populate_ingredients()
	show()
	_update_start_button()

## Show selector with ingredients from inventory
func show_selector_from_inventory(inventory: InventoryManager) -> void:
	current_inventory = inventory
	selected_ingredients.clear()
	available_ingredients = inventory.get_ingredients()
	_populate_ingredients()
	show()
	_update_start_button()

## Create ingredient cards in grid
func _populate_ingredients() -> void:
	# Clear existing cards
	for child in ingredient_grid.get_children():
		child.queue_free()
	
	# Create new cards
	for ingredient in available_ingredients:
		var card = _create_ingredient_card(ingredient)
		ingredient_grid.add_child(card)

## Create a single ingredient card button
func _create_ingredient_card(ingredient: IngredientModel) -> Button:
	var card = Button.new()
	card.custom_minimum_size = Vector2(150, 120)
	card.text = "%s\n\n%s" % [ingredient.name, ingredient.get_stats_description()]
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Connect pressed signal
	card.pressed.connect(_on_ingredient_card_pressed.bind(ingredient, card))
	
	return card

## Handle ingredient card selection
func _on_ingredient_card_pressed(ingredient: IngredientModel, card: Button) -> void:
	if ingredient in selected_ingredients:
		# Deselect
		selected_ingredients.erase(ingredient)
		card.modulate = Color.WHITE
		EventBus.ingredient_deselected.emit(ingredient)
	else:
		# Select (if under limit)
		if selected_ingredients.size() < MAX_SELECTIONS:
			selected_ingredients.append(ingredient)
			card.modulate = Color.GREEN
			EventBus.ingredient_selected.emit(ingredient)
	
	_update_start_button()

## Enable/disable start button based on selection
func _update_start_button() -> void:
	# Can start with 1 or 2 ingredients
	start_button.disabled = selected_ingredients.size() == 0
	
	if selected_ingredients.size() == 0:
		start_button.text = "Select 1-2 Ingredients"
		if drain_preview_label:
			drain_preview_label.text = ""
	elif selected_ingredients.size() == 1:
		start_button.text = "Start Cooking! (or select 1 more)"
		_update_drain_preview()
	else:
		start_button.text = "Start Cooking!"
		_update_drain_preview()

## Calculate and display the drain rate preview
func _update_drain_preview() -> void:
	if not drain_preview_label:
		return
	
	# Get the ingredients that will be used
	var ing1 = selected_ingredients[0]
	var ing2 = selected_ingredients[1] if selected_ingredients.size() >= 2 else selected_ingredients[0]
	
	# Calculate combined stats (same logic as moisture_manager)
	var total_water = ing1.water_content + ing2.water_content
	var total_heat_resist = ing1.heat_resistance + ing2.heat_resistance
	var total_density = ing1.density + ing2.density
	var total_spice = ing1.spice_level + ing2.spice_level
	
	# Calculate drain rate (spice multiplier is 0.15 for combined ingredients)
	var base_drain = 5.0
	var drain = base_drain + (total_spice * 0.15) - (total_heat_resist * 0.01) - (total_density * 0.008)
	var drain_rate = maxf(drain, 3.0)
	
	# Apply mastery bonus if same ingredient twice
	var mastery_text = ""
	if ing1 == ing2:
		drain_rate *= 0.95
		mastery_text = " (5% Mastery Bonus!)"
	
	drain_preview_label.text = "Moisture Drain Rate: %.2f/sec%s" % [drain_rate, mastery_text]

## Validate and start round
func _on_start_pressed() -> void:
	if selected_ingredients.size() >= 1:
		# If only 1 ingredient selected, use it twice
		var ing1 = selected_ingredients[0]
		var ing2 = selected_ingredients[1] if selected_ingredients.size() >= 2 else selected_ingredients[0]
		
		# Remove used ingredients from inventory (consumable)
		if current_inventory:
			current_inventory.remove_ingredients(ing1, ing2)
		
		EventBus.selection_confirmed.emit(ing1, ing2)
		EventBus.round_started.emit(ing1, ing2)
		hide()
