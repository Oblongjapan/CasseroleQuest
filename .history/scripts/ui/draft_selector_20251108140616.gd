extends Panel

## UI controller for draft/pick phase - shows 3 random items to choose from

@onready var draft_grid: GridContainer = $VBoxContainer/DraftGrid
@onready var confirm_button: Button = $VBoxContainer/ConfirmButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var info_label: Label = $VBoxContainer/InfoLabel
@onready var trade_dialog: Panel = $TradeDialog
@onready var ingredient_trade_dialog: Panel = $IngredientTradeDialog

enum ItemCategory { INGREDIENT, ACTIVE_ITEM, RELIC }

var draft_pool: Array[Dictionary] = []  # {category: ItemCategory, data: Variant}
var selected_items: Array[Dictionary] = []
const MAX_SELECTIONS: int = 2

var inventory_manager: InventoryManager
var pending_trade_item: Dictionary = {}  # Item waiting to be traded in
var pending_ingredient: IngredientModel  # Ingredient waiting to be traded

func _ready():
	confirm_button.pressed.connect(_on_confirm_pressed)
	
	# Setup trade dialogs if they exist
	if trade_dialog:
		trade_dialog.hide()
	if ingredient_trade_dialog:
		ingredient_trade_dialog.hide()
	
	hide()

## Show draft selector with random pool of 3 items
func show_draft(inventory: InventoryManager, is_initial_draft: bool = false, round_number: int = 1) -> void:
	inventory_manager = inventory
	selected_items.clear()
	draft_pool.clear()
	
	if is_initial_draft:
		title_label.text = "Game Start - Choose Starting Ingredients"
		info_label.text = "Pick 0-3 ingredients for your first cook"
		_generate_initial_draft_pool()
	elif round_number > 0 and round_number % 5 == 0:
		# Milestone rounds: show relics and items
		title_label.text = "Milestone Round %d - Special Reward!" % round_number
		info_label.text = "Pick 1 relic or active item"
		_generate_milestone_draft_pool()
	else:
		# Normal rounds: only ingredients
		title_label.text = "Round %d Complete - Choose Ingredients" % round_number
		info_label.text = "Pick 0-2 ingredients to add to your collection"
		_generate_ingredient_draft_pool()
	
	_populate_draft_cards()
	show()
	_update_confirm_button()

## Generate initial draft pool (6 ingredients)
func _generate_initial_draft_pool() -> void:
	var ingredients = IngredientsData.get_random_ingredient_pool(6)
	for ingredient in ingredients:
		draft_pool.append({
			"category": ItemCategory.INGREDIENT,
			"data": ingredient
		})

## Generate ingredient-only draft pool (3 ingredients)
func _generate_ingredient_draft_pool() -> void:
	var ingredients = IngredientsData.get_random_ingredient_pool(3)
	for ingredient in ingredients:
		draft_pool.append({
			"category": ItemCategory.INGREDIENT,
			"data": ingredient
		})

## Generate milestone draft pool (4 relics and items)
func _generate_milestone_draft_pool() -> void:
	var available_items: Array[Dictionary] = []
	
	# Add all possible active items
	var all_items = ActiveItemsData.get_all_items()
	for item in all_items:
		available_items.append({
			"category": ItemCategory.ACTIVE_ITEM,
			"data": item
		})
	
	# Add all possible relics
	var all_relics = RelicsData.get_all_relics()
	for relic in all_relics:
		available_items.append({
			"category": ItemCategory.RELIC,
			"data": relic
		})
	
	# Shuffle and pick 4
	available_items.shuffle()
	for i in range(min(4, available_items.size())):
		draft_pool.append(available_items[i])

## Generate draft pool (3 random items: mix of ingredients, active items, relics) - DEPRECATED
func _generate_draft_pool() -> void:
	var available_items: Array[Dictionary] = []
	
	# Add all possible ingredients
	var all_ingredients = IngredientsData.get_all_ingredients()
	for ingredient in all_ingredients:
		available_items.append({
			"category": ItemCategory.INGREDIENT,
			"data": ingredient
		})
	
	# Add all possible active items (if player can still add them)
	if inventory_manager.can_add_active_item():
		var all_items = ActiveItemsData.get_all_items()
		for item in all_items:
			available_items.append({
				"category": ItemCategory.ACTIVE_ITEM,
				"data": item
			})
	
	# Add all possible relics
	var all_relics = RelicsData.get_all_relics()
	for relic in all_relics:
		available_items.append({
			"category": ItemCategory.RELIC,
			"data": relic
		})
	
	# Shuffle and pick 3
	available_items.shuffle()
	for i in range(min(3, available_items.size())):
		draft_pool.append(available_items[i])

## Create draft cards in grid
func _populate_draft_cards() -> void:
	# Clear existing cards
	for child in draft_grid.get_children():
		child.queue_free()
	
	# Create new cards
	for item in draft_pool:
		var card = _create_draft_card(item)
		draft_grid.add_child(card)

## Create a single draft card button
func _create_draft_card(item: Dictionary) -> Button:
	var card = Button.new()
	card.custom_minimum_size = Vector2(180, 140)
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var item_name: String
	var item_info: String
	var category_label: String
	
	match item.category:
		ItemCategory.INGREDIENT:
			var ingredient: IngredientModel = item.data
			category_label = "[INGREDIENT]"
			item_name = ingredient.name
			item_info = ingredient.get_stats_description()
		ItemCategory.ACTIVE_ITEM:
			var active_item: ActiveItem = item.data
			category_label = "[ITEM]"
			item_name = active_item.name
			item_info = active_item.description
		ItemCategory.RELIC:
			var relic: RelicModel = item.data
			category_label = "[RELIC]"
			item_name = relic.name
			item_info = "%s\n%s" % [relic.description, relic.get_effect_description()]
	
	card.text = "%s\n%s\n\n%s" % [category_label, item_name, item_info]
	
	# Connect pressed signal
	card.pressed.connect(_on_draft_card_pressed.bind(item, card))
	
	return card

## Handle draft card selection
func _on_draft_card_pressed(item: Dictionary, card: Button) -> void:
	if item in selected_items:
		# Deselect
		selected_items.erase(item)
		card.modulate = Color.WHITE
	else:
		# Check if this is initial draft (more flexible selection)
		var max_sel = MAX_SELECTIONS if title_label.text.contains("Round") else 3
		
		# Select (if under limit)
		if selected_items.size() < max_sel:
			# Additional check for active items (max 3 total)
			if item.category == ItemCategory.ACTIVE_ITEM:
				if not inventory_manager.can_add_active_item():
					# Show trade dialog
					pending_trade_item = item
					_show_trade_dialog()
					return
			
			selected_items.append(item)
			card.modulate = Color.GREEN
	
	_update_confirm_button()

## Enable/disable confirm button based on selection
func _update_confirm_button() -> void:
	confirm_button.disabled = false  # Can always skip picks
	
	if selected_items.size() == 0:
		confirm_button.text = "Skip (Take Nothing)"
	else:
		confirm_button.text = "Confirm Selection (%d)" % selected_items.size()

## Confirm selection and add to inventory
func _on_confirm_pressed() -> void:
	# Add selected items to inventory
	for item in selected_items:
		match item.category:
			ItemCategory.INGREDIENT:
				inventory_manager.add_ingredient(item.data)
			ItemCategory.ACTIVE_ITEM:
				inventory_manager.add_active_item(item.data)
			ItemCategory.RELIC:
				inventory_manager.add_relic(item.data)
	
	# Emit signal that draft is complete
	EventBus.draft_completed.emit()
	hide()

## Show trade dialog for active items
func _show_trade_dialog() -> void:
	if not trade_dialog:
		# Fallback: just show message if no dialog exists
		info_label.text = "Active items maxed! Can't add more."
		return
	
	var new_item: ActiveItem = pending_trade_item.data
	
	# Get nodes with null checks
	var trade_label = trade_dialog.get_node_or_null("VBoxContainer/TradeLabel")
	var buttons_container = trade_dialog.get_node_or_null("VBoxContainer/ItemButtons")
	var cancel_button = trade_dialog.get_node_or_null("VBoxContainer/CancelButton")
	
	if not trade_label or not buttons_container or not cancel_button:
		info_label.text = "Trade dialog error!"
		return
	
	trade_label.text = "Trade an item for %s?\n%s" % [new_item.name, new_item.description]
	
	# Clear existing buttons
	for child in buttons_container.get_children():
		child.queue_free()
	
	# Create buttons for each owned item
	var owned_items = inventory_manager.get_active_items()
	for i in range(owned_items.size()):
		var btn = Button.new()
		btn.text = "%s\n%s" % [owned_items[i].name, owned_items[i].description]
		btn.custom_minimum_size = Vector2(120, 80)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_trade_item_selected.bind(i))
		buttons_container.add_child(btn)
	
	# Setup cancel button
	if not cancel_button.pressed.is_connected(_on_trade_cancelled):
		cancel_button.pressed.connect(_on_trade_cancelled)
	
	trade_dialog.show()

## Handle trading an item
func _on_trade_item_selected(index: int) -> void:
	# Remove old item and add new one
	inventory_manager.trade_active_item(index, pending_trade_item.data)
	selected_items.append(pending_trade_item)
	pending_trade_item = {}
	trade_dialog.hide()
	info_label.text = "Item traded successfully!"
	_update_confirm_button()

## Cancel trade
func _on_trade_cancelled() -> void:
	pending_trade_item = {}
	trade_dialog.hide()
	info_label.text = "Trade cancelled"
