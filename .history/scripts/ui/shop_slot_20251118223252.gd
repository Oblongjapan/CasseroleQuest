extends Panel
class_name ShopSlot

## A visual shop slot that can be placed and arranged in the editor
## Items will be instantiated into these slots at runtime

enum SlotType {
	INGREDIENT,      # Shows ingredient cards
	UPGRADE,         # Shows upgrade cards
	RELIC,           # Shows relic cards
	FREE_SAMPLE,     # Special slot for free ingredients
	ANY              # Can show any type
}

@export var slot_type: SlotType = SlotType.ANY
@export var slot_label: String = "Slot"
@export var is_free_sample: bool = false  # If true, this slot gives free items

@onready var content_container: Control = $ContentContainer
@onready var label: Label = $Label
@onready var type_indicator: Label = $TypeIndicator

# Preload ingredient card scene
const IngredientCardScene = preload("res://scenes/ingredient_card.tscn")

var current_item: Dictionary = {}
var shop_manager: ShopManager
var currency_manager: CurrencyManager
var fridge_manager: FridgeManager
var progression_manager: ProgressionManager
var is_occupied: bool = false
var is_sample_seen: bool = false  # Track if free sample has been revealed

signal item_clicked(item: Dictionary, slot: ShopSlot)
signal free_sample_taken(item: Dictionary, slot: ShopSlot)

func _ready():
	# Setup visual indicators
	if label:
		label.text = slot_label
	
	if type_indicator:
		type_indicator.text = _get_type_text()
		type_indicator.modulate = _get_type_color()
	
	# Style the panel based on type
	_apply_slot_styling()

func _get_type_text() -> String:
	match slot_type:
		SlotType.INGREDIENT:
			return "[INGREDIENT]"
		SlotType.UPGRADE:
			return "[UPGRADE]"
		SlotType.RELIC:
			return "[RELIC]"
		SlotType.FREE_SAMPLE:
			return "[FREE SAMPLE]"
		SlotType.ANY:
			return "[ANY]"
	return ""

func _get_type_color() -> Color:
	if is_free_sample:
		return Color.GOLD
	
	match slot_type:
		SlotType.INGREDIENT:
			return Color.LIGHT_GREEN
		SlotType.UPGRADE:
			return Color.LIGHT_BLUE
		SlotType.RELIC:
			return Color.PURPLE
		SlotType.ANY:
			return Color.WHITE
	return Color.WHITE

func _apply_slot_styling():
	# Create a styled panel for the slot
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	style_box.border_color = _get_type_color()
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	
	add_theme_stylebox_override("panel", style_box)

## Check if this slot can accept a given item type
func can_accept_item(item: Dictionary) -> bool:
	if is_occupied:
		return false
	
	if slot_type == SlotType.ANY:
		return true
	
	if not item.has("type"):
		return false
	
	match slot_type:
		SlotType.INGREDIENT:
			return item.type == ShopManager.ShopItemType.NEW_INGREDIENT
		SlotType.UPGRADE:
			return item.type == ShopManager.ShopItemType.INGREDIENT_UPGRADE
		SlotType.RELIC:
			return item.type == ShopManager.ShopItemType.RELIC
		SlotType.FREE_SAMPLE:
			return is_free_sample and item.has("is_free") and item.is_free
	
	return false

## Set the item in this slot
func set_item(item: Dictionary, shop_mgr: ShopManager, currency_mgr: CurrencyManager, fridge_mgr: FridgeManager = null, prog_mgr: ProgressionManager = null):
	current_item = item
	shop_manager = shop_mgr
	currency_manager = currency_mgr
	fridge_manager = fridge_mgr
	progression_manager = prog_mgr
	is_occupied = true
	
	# Clear placeholder labels
	if label:
		label.hide()
	if type_indicator:
		type_indicator.hide()
	
	# Create the actual shop item in the content container
	_create_shop_item_display(item)

## Create the visual representation of the shop item
func _create_shop_item_display(item: Dictionary):
	# Clear existing content
	for child in content_container.get_children():
		child.queue_free()
	
	# Free samples show as mystery boxes until revealed
	if is_free_sample and not is_sample_seen:
		_create_mystery_box()
		return
	
	# Create ingredient card for ingredient items
	if item.get("type") == ShopManager.ShopItemType.NEW_INGREDIENT and item.has("ingredient"):
		_create_ingredient_card_display(item)
	else:
		# Generic display for upgrades/relics
		_create_generic_item_display(item)

## Create a mystery box for unrevealed free samples
func _create_mystery_box():
	var mystery = VBoxContainer.new()
	mystery.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mystery.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Mystery box visual
	var box_label = Label.new()
	box_label.text = "?"
	box_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box_label.add_theme_font_size_override("font_size", 72)
	box_label.add_theme_color_override("font_color", Color.GOLD)
	box_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mystery.add_child(box_label)
	
	var mystery_label = Label.new()
	mystery_label.text = "Mystery Sample"
	mystery_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mystery_label.add_theme_font_size_override("font_size", 14)
	mystery.add_child(mystery_label)
	
	var reveal_button = Button.new()
	if reveal_button:
		reveal_button.text = "REVEAL"
		reveal_button.custom_minimum_size = Vector2(0, 40)
		reveal_button.pressed.connect(_on_mystery_box_clicked)
		mystery.add_child(reveal_button)
	
	content_container.add_child(mystery)

## Create ingredient card display
func _create_ingredient_card_display(item: Dictionary):
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Instance the ingredient card
	var card_instance: IngredientCard = IngredientCardScene.instantiate()
	
	# Store data for setup after _ready
	card_instance.set_meta("pending_ingredient", item.ingredient)
	card_instance.set_meta("pending_upgrade", "")
	
	# Scale down the card to fit in slot
	card_instance.scale = Vector2(0.9, 0.9)
	card_instance.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	container.add_child(card_instance)
	
	# Add button
	if is_free_sample:
		var take_button = Button.new()
		take_button.text = "TAKE (Free!)"
		take_button.custom_minimum_size = Vector2(0, 40)
		take_button.add_theme_font_size_override("font_size", 14)
		take_button.pressed.connect(_on_free_item_clicked)
		container.add_child(take_button)
	else:
		var cost_label = Label.new()
		cost_label.text = "💰 %d" % item.get("cost", 0)
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_label.add_theme_font_size_override("font_size", 16)
		container.add_child(cost_label)
		
		var buy_button = Button.new()
		buy_button.text = "BUY"
		buy_button.custom_minimum_size = Vector2(0, 40)
		buy_button.pressed.connect(_on_paid_item_clicked)
		container.add_child(buy_button)
	
	content_container.add_child(container)
	
	# Setup card after adding to tree
	await get_tree().process_frame
	if card_instance and is_instance_valid(card_instance):
		var pending_ingredient = card_instance.get_meta("pending_ingredient") as IngredientModel
		card_instance.setup(pending_ingredient, "")

## Create generic item display (for upgrades/relics)
func _create_generic_item_display(item: Dictionary):
	var display = VBoxContainer.new()
	display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Name
	var name_label = Label.new()
	name_label.text = item.get("name", "Unknown")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 14)
	
	# Color by rarity
	if item.has("rarity"):
		name_label.add_theme_color_override("font_color", _get_rarity_color(item.rarity))
	
	display.add_child(name_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = item.get("description", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	display.add_child(desc_label)
	
	# Cost and button
	var cost_label = Label.new()
	cost_label.text = "💰 %d" % item.get("cost", 0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 16)
	display.add_child(cost_label)
	
	var buy_button = Button.new()
	buy_button.text = "BUY"
	buy_button.custom_minimum_size = Vector2(0, 40)
	buy_button.pressed.connect(_on_paid_item_clicked)
	display.add_child(buy_button)
	
	content_container.add_child(display)

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color.WHITE
		"uncommon": return Color.LIME_GREEN
		"rare": return Color.DODGER_BLUE
		"epic": return Color.PURPLE
		_: return Color.WHITE

## Handle mystery box click (reveal the sample)
func _on_mystery_box_clicked():
	is_sample_seen = true
	_create_shop_item_display(current_item)

## Handle free sample click
func _on_free_item_clicked():
	print("[ShopSlot] Free sample taken: %s" % current_item.get("name", ""))
	free_sample_taken.emit(current_item, self)
	_mark_as_taken()

## Handle paid item click (emit signal for purchase prompt)
func _on_paid_item_clicked():
	print("[ShopSlot] Item clicked for purchase: %s" % current_item.get("name", ""))
	item_clicked.emit(current_item, self)

func _on_item_purchased(_item: Dictionary):
	# This is now handled by the parent VisualShopGrid
	pass

func _on_free_item_taken(_item: Dictionary):
	# This is now handled by the parent VisualShopGrid
	pass

func _mark_as_sold():
	# Update visual to show item is sold
	for child in content_container.get_children():
		_mark_buttons_in_node(child, "SOLD", true)

func _mark_as_taken():
	# Update visual to show item is taken
	for child in content_container.get_children():
		_mark_buttons_in_node(child, "TAKEN", true)

func _mark_buttons_in_node(node: Node, text: String, disabled: bool):
	if node is Button:
		node.text = text
		node.disabled = disabled
	for child in node.get_children():
		_mark_buttons_in_node(child, text, disabled)

## Clear the slot
func clear_slot():
	current_item.clear()
	is_occupied = false
	
	# Clear content
	for child in content_container.get_children():
		child.queue_free()
	
	# Show placeholder labels again
	if label:
		label.show()
	if type_indicator:
		type_indicator.show()
