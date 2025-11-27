extends Control

## UI for selecting 2 ingredients from a hand of 3 at game start
## Slay the Spire style card hand with hover effects

@onready var hand_container: HBoxContainer = $CenterContainer/VBoxContainer/HandContainer
@onready var confirm_button: Button = $CenterContainer/VBoxContainer/BottomPanel/ConfirmButton
@onready var title_label: Label = $CenterContainer/VBoxContainer/TopPanel/TitleLabel
@onready var info_label: Label = $CenterContainer/VBoxContainer/TopPanel/InfoLabel

var hand_ingredients: Array[IngredientModel] = []  # 3 cards drawn
var selected_ingredients: Array[IngredientModel] = []  # 2 selected
var fridge_manager: FridgeManager
var card_buttons: Array[Control] = []  # Keep reference to card nodes
var hovered_card: Control = null

const CARD_BASE_SIZE := Vector2(180, 260)
const CARD_HOVER_SCALE := 1.2
const CARD_SELECTED_COLOR := Color(0.3, 1.0, 0.3, 1.0)  # Green
const CARD_NORMAL_COLOR := Color(1.0, 1.0, 1.0, 1.0)  # White
const CARD_HOVER_OFFSET := -30.0  # Lift card up on hover

signal hand_selection_confirmed(ingredient_1: IngredientModel, ingredient_2: IngredientModel, discarded: IngredientModel)

func _ready():
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	else:
		push_error("[HandSelector] ConfirmButton not found!")
	
	# Set up layout
	custom_minimum_size = Vector2(1920, 1080)  # Full screen
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	hide()

## Show hand selection with 3 cards
func show_hand_selection(fridge: FridgeManager) -> void:
	print("[HandSelector] show_hand_selection called")
	fridge_manager = fridge
	selected_ingredients.clear()
	card_buttons.clear()
	
	# Draw 3 cards from fridge
	hand_ingredients = fridge_manager.draw_cards(3)
	print("[HandSelector] Drew %d cards" % hand_ingredients.size())
	
	# Update labels
	if title_label:
		title_label.text = "Starting Hand"
	if info_label:
		info_label.text = "Select 2 ingredients to cook • 1 will return to deck"
	
	# Populate hand cards
	_populate_hand()
	_update_confirm_button()
	
	print("[HandSelector] Showing panel")
	show()

## Populate hand container with ingredient cards (Slay the Spire style)
func _populate_hand() -> void:
	# Clear existing cards
	if hand_container:
		for child in hand_container.get_children():
			child.queue_free()
	
	# Create card for each ingredient
	for i in range(hand_ingredients.size()):
		var ingredient = hand_ingredients[i]
		var card = _create_slay_spire_card(ingredient, i)
		if hand_container:
			hand_container.add_child(card)
			card_buttons.append(card)

## Create a Slay the Spire style card with hover effects
func _create_slay_spire_card(ingredient: IngredientModel, index: int) -> Control:
	var card_container = Control.new()
	card_container.custom_minimum_size = CARD_BASE_SIZE
	card_container.size = CARD_BASE_SIZE
	card_container.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Create card panel
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = CARD_BASE_SIZE
	card_panel.size = CARD_BASE_SIZE
	card_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Add style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.4, 0.4, 0.5, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	card_panel.add_theme_stylebox_override("panel", style)
	
	# Main VBox for card content
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	
	# Header with ingredient name
	var name_panel = PanelContainer.new()
	var name_style = StyleBoxFlat.new()
	name_style.bg_color = Color(0.25, 0.25, 0.35, 1.0)
	name_panel.add_theme_stylebox_override("panel", name_style)
	
	var name_label = Label.new()
	name_label.text = ingredient.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1.0))
	name_panel.add_child(name_label)
	vbox.add_child(name_panel)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer1)
	
	# Stats section
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 5)
	
	# Water stat
	var water_hbox = HBoxContainer.new()
	var water_icon = Label.new()
	water_icon.text = "💧"
	water_icon.add_theme_font_size_override("font_size", 20)
	water_hbox.add_child(water_icon)
	var water_label = Label.new()
	water_label.text = "Water: %d" % ingredient.water_content
	water_label.add_theme_font_size_override("font_size", 16)
	water_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	water_hbox.add_child(water_label)
	stats_vbox.add_child(water_hbox)
	
	# Heat stat
	var heat_hbox = HBoxContainer.new()
	var heat_icon = Label.new()
	heat_icon.text = "🔥"
	heat_icon.add_theme_font_size_override("font_size", 20)
	heat_hbox.add_child(heat_icon)
	var heat_label = Label.new()
	heat_label.text = "Heat: %d" % ingredient.heat_resistance
	heat_label.add_theme_font_size_override("font_size", 16)
	heat_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3, 1.0))
	heat_hbox.add_child(heat_label)
	stats_vbox.add_child(heat_hbox)
	
	# Spice stat
	var spice_hbox = HBoxContainer.new()
	var spice_icon = Label.new()
	spice_icon.text = "🌶️"
	spice_icon.add_theme_font_size_override("font_size", 20)
	spice_hbox.add_child(spice_icon)
	var spice_label = Label.new()
	spice_label.text = "Spice: %d" % ingredient.volatility
	spice_label.add_theme_font_size_override("font_size", 16)
	spice_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	spice_hbox.add_child(spice_label)
	stats_vbox.add_child(spice_hbox)
	
	vbox.add_child(stats_vbox)
	
	# Add upgrade info if any
	var upgrade_desc = fridge_manager.get_upgrade_description(ingredient.name)
	if not upgrade_desc.is_empty():
		var spacer2 = Control.new()
		spacer2.custom_minimum_size = Vector2(0, 10)
		vbox.add_child(spacer2)
		
		var upgrade_label = Label.new()
		upgrade_label.text = "✨ " + upgrade_desc
		upgrade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		upgrade_label.add_theme_font_size_override("font_size", 13)
		upgrade_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
		upgrade_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(upgrade_label)
	
	# Add spacer to push status to bottom
	var spacer3 = Control.new()
	spacer3.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer3)
	
	# Selection status indicator at bottom
	var status_label = Label.new()
	status_label.text = "Click to Select"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	status_label.name = "StatusLabel"
	vbox.add_child(status_label)
	
	card_panel.add_child(vbox)
	card_container.add_child(card_panel)
	
	# Store ingredient reference
	card_container.set_meta("ingredient", ingredient)
	card_container.set_meta("index", index)
	card_container.set_meta("card_panel", card_panel)
	card_container.set_meta("status_label", status_label)
	card_container.set_meta("style", style)
	
	# Connect mouse events for hover and click
	card_container.mouse_entered.connect(_on_card_hover_start.bind(card_container))
	card_container.mouse_exited.connect(_on_card_hover_end.bind(card_container))
	card_container.gui_input.connect(_on_card_input.bind(card_container))
	
	return card_container

## Handle card hover start (Slay the Spire lift effect)
func _on_card_hover_start(card: Control) -> void:
	if hovered_card and hovered_card != card:
		_on_card_hover_end(hovered_card)
	
	hovered_card = card
	
	# Create hover animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Lift card up and scale
	tween.tween_property(card, "position:y", CARD_HOVER_OFFSET, 0.2)
	tween.tween_property(card, "scale", Vector2(CARD_HOVER_SCALE, CARD_HOVER_SCALE), 0.2)
	
	# Brighten border
	var style = card.get_meta("style") as StyleBoxFlat
	if style:
		tween.tween_property(style, "border_color", Color(0.8, 0.8, 1.0, 1.0), 0.2)
	
	# Move to front (z-index)
	card.z_index = 10

## Handle card hover end
func _on_card_hover_end(card: Control) -> void:
	if card == hovered_card:
		hovered_card = null
	
	# Create return animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Return to original position and scale
	tween.tween_property(card, "position:y", 0.0, 0.15)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.15)
	
	# Return border color
	var style = card.get_meta("style") as StyleBoxFlat
	var ingredient = card.get_meta("ingredient") as IngredientModel
	if style and ingredient:
		var border_color = Color(0.4, 0.4, 0.5, 1.0)
		if ingredient in selected_ingredients:
			border_color = Color(0.3, 1.0, 0.3, 1.0)
		tween.tween_property(style, "border_color", border_color, 0.15)
	
	# Reset z-index
	card.z_index = 0

## Handle card click/input
func _on_card_input(event: InputEvent, card: Control) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var ingredient = card.get_meta("ingredient") as IngredientModel
			_toggle_card_selection(ingredient, card)

## Toggle card selection
func _toggle_card_selection(ingredient: IngredientModel, card: Control) -> void:
	var style = card.get_meta("style") as StyleBoxFlat
	var status_label = card.get_meta("status_label") as Label
	
	if ingredient in selected_ingredients:
		# Deselect
		selected_ingredients.erase(ingredient)
		if style:
			style.border_color = Color(0.4, 0.4, 0.5, 1.0)
			style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
		if status_label:
			status_label.text = "Click to Select"
			status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	else:
		# Select (if under limit)
		if selected_ingredients.size() < 2:
			selected_ingredients.append(ingredient)
			if style:
				style.border_color = Color(0.3, 1.0, 0.3, 1.0)
				style.bg_color = Color(0.15, 0.25, 0.15, 0.95)
			if status_label:
				status_label.text = "✓ SELECTED"
				status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
		else:
			# Deselect oldest and select this one
			var old_ingredient = selected_ingredients[0]
			selected_ingredients.erase(old_ingredient)
			
			# Find and update old card
			for other_card in card_buttons:
				var other_ing = other_card.get_meta("ingredient") as IngredientModel
				if other_ing == old_ingredient:
					var other_style = other_card.get_meta("style") as StyleBoxFlat
					var other_status = other_card.get_meta("status_label") as Label
					if other_style:
						other_style.border_color = Color(0.4, 0.4, 0.5, 1.0)
						other_style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
					if other_status:
						other_status.text = "Click to Select"
						other_status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
					break
			
			# Select new card
			selected_ingredients.append(ingredient)
			if style:
				style.border_color = Color(0.3, 1.0, 0.3, 1.0)
				style.bg_color = Color(0.15, 0.25, 0.15, 0.95)
			if status_label:
				status_label.text = "✓ SELECTED"
				status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	
	_update_confirm_button()

## Update confirm button state
func _update_confirm_button() -> void:
	if selected_ingredients.size() == 2:
		confirm_button.disabled = false
		confirm_button.text = "Cook These 2 Ingredients"
	else:
		confirm_button.disabled = true
		confirm_button.text = "Select 2 Ingredients (%d/2)" % selected_ingredients.size()

## Handle confirm button
func _on_confirm_pressed() -> void:
	if selected_ingredients.size() != 2:
		return
	
	# Find the discarded ingredient
	var discarded: IngredientModel = null
	for ingredient in hand_ingredients:
		if ingredient not in selected_ingredients:
			discarded = ingredient
			break
	
	# Return discarded card to deck (top)
	if discarded:
		fridge_manager.deck.push_front(discarded)
	
	# Discard the 2 selected cards (they'll be used this round)
	fridge_manager.discard_cards(selected_ingredients)
	
	# Emit signal with selection
	hand_selection_confirmed.emit(selected_ingredients[0], selected_ingredients[1], discarded)
	
	hide()
