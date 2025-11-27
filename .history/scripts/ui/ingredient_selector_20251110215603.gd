extends Panel

## UI controller for ingredient selection screen (2-card preview from fridge)

@onready var ingredient_grid: GridContainer = $VBoxContainer/IngredientGrid
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var drain_preview_label: Label = $VBoxContainer/DrainPreviewLabel
@onready var currency_label: Label = $VBoxContainer/CurrencyLabel
@onready var round_label: Label = $VBoxContainer/RoundLabel

var drawn_ingredients: Array[IngredientModel] = []  # Exactly 2 cards from fridge
var fridge_manager: FridgeManager
var currency_manager: CurrencyManager
var current_round: int = 1

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	hide()

## Show selector with 2 cards drawn from fridge
func show_selector(fridge: FridgeManager, currency: CurrencyManager, round_number: int) -> void:
	fridge_manager = fridge
	currency_manager = currency
	current_round = round_number
	
	# Draw 2 cards from fridge
	drawn_ingredients = fridge_manager.draw_cards(2)
	
	# Update labels
	title_label.text = "Round %d" % current_round
	round_label.text = "Select 2 Ingredients to Cook"
	_update_currency_display()
	
	# Populate ingredient cards
	_populate_ingredients()
	_update_drain_preview()
	
	show()

## Create ingredient cards in grid
func _populate_ingredients() -> void:
	# Clear existing cards
	for child in ingredient_grid.get_children():
		child.queue_free()
	
	# Create cards for the 2 drawn ingredients
	for ingredient in drawn_ingredients:
		var card = _create_ingredient_card(ingredient)
		ingredient_grid.add_child(card)

## Create a single ingredient card (display only, no selection)
func _create_ingredient_card(ingredient: IngredientModel) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 150)
	
	var vbox = VBoxContainer.new()
	
	# Name label
	var name_label = Label.new()
	name_label.text = ingredient.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)
	
	# Upgrade info if any
	var upgrade_desc = fridge_manager.get_upgrade_description(ingredient.name)
	if not upgrade_desc.is_empty():
		var upgrade_label = Label.new()
		upgrade_label.text = upgrade_desc
		upgrade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		upgrade_label.modulate = Color.GREEN
		vbox.add_child(upgrade_label)
	
	# Stats label
	var stats_label = Label.new()
	stats_label.text = ingredient.get_stats_description()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)
	
	# Selection indicator
	var selected_label = Label.new()
	selected_label.text = "✓ SELECTED"
	selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_label.modulate = Color.GREEN
	vbox.add_child(selected_label)
	
	card.add_child(vbox)
	return card

## Calculate and display the drain rate preview
func _update_drain_preview() -> void:
	if not drain_preview_label or drawn_ingredients.size() < 2:
		return
	
	var ing1 = drawn_ingredients[0]
	var ing2 = drawn_ingredients[1]
	
	# Calculate preview stats
	var combined_water = ing1.water_content + ing2.water_content
	var worst_spice = max(ing1.volatility, ing2.volatility)
	var best_heat = max(ing1.heat_resistance, ing2.heat_resistance)
	var estimated_drain = 5.0 + (worst_spice * 0.3) - (best_heat * 0.25)
	estimated_drain = max(0.5, estimated_drain)
	
	drain_preview_label.text = "Starting Moisture: %d\nEstimated Drain: ~%.1f/sec" % [
		combined_water,
		estimated_drain
	]

## Update currency display
func _update_currency_display() -> void:
	if currency_label:
		currency_label.text = "Currency: %d" % currency_manager.get_currency()

## Handle start cooking button
func _on_start_pressed() -> void:
	if drawn_ingredients.size() < 2:
		print("[IngredientSelector] Error: Need exactly 2 ingredients!")
		return
	
	# Discard these cards from the fridge
	fridge_manager.discard_cards(drawn_ingredients)
	
	# Emit round started signal
	EventBus.round_started.emit(drawn_ingredients[0], drawn_ingredients[1])
	hide()
