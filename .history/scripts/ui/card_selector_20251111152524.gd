extends Control
class_name CardSelector

## Visual decklist for choosing which card to upgrade
## Opens when player purchases an upgrade in the shop

signal card_selected(ingredient_name: String)
signal selection_cancelled

@onready var card_grid: GridContainer = $Panel/VBox/ScrollContainer/CardGrid
@onready var upgrade_desc_label: Label = $Panel/VBox/Header/UpgradeDesc
@onready var cancel_button: Button = $Panel/VBox/ButtonBar/CancelButton

var current_upgrade: Dictionary = {}
var fridge_manager: FridgeManager

func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed)
	hide()

## Open the card selector with a specific upgrade
func open_with_upgrade(upgrade_data: Dictionary, fridge_mgr: FridgeManager) -> void:
	current_upgrade = upgrade_data
	fridge_manager = fridge_mgr
	
	# Update description label
	var upgrade_text = _format_upgrade_text(upgrade_data)
	upgrade_desc_label.text = "Upgrade: " + upgrade_text
	
	# Populate grid with cards from deck
	_populate_card_grid()
	
	show()

## Format upgrade data into readable text
func _format_upgrade_text(upgrade_data: Dictionary) -> String:
	var parts: Array[String] = []
	
	if upgrade_data.has("water") and upgrade_data.water != 0:
		var sign = "+" if upgrade_data.water > 0 else ""
		parts.append("%s%d Water" % [sign, upgrade_data.water])
	
	if upgrade_data.has("heat_resistance") and upgrade_data.heat_resistance != 0:
		var sign = "+" if upgrade_data.heat_resistance > 0 else ""
		parts.append("%s%d Heat Resistance" % [sign, upgrade_data.heat_resistance])
	
	if upgrade_data.has("volatility") and upgrade_data.volatility != 0:
		var sign = "+" if upgrade_data.volatility > 0 else ""
		parts.append("%s%d Volatility" % [sign, upgrade_data.volatility])
	
	return ", ".join(parts) if parts.size() > 0 else "Unknown"

## Populate the grid with cards from player's deck
func _populate_card_grid() -> void:
	# Clear existing cards
	for child in card_grid.get_children():
		child.queue_free()
	
	if not fridge_manager:
		print("[CardSelector] Error: No fridge manager provided")
		return
	
	# Get all cards from deck and discard pile
	var all_cards = fridge_manager.deck + fridge_manager.discard_pile
	
	if all_cards.is_empty():
		var label = Label.new()
		label.text = "No cards in deck!"
		card_grid.add_child(label)
		return
	
	# Create a card display for EACH card in the deck (including duplicates)
	for ingredient in all_cards:
		var card = _create_card_for_ingredient(ingredient)
		card_grid.add_child(card)

## Create an ingredient card instance (same as hand selector)
func _create_card_for_ingredient(ingredient: IngredientModel) -> Control:
	# Load and instantiate the card scene
	var card_scene = preload("res://scenes/ingredient_card.tscn")
	var card: IngredientCard = card_scene.instantiate()
	
	# Get upgrade description if any
	var upgrade_desc = fridge_manager.get_upgrade_description(ingredient.name)
	
	# Store data for setup after _ready
	card.set_meta("pending_ingredient", ingredient)
	card.set_meta("pending_upgrade", upgrade_desc)
	
	# Wrap card in a container with preview label
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(150, 250)
	
	# Add the card
	container.add_child(card)
	
	# Add upgrade preview below the card
	var preview_label = Label.new()
	preview_label.text = "After Upgrade:\n" + _get_upgrade_preview(ingredient)
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.add_theme_color_override("font_color", Color.GREEN)
	preview_label.add_theme_font_size_override("font_size", 10)
	container.add_child(preview_label)
	
	# Make card clickable
	card.gui_input.connect(_on_card_clicked.bind(ingredient.name))
	
	return container

## Handle card click
func _on_card_clicked(event: InputEvent, ingredient_name: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_card_selected(ingredient_name)

## Get preview of stats after upgrade
func _get_upgrade_preview(ingredient: IngredientModel) -> String:
	var new_water = ingredient.water_content
	var new_heat = ingredient.heat_resistance
	var new_vol = ingredient.volatility
	
	if current_upgrade.has("water"):
		new_water = clampi(new_water + current_upgrade.water, 0, 100)
	if current_upgrade.has("heat_resistance"):
		new_heat = clampi(new_heat + current_upgrade.heat_resistance, 0, 100)
	if current_upgrade.has("volatility"):
		new_vol = clampi(new_vol + current_upgrade.volatility, 0, 100)
	
	return "Water: %d\nHeat Resist: %d\nVolatility: %d" % [new_water, new_heat, new_vol]

## Handle card selection
func _on_card_selected(ingredient_name: String) -> void:
	print("[CardSelector] Selected card: %s for upgrade" % ingredient_name)
	card_selected.emit(ingredient_name)
	hide()

## Handle cancel button
func _on_cancel_pressed() -> void:
	print("[CardSelector] Upgrade cancelled")
	selection_cancelled.emit()
	hide()
