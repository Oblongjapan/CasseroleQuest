extends Panel

## Simple shop UI screen - displays shop items directly

@onready var currency_label: Label = $CurrencyLabel
@onready var done_button: Button = $DoneButton
@onready var shop_items_container: VBoxContainer = $ScrollContainer/ShopItemsContainer
@onready var free_samples_container: HBoxContainer = $FreeSamplesContainer
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

## Display shop items for purchase
func _display_shop_items():
	if not shop_manager or not shop_items_container:
		return
	
	var items = shop_manager.current_shop_items
	
	for item in items:
		var item_panel = _create_shop_item_panel(item)
		shop_items_container.add_child(item_panel)

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

## Create a panel for a shop item
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
	food_sprite.custom_minimum_size = Vector2(100, 100)
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
	
	# Take button
	var take_button = Button.new()
	take_button.text = "TAKE"
	take_button.custom_minimum_size = Vector2(100, 40)
	take_button.position = Vector2(10, 130)
	take_button.pressed.connect(func(): _take_free_sample(item, take_button))
	container.add_child(take_button)
	
	# Connect hover signals to food sprite
	food_sprite.mouse_entered.connect(func(): _on_sample_hover_start(item))
	food_sprite.mouse_exited.connect(func(): _on_sample_hover_end())
	
	# Make sure the sprite receives mouse events
	food_sprite.mouse_filter = Control.MOUSE_FILTER_STOP
	
	return container

## Handle sample hover start - show scaling preview card
func _on_sample_hover_start(item: Dictionary):
	if not item.has("ingredient"):
		return
	
	is_hovering = true
	
	# Create ingredient card for preview
	if hover_card:
		hover_card.queue_free()
	
	var ingredient = item.ingredient
	hover_card = IngredientCardScene.instantiate()
	add_child(hover_card)
	
	# Set card data
	hover_card.set_ingredient(ingredient)
	
	# Position at center of screen
	hover_card.position = Vector2(640, 360) - hover_card.size / 2
	hover_card.z_index = 1000
	
	# Start at 240x300, scale up to 720x900 over time
	hover_card.scale = Vector2(0.5, 0.5)  # Start small (240x300 from base 480x600)
	
	# Kill existing tween
	if hover_tween:
		hover_tween.kill()
	
	# Smooth scale animation: quick to 240x300, then slow to 720x900
	hover_tween = create_tween()
	# First tween: instant to starting size
	hover_tween.tween_property(hover_card, "scale", Vector2(0.5, 0.5), 0.0)
	# Second tween: slowly scale to 1.5x (720x900 from base 480x600) over 3 seconds
	hover_tween.tween_property(hover_card, "scale", Vector2(1.5, 1.5), 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

## Handle sample hover end - remove preview card
func _on_sample_hover_end():
	is_hovering = false
	
	# Kill tween
	if hover_tween:
		hover_tween.kill()
		hover_tween = null
	
	# Remove hover card
	if hover_card:
		hover_card.queue_free()
		hover_card = null

## Purchase an item
func _purchase_item(item: Dictionary, panel: Panel):
	if shop_manager.purchase_item(item):
		print("[ShopScreen] Purchased: %s" % item.get("name", ""))
		panel.queue_free()
	else:
		_show_message("Cannot afford item!")

## Take a free sample
func _take_free_sample(item: Dictionary, button: Button):
	if free_samples_taken >= 2:
		_show_message("You already took 2 free samples!")
		return
	
	if fridge_manager and item.has("ingredient"):
		fridge_manager.add_ingredient_to_deck(item.ingredient)
		free_samples_taken += 1
		button.text = "TAKEN"
		button.disabled = true
		print("[ShopScreen] Free sample taken: %s (%d/2)" % [item.get("name", ""), free_samples_taken])

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
