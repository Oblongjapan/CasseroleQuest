extends Panel

## Simple shop UI screen - displays shop items directly

@onready var currency_label: Label = $CurrencyLabel
@onready var done_button: Button = $DoneButton
@onready var shop_items_container: VBoxContainer = $ScrollContainer/ShopItemsContainer
@onready var free_samples_container: VBoxContainer = $FreeSamplesContainer
@onready var card_selector: CardSelector = $CardSelector

var shop_manager: ShopManager
var currency_manager: CurrencyManager
var fridge_manager: FridgeManager
var game_state_manager: GameStateManager
var progression_manager: ProgressionManager
var current_round: int = 0
var free_samples_taken: int = 0

# Hover preview card
var hover_card: Control = null
var hover_tween: Tween = null
var is_hovering: bool = false
var hover_button: Button = null
var current_hover_item: Dictionary = {}
var current_hover_container: Control = null

const IngredientCardScene = preload("res://scenes/ingredient_card.tscn")

func _ready():
	done_button.pressed.connect(_on_done_pressed)
	
	# Connect card selector signals
	if card_selector:
		card_selector.card_selected.connect(_on_card_selected_for_upgrade)
		card_selector.selection_cancelled.connect(_on_upgrade_cancelled)
	
	# Connect currency changes
	EventBus.currency_changed.connect(_update_currency_display)
	
	hide()

## Show shop with current inventory
func show_shop(shop_mgr: ShopManager, currency_mgr: CurrencyManager, fridge_mgr: FridgeManager, game_state_mgr: GameStateManager, prog_mgr: ProgressionManager, round_number: int) -> void:
	shop_manager = shop_mgr
	currency_manager = currency_mgr
	fridge_manager = fridge_mgr
	game_state_manager = game_state_mgr
	progression_manager = prog_mgr
	current_round = round_number
	free_samples_taken = 0
	
	# Clear existing items
	_clear_shop_display()
	
	# Display shop items
	_display_shop_items()
	
	# Display free samples
	_display_free_samples()
	
	# Update labels
	_update_currency_display()
	
	show()

## Clear all displayed shop items
func _clear_shop_display():
	if shop_items_container:
		for child in shop_items_container.get_children():
			child.queue_free()
	if free_samples_container:
		for child in free_samples_container.get_children():
			child.queue_free()

## Display shop items for purchase - now only shows upgraded ingredients as food sprites
func _display_shop_items():
	if not shop_manager or not shop_items_container:
		return
	
	# Generate 4-6 upgraded (organic) ingredients
	var available_ingredients = IngredientsData.get_all_ingredients()
	var num_items = randi_range(4, 6)
	
	for i in range(num_items):
		if available_ingredients.is_empty():
			break
		
		var base_ingredient = available_ingredients[randi() % available_ingredients.size()]
		
		# Create upgraded version (add "Organic " prefix and apply 1 random upgrade)
		var upgraded_ingredient = base_ingredient.duplicate()
		upgraded_ingredient.name = "Organic " + base_ingredient.name
		
		# Apply 1 random upgrade
		var upgrade_type = randi() % 3
		match upgrade_type:
			0:  # Water upgrade
				var amount = randi_range(1, 5)
				upgraded_ingredient.water_content += amount
			1:  # Heat resistance upgrade
				var amount = randi_range(1, 5)
				upgraded_ingredient.heat_resistance += amount
			2:  # Volatility reduction (scaled down from 1-5 to 1-3)
				var amount = randi_range(1, 3)
				upgraded_ingredient.volatility = max(2, upgraded_ingredient.volatility - amount)  # Min volatility is 2
		
		# Calculate cost based on upgrade value (20-50 currency)
		var cost = randi_range(20, 50)
		
		var shop_item = {
			"type": ShopManager.ShopItemType.NEW_INGREDIENT,
			"name": upgraded_ingredient.name,
			"cost": cost,
			"ingredient": upgraded_ingredient
		}
		
		var item_sprite = _create_shop_ingredient_sprite(shop_item)
		shop_items_container.add_child(item_sprite)

## Display free samples
func _display_free_samples():
	if not shop_manager or not free_samples_container:
		return
	
	# Generate 3 free samples
	var available_ingredients = IngredientsData.get_all_ingredients()
	
	for i in range(3):
		if available_ingredients.is_empty():
			break
		
		var random_ingredient = available_ingredients[randi() % available_ingredients.size()]
		var sample_item = {
			"type": ShopManager.ShopItemType.NEW_INGREDIENT,
			"name": random_ingredient.name,
			"description": "Free Sample!",
			"cost": 0,
			"is_free": true,
			"ingredient": random_ingredient.duplicate()
		}
		
		var sample_panel = _create_free_sample_panel(sample_item)
		free_samples_container.add_child(sample_panel)

## Create a food sprite for shop ingredients (with hover preview)
func _create_shop_ingredient_sprite(item: Dictionary) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(120, 200)
	
	# Create food sprite
	var food_sprite = TextureRect.new()
	food_sprite.custom_minimum_size = Vector2(300, 300)
	food_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	food_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# Load food texture (strip "Organic " prefix for texture lookup)
	var ingredient_name = item.get("name", "Unknown").replace("Organic ", "")
	var texture_path = "res://Assets/Food/%s.png" % ingredient_name
	var texture = load(texture_path)
	if texture:
		food_sprite.texture = texture
	
	container.add_child(food_sprite)
	food_sprite.position = Vector2(10, 10)
	
	# Price label
	var price_label = Label.new()
	price_label.text = "%d" % item.get("cost", 0)
	price_label.position = Vector2(35, 120)
	price_label.add_theme_font_size_override("font_size", 20)
	container.add_child(price_label)
	
	# Connect hover signals - use deferred to prevent premature exit
	food_sprite.mouse_entered.connect(func(): _on_shop_item_hover_start(item, container, false))
	food_sprite.mouse_exited.connect(func(): _on_sample_hover_end.call_deferred())
	
	# Make sure the sprite receives mouse events
	food_sprite.mouse_filter = Control.MOUSE_FILTER_STOP
	
	return container

## Purchase a shop ingredient
func _purchase_shop_ingredient(item: Dictionary, container: Control):
	var cost = item.get("cost", 0)
	if currency_manager.get_currency() >= cost:
		if currency_manager.spend_currency(cost):
			if fridge_manager and item.has("ingredient"):
				fridge_manager.add_ingredient_to_deck(item.ingredient)
				print("[ShopScreen] Purchased: %s for %d" % [item.get("name", ""), cost])
				container.queue_free()
	else:
		_show_message("Cannot afford item!")
func _create_shop_item_panel(item: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(200, 150)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	
	# Item name
	var name_label = Label.new()
	name_label.text = item.get("name", "Unknown")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# Item description
	var desc_label = Label.new()
	desc_label.text = item.get("description", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)
	
	# Cost and buy button
	var buy_button = Button.new()
	buy_button.text = "Buy (%d)" % item.get("cost", 0)
	buy_button.pressed.connect(func(): _purchase_item(item, panel))
	vbox.add_child(buy_button)
	
	return panel

## Create a panel for a free sample - now shows food sprite with hover preview
func _create_free_sample_panel(item: Dictionary) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(120, 180)
	
	# Create food sprite
	var food_sprite = TextureRect.new()
	food_sprite.custom_minimum_size = Vector2(300, 300)
	food_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	food_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# Load food texture
	var ingredient_name = item.get("name", "Unknown")
	var texture_path = "res://Assets/Food/%s.png" % ingredient_name
	var texture = load(texture_path)
	if texture:
		food_sprite.texture = texture
	
	container.add_child(food_sprite)
	food_sprite.position = Vector2(10, 10)
	
	# Connect hover signals to food sprite - use deferred to prevent premature exit
	food_sprite.mouse_entered.connect(func(): _on_shop_item_hover_start(item, container, true))
	food_sprite.mouse_exited.connect(func(): _on_sample_hover_end.call_deferred())
	
	# Make sure the sprite receives mouse events
	food_sprite.mouse_filter = Control.MOUSE_FILTER_STOP
	
	return container

## Handle sample hover start - show scaling preview card centered on cursor
func _on_shop_item_hover_start(item: Dictionary, container: Control, is_free_sample: bool):
	if not item.has("ingredient"):
		return
	
	# Clean up any existing hover card first
	if hover_card:
		hover_card.queue_free()
		hover_card = null
	if hover_tween:
		hover_tween.kill()
		hover_tween = null
	if hover_button:
		hover_button.queue_free()
		hover_button = null
	
	is_hovering = true
	current_hover_item = item
	current_hover_container = container
	
	# Create ingredient card for preview
	var ingredient = item.ingredient
	hover_card = IngredientCardScene.instantiate()
	add_child(hover_card)
	
	# Set card data using setup() function
	hover_card.setup(ingredient)
	
	# Get mouse position and center card on it
	var mouse_pos = get_viewport().get_mouse_position()
	var card_half_size = hover_card.size / 2
	hover_card.position = mouse_pos - card_half_size
	
	# Clamp position to keep card within viewport bounds
	var viewport_size = get_viewport_rect().size
	hover_card.position.x = clamp(hover_card.position.x, 0, viewport_size.x - hover_card.size.x)
	hover_card.position.y = clamp(hover_card.position.y, 0, viewport_size.y - hover_card.size.y)
	
	hover_card.z_index = 1000
	
	# Start at smaller scale and quickly scale up to full size
	hover_card.scale = Vector2(0.3, 0.3)
	
	# Kill existing tween
	if hover_tween:
		hover_tween.kill()
	
	# Fast animation to full size (0.3 seconds)
	hover_tween = create_tween()
	hover_tween.tween_property(hover_card, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Create button inside the hover card
	if hover_button:
		hover_button.queue_free()
	
	hover_button = Button.new()
	if is_free_sample:
		hover_button.text = "TAKE"
		# Check if already taken 2 samples
		if free_samples_taken >= 2:
			hover_button.disabled = true
			hover_button.text = "LIMIT REACHED"
	else:
		var cost = item.get("cost", 0)
		hover_button.text = "BUY (%d)" % cost
		# Check if player can afford it
		if currency_manager and currency_manager.get_currency() < cost:
			hover_button.disabled = true
	
	hover_button.custom_minimum_size = Vector2(150, 50)
	hover_button.add_theme_font_size_override("font_size", 20)
	
	# Position button at bottom center of card
	hover_card.add_child(hover_button)
	hover_button.position = Vector2(hover_card.size.x / 2 - 75, hover_card.size.y - 70)
	
	# Connect button press
	if is_free_sample:
		hover_button.pressed.connect(func(): _on_hover_take_pressed())
	else:
		hover_button.pressed.connect(func(): _on_hover_buy_pressed())
	
	# Connect hover signals to the card and button to keep it open
	hover_card.mouse_entered.connect(func(): is_hovering = true)
	hover_card.mouse_exited.connect(func(): _on_sample_hover_end.call_deferred())
	hover_button.mouse_entered.connect(func(): is_hovering = true)
	hover_button.mouse_exited.connect(func(): _on_sample_hover_end.call_deferred())

## Handle buy button pressed in hover card
func _on_hover_buy_pressed():
	if current_hover_item.is_empty() or not current_hover_container:
		return
	
	_purchase_shop_ingredient(current_hover_item, current_hover_container)
	_on_sample_hover_end()

## Handle take button pressed in hover card
func _on_hover_take_pressed():
	if current_hover_item.is_empty():
		return
	
	if free_samples_taken >= 2:
		_show_message("You already took 2 free samples!")
		return
	
	if fridge_manager and current_hover_item.has("ingredient"):
		fridge_manager.add_ingredient_to_deck(current_hover_item.ingredient)
		free_samples_taken += 1
		print("[ShopScreen] Free sample taken: %s (%d/2)" % [current_hover_item.get("name", ""), free_samples_taken])
		
		# Remove the container from the free samples
		if current_hover_container:
			current_hover_container.queue_free()
	
	_on_sample_hover_end()

## Handle sample hover end - remove preview card
func _on_sample_hover_end():
	# Don't immediately close if we're still hovering
	# Give it a frame to check if we've entered a new item
	await get_tree().process_frame
	
	# If we're hovering again (moved to a new item), don't close
	if is_hovering and hover_card:
		return
	
	# Check if mouse is still over the hover card
	if hover_card and is_instance_valid(hover_card):
		var mouse_pos = get_viewport().get_mouse_position()
		var card_rect = Rect2(hover_card.global_position, hover_card.size * hover_card.scale)
		if card_rect.has_point(mouse_pos):
			return  # Don't close if mouse is still over the card
	
	is_hovering = false
	current_hover_item.clear()
	current_hover_container = null
	
	# Kill tween
	if hover_tween:
		hover_tween.kill()
		hover_tween = null
	
	# Remove button
	if hover_button:
		hover_button.queue_free()
		hover_button = null
	
	# Remove hover card
	if hover_card:
		hover_card.queue_free()
		hover_card = null

## Purchase an item (legacy - keeping for compatibility)
func _purchase_item(item: Dictionary, panel: Panel):
	if shop_manager.purchase_item(item):
		print("[ShopScreen] Purchased: %s" % item.get("name", ""))
		panel.queue_free()
	else:
		_show_message("Cannot afford item!")

## Handle when upgrade is purchased and needs a target card
func _on_upgrade_needs_target(upgrade_data: Dictionary) -> void:
	print("[ShopScreen] Opening card selector for upgrade")
	if card_selector:
		card_selector.open_with_upgrade(upgrade_data, fridge_manager)

## Handle when card is selected for upgrade
func _on_card_selected_for_upgrade(ingredient_name: String) -> void:
	print("[ShopScreen] Card selected: %s" % ingredient_name)
	shop_manager.apply_upgrade_to_card(ingredient_name)

## Handle when upgrade is cancelled
func _on_upgrade_cancelled() -> void:
	print("[ShopScreen] Upgrade cancelled - refunding currency")
	if shop_manager.pending_upgrade.has("cost"):
		currency_manager.add_currency(shop_manager.pending_upgrade.cost)
		shop_manager.pending_upgrade.clear()
		_update_currency_display()

## Update currency display
func _update_currency_display() -> void:
	if currency_manager:
		currency_label.text = "💰 Currency: %d" % currency_manager.get_currency()

## Handle done shopping button
func _on_done_pressed() -> void:
	hide()
	EventBus.shop_closed.emit()

## Show a message popup
func _show_message(message: String):
	var popup = AcceptDialog.new()
	popup.dialog_text = message
	popup.ok_button_text = "OK"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())
	popup.close_requested.connect(func(): popup.queue_free())
