extends Panel

## Shop UI screen - now uses VisualShopGrid system

@onready var visual_shop_grid: VisualShopGrid = $VisualShopGrid
@onready var currency_label: Label = $CurrencyLabel
@onready var done_button: Button = $DoneButton
@onready var card_selector: CardSelector = $CardSelector

var shop_manager: ShopManager
var currency_manager: CurrencyManager
var fridge_manager: FridgeManager
var game_state_manager: GameStateManager
var progression_manager: ProgressionManager
var current_round: int = 0

func _ready():
	done_button.pressed.connect(_on_done_pressed)
	
	# Connect card selector signals
	if card_selector:
		card_selector.card_selected.connect(_on_card_selected_for_upgrade)
		card_selector.selection_cancelled.connect(_on_upgrade_cancelled)
	
	hide()

## Show shop with current inventory
func show_shop(shop_mgr: ShopManager, currency_mgr: CurrencyManager, fridge_mgr: FridgeManager, game_state_mgr: GameStateManager, round_number: int) -> void:
	shop_manager = shop_mgr
	currency_manager = currency_mgr
	fridge_manager = fridge_mgr
	game_state_manager = game_state_mgr
	current_round = round_number
	
	# Connect to shop manager signal for upgrade purchases
	if not shop_manager.upgrade_needs_target.is_connected(_on_upgrade_needs_target):
		shop_manager.upgrade_needs_target.connect(_on_upgrade_needs_target)
	
	# Update labels
	title_label.text = "WELCOME TO THE SHOP"
	_update_currency_display()
	
	# Populate shop items
	_populate_shop_grid()
	
	# Check if this is first visit and player can't afford anything
	_check_first_visit_affordability()
	
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
	
	# Wait for removal to complete
	await get_tree().process_frame
	
	# Get shop items
	var items = shop_manager.get_shop_items()
	
	for item in items:
		var item_card = _create_shop_item_card(item)
		shop_grid.add_child(item_card)
		
		# If it's an ingredient card, setup after adding to tree
		if item.type == ShopManager.ShopItemType.NEW_INGREDIENT and item.has("ingredient"):
			# Get the card instance (first child of the container)
			var card = item_card.get_child(0) as IngredientCard
			if card:
				var pending_ingredient = card.get_meta("pending_ingredient") as IngredientModel
				var pending_upgrade = card.get_meta("pending_upgrade", "") as String
				card.setup(pending_ingredient, pending_upgrade)

## Create a shop item card
func _create_shop_item_card(item: Dictionary) -> Control:
	# Special handling for NEW_INGREDIENT - use actual ingredient card
	if item.type == ShopManager.ShopItemType.NEW_INGREDIENT and item.has("ingredient"):
		return _create_ingredient_purchase_card(item)
	
	# For other items (upgrades, relics, etc.), use the generic card
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
	
	# Check if item is already purchased
	if item.get("is_purchased", false):
		buy_button.text = "SOLD"
		buy_button.disabled = true
		cost_label.modulate = Color(0.5, 0.5, 0.5)
		name_label.modulate = Color(0.6, 0.6, 0.6)
	
	button_container.add_child(buy_button)
	
	vbox.add_child(button_container)
	
	panel.add_child(vbox)
	card.add_child(panel)
	
	return card

## Create an ingredient purchase card using the actual IngredientCard scene
func _create_ingredient_purchase_card(item: Dictionary) -> Control:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(180, 300)
	
	# Instance the ingredient card
	var card_instance: IngredientCard = IngredientCardScene.instantiate()
	
	# Get upgrade description if any (empty for shop items)
	var upgrade_desc = ""
	
	# Store data for setup after _ready (same pattern as hand_selector and card_selector)
	card_instance.set_meta("pending_ingredient", item.ingredient)
	card_instance.set_meta("pending_upgrade", upgrade_desc)
	
	# Prevent the card from expanding - keep it at its fixed 180x260 size
	card_instance.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card_instance.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	# Add to container (setup will be called after container is added to tree)
	container.add_child(card_instance)
	
	# Disable drag/drop and selection (it's just for display in shop)
	card_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Add spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	container.add_child(spacer)
	
	# Cost and buy button container
	var button_container = HBoxContainer.new()
	button_container.custom_minimum_size = Vector2(180, 0)
	
	var cost_label = Label.new()
	cost_label.text = "💰 %d" % item.cost
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 16)
	button_container.add_child(cost_label)
	
	var buy_button = Button.new()
	buy_button.text = "BUY"
	buy_button.custom_minimum_size = Vector2(80, 40)
	buy_button.add_theme_font_size_override("font_size", 16)
	buy_button.pressed.connect(_on_buy_pressed.bind(item))
	
	# Check if item is already purchased
	if item.get("is_purchased", false):
		buy_button.text = "SOLD"
		buy_button.disabled = true
		cost_label.modulate = Color(0.5, 0.5, 0.5)
		card_instance.modulate = Color(0.6, 0.6, 0.6)
	
	button_container.add_child(buy_button)
	
	container.add_child(button_container)
	
	return container

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

## Check if this is first shop visit and player can't afford anything
func _check_first_visit_affordability() -> void:
	if not game_state_manager:
		print("[ShopScreen] ERROR: game_state_manager is null!")
		return
	
	# Only check on first visit
	if game_state_manager.has_visited_shop:
		return
	
	game_state_manager.has_visited_shop = true
	
	# Check if player can afford ANY item
	var current_money = currency_manager.get_currency()
	var items = shop_manager.get_shop_items()
	var can_afford_any = false
	
	for item in items:
		if item.has("cost") and current_money >= item.cost:
			can_afford_any = true
			break
	
	print("[ShopScreen] First visit check: can_afford_any=%s, current_money=%d, items=%d" % [can_afford_any, current_money, items.size()])
	
	# If can't afford anything, show popup and flag water cup delivery
	if not can_afford_any:
		game_state_manager.should_give_water_cup = true
		_show_moisture_popup()

## Show "NEED MORE MOISTURE!!!" popup
func _show_moisture_popup() -> void:
	# Create a simple popup
	var popup = AcceptDialog.new()
	popup.dialog_text = "NEED MORE MOISTURE!!!"
	popup.title = ""
	popup.ok_button_text = "OK"
	
	# Style it
	var label = popup.get_label()
	if label:
		label.add_theme_font_size_override("font_size", 32)
		label.add_theme_color_override("font_color", Color.RED)
	
	add_child(popup)
	popup.popup_centered()
	
	# Clean up after closing
	popup.confirmed.connect(func(): popup.queue_free())
	popup.close_requested.connect(func(): popup.queue_free())
