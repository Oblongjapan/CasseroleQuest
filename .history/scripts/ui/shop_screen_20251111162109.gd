extends Panel

## Shop UI screen

@onready var shop_grid: GridContainer = $ScrollContainer/VBoxContainer/ShopGrid
@onready var currency_label: Label = $ScrollContainer/VBoxContainer/CurrencyLabel
@onready var round_label: Label = $ScrollContainer/VBoxContainer/RoundLabel
@onready var done_button: Button = $ScrollContainer/VBoxContainer/DoneButton
@onready var title_label: Label = $ScrollContainer/VBoxContainer/TitleLabel
@onready var card_selector: CardSelector = $CardSelector

# Preload ingredient card scene
const IngredientCardScene = preload("res://scenes/ingredient_card.tscn")

var shop_manager: ShopManager
var currency_manager: CurrencyManager
var fridge_manager: FridgeManager
var current_round: int = 1

func _ready():
	done_button.pressed.connect(_on_done_pressed)
	
	# Connect card selector signals
	if card_selector:
		card_selector.card_selected.connect(_on_card_selected_for_upgrade)
		card_selector.selection_cancelled.connect(_on_upgrade_cancelled)
	
	hide()

## Show shop with current inventory
func show_shop(shop_mgr: ShopManager, currency_mgr: CurrencyManager, fridge_mgr: FridgeManager, round_number: int) -> void:
	shop_manager = shop_mgr
	currency_manager = currency_mgr
	fridge_manager = fridge_mgr
	current_round = round_number
	
	# Connect to shop manager signal for upgrade purchases
	if not shop_manager.upgrade_needs_target.is_connected(_on_upgrade_needs_target):
		shop_manager.upgrade_needs_target.connect(_on_upgrade_needs_target)
	
	# Update labels
	title_label.text = "🛒 SHOP 🛒"
	round_label.text = "Round: %d" % current_round
	_update_currency_display()
	
	# Populate shop items
	_populate_shop_grid()
	
	show()

## Handle when upgrade is purchased and needs a target card
func _on_upgrade_needs_target(upgrade_data: Dictionary) -> void:
	print("[ShopScreen] Opening card selector for upgrade")
	card_selector.open_with_upgrade(upgrade_data, fridge_manager)

## Handle when card is selected for upgrade
func _on_card_selected_for_upgrade(ingredient_name: String) -> void:
	print("[ShopScreen] Card selected: %s" % ingredient_name)
	shop_manager.apply_upgrade_to_card(ingredient_name)
	_populate_shop_grid()  # Refresh shop

## Handle when upgrade is cancelled
func _on_upgrade_cancelled() -> void:
	print("[ShopScreen] Upgrade cancelled - refunding currency")
	# Refund the cost (stored in pending_upgrade)
	if shop_manager.pending_upgrade.has("cost"):
		currency_manager.add_currency(shop_manager.pending_upgrade.cost)
		shop_manager.pending_upgrade.clear()
		_update_currency_display()

## Populate the shop grid with items
func _populate_shop_grid() -> void:
	# Clear existing items
	for child in shop_grid.get_children():
		child.queue_free()
	
	# Get shop items
	var items = shop_manager.get_shop_items()
	
	for item in items:
		var item_card = _create_shop_item_card(item)
		shop_grid.add_child(item_card)

## Create a shop item card
func _create_shop_item_card(item: Dictionary) -> Control:
	var card = VBoxContainer.new()
	card.custom_minimum_size = Vector2(250, 150)
	
	# Add a panel for styling
	var panel = PanelContainer.new()
	
	# Add rarity color border if it's an upgrade
	if item.get("rarity", "") != "":
		var rarity_color = _get_rarity_color(item.rarity)
		panel.add_theme_stylebox_override("panel", _create_colored_panel(rarity_color))
	
	var vbox = VBoxContainer.new()
	
	# Name label
	var name_label = Label.new()
	name_label.text = item.name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 14)
	
	# Add rarity indicator to name for upgrades
	if item.get("rarity", "") != "":
		var rarity_text = " [%s]" % item.rarity.to_upper()
		name_label.text += rarity_text
		name_label.add_theme_color_override("font_color", _get_rarity_color(item.rarity))
	
	vbox.add_child(name_label)
	
	# Description label
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(desc_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)
	
	# Cost and buy button container
	var button_container = HBoxContainer.new()
	
	var cost_label = Label.new()
	cost_label.text = "Cost: %d" % item.cost
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_container.add_child(cost_label)
	
	var buy_button = Button.new()
	buy_button.text = "BUY"
	buy_button.pressed.connect(_on_buy_pressed.bind(item))
	button_container.add_child(buy_button)
	
	vbox.add_child(button_container)
	
	panel.add_child(vbox)
	card.add_child(panel)
	
	return card

## Handle buy button press
func _on_buy_pressed(item: Dictionary) -> void:
	if shop_manager.purchase_item(item):
		# Refresh shop display
		_update_currency_display()
		_populate_shop_grid()

## Update currency display
func _update_currency_display() -> void:
	currency_label.text = "Currency: %d" % currency_manager.get_currency()

## Handle done shopping button
func _on_done_pressed() -> void:
	hide()
	EventBus.shop_closed.emit()

## Get color for rarity tier
func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color.WHITE
		"uncommon": return Color.LIME_GREEN
		"rare": return Color.DODGER_BLUE
		"epic": return Color.PURPLE
		_: return Color.WHITE

## Create a colored panel style
func _create_colored_panel(color: Color) -> StyleBoxFlat:
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	stylebox.border_width_left = 3
	stylebox.border_width_right = 3
	stylebox.border_width_top = 3
	stylebox.border_width_bottom = 3
	stylebox.border_color = color
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	return stylebox
