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
var inventory_manager: InventoryManager

func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed)
	hide()

## Open the card selector with a specific upgrade
func open_with_upgrade(upgrade_data: Dictionary, inv_manager: InventoryManager) -> void:
	current_upgrade = upgrade_data
	inventory_manager = inv_manager
	
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
	
	if upgrade_data.has("oil") and upgrade_data.oil != 0:
		var sign = "+" if upgrade_data.oil > 0 else ""
		parts.append("%s%d Oil" % [sign, upgrade_data.oil])
	
	if upgrade_data.has("volatility") and upgrade_data.volatility != 0:
		var sign = "+" if upgrade_data.volatility > 0 else ""
		parts.append("%s%d Volatility" % [sign, upgrade_data.volatility])
	
	if upgrade_data.has("cook_time") and upgrade_data.cook_time != 0:
		var sign = "+" if upgrade_data.cook_time > 0 else ""
		parts.append("%s%d Cook Time" % [sign, upgrade_data.cook_time])
	
	return ", ".join(parts) if parts.size() > 0 else "Unknown"

## Populate the grid with cards from player's deck
func _populate_card_grid() -> void:
	# Clear existing cards
	for child in card_grid.get_children():
		child.queue_free()
	
	if not inventory_manager:
		print("[CardSelector] Error: No inventory manager provided")
		return
	
	var deck = inventory_manager.get_deck()
	
	if deck.is_empty():
		var label = Label.new()
		label.text = "No cards in deck!"
		card_grid.add_child(label)
		return
	
	# Create a button for each unique ingredient
	var unique_ingredients: Dictionary = {}
	for ingredient in deck:
		if ingredient.name not in unique_ingredients:
			unique_ingredients[ingredient.name] = ingredient
	
	for ingredient_name in unique_ingredients:
		var ingredient = unique_ingredients[ingredient_name]
		var card_button = _create_card_button(ingredient)
		card_grid.add_child(card_button)

## Create a clickable card button
func _create_card_button(ingredient: IngredientModel) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(150, 200)
	
	# Create card display
	var vbox = VBoxContainer.new()
	button.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = ingredient.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	var stats_label = Label.new()
	stats_label.text = "Water: %d\nOil: %d\nVol: %d\nTime: %ds" % [
		ingredient.water_content,
		ingredient.oil_content,
		ingredient.volatility,
		ingredient.cook_time
	]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)
	
	# Show what the upgrade would result in
	var preview_label = Label.new()
	preview_label.text = "\n--- After Upgrade ---\n" + _get_upgrade_preview(ingredient)
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.add_theme_color_override("font_color", Color.GREEN)
	vbox.add_child(preview_label)
	
	button.pressed.connect(_on_card_selected.bind(ingredient.name))
	
	return button

## Get preview of stats after upgrade
func _get_upgrade_preview(ingredient: IngredientModel) -> String:
	var new_water = ingredient.water_content
	var new_oil = ingredient.oil_content
	var new_vol = ingredient.volatility
	var new_time = ingredient.cook_time
	
	if current_upgrade.has("water"):
		new_water = clampi(new_water + current_upgrade.water, 0, 20)
	if current_upgrade.has("oil"):
		new_oil = clampi(new_oil + current_upgrade.oil, 0, 20)
	if current_upgrade.has("volatility"):
		new_vol = clampi(new_vol + current_upgrade.volatility, 0, 20)
	if current_upgrade.has("cook_time"):
		new_time = maxi(new_time + current_upgrade.cook_time, 1)
	
	return "Water: %d\nOil: %d\nVol: %d\nTime: %ds" % [new_water, new_oil, new_vol, new_time]

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
