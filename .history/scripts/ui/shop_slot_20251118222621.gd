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
	
	# This will be implemented to create the actual card/item display
	# For now, create a placeholder
	var item_display = VBoxContainer.new()
	
	var item_name = Label.new()
	item_name.text = item.get("name", "Unknown Item")
	item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_display.add_child(item_name)
	
	var item_desc = Label.new()
	item_desc.text = item.get("description", "")
	item_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_display.add_child(item_desc)
	
	# Add buy button if not free
	if not is_free_sample:
		var buy_button = Button.new()
		buy_button.text = "Buy - %d" % item.get("cost", 0)
		buy_button.pressed.connect(_on_item_purchased.bind(item))
		item_display.add_child(buy_button)
	else:
		var take_button = Button.new()
		take_button.text = "Take (Free!)"
		take_button.pressed.connect(_on_free_item_taken.bind(item))
		item_display.add_child(take_button)
	
	content_container.add_child(item_display)

func _on_item_purchased(item: Dictionary):
	# Handle purchase through shop manager
	if shop_manager and currency_manager:
		var can_afford = currency_manager.get_currency() >= item.get("cost", 0)
		if can_afford:
			# Purchase logic here
			print("[ShopSlot] Item purchased: %s" % item.get("name", ""))
			_mark_as_sold()

func _on_free_item_taken(item: Dictionary):
	# Handle free sample
	if shop_manager:
		print("[ShopSlot] Free sample taken: %s" % item.get("name", ""))
		_mark_as_taken()

func _mark_as_sold():
	# Update visual to show item is sold
	for child in content_container.get_children():
		if child is Button:
			child.text = "SOLD"
			child.disabled = true

func _mark_as_taken():
	# Update visual to show item is taken
	for child in content_container.get_children():
		if child is Button:
			child.text = "TAKEN"
			child.disabled = true

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
