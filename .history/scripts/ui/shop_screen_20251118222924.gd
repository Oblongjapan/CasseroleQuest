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
func show_shop(shop_mgr: ShopManager, currency_mgr: CurrencyManager, fridge_mgr: FridgeManager, game_state_mgr: GameStateManager, prog_mgr: ProgressionManager, round_number: int) -> void:
	shop_manager = shop_mgr
	currency_manager = currency_mgr
	fridge_manager = fridge_mgr
	game_state_manager = game_state_mgr
	progression_manager = prog_mgr
	current_round = round_number
	
	# Setup visual shop grid
	if visual_shop_grid:
		visual_shop_grid.setup(shop_manager, currency_manager, fridge_manager, progression_manager, card_selector)
		visual_shop_grid.refresh_shop(round_number)
	
	# Update labels
	_update_currency_display()
	
	# Check if this is first visit and player can't afford anything
	_check_first_visit_affordability()
	
	show()

## Handle when upgrade is purchased and needs a target card
func _on_upgrade_needs_target(upgrade_data: Dictionary) -> void:
	print("[ShopScreen] Opening card selector for upgrade")
	if card_selector:
		card_selector.open_with_upgrade(upgrade_data, fridge_manager)

## Handle when card is selected for upgrade
func _on_card_selected_for_upgrade(ingredient_name: String) -> void:
	print("[ShopScreen] Card selected: %s" % ingredient_name)
	shop_manager.apply_upgrade_to_card(ingredient_name)
	# Refresh shop grid
	if visual_shop_grid:
		visual_shop_grid.refresh_shop(current_round)

## Handle when upgrade is cancelled
func _on_upgrade_cancelled() -> void:
	print("[ShopScreen] Upgrade cancelled - refunding currency")
	# Refund the cost (stored in pending_upgrade)
	if shop_manager.pending_upgrade.has("cost"):
		currency_manager.add_currency(shop_manager.pending_upgrade.cost)
		shop_manager.pending_upgrade.clear()
		_update_currency_display()

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
