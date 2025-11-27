extends Control

## UI for selecting ingredients from a hand of 3 using drag-and-drop
## Drag cards onto the microwave to select them

@onready var hand_container: HBoxContainer = $CenterContainer/VBoxContainer/HandContainer
@onready var title_label: Label = $CenterContainer/VBoxContainer/TopPanel/VBoxContainer/TitleLabel
@onready var info_label: Label = $CenterContainer/VBoxContainer/TopPanel/VBoxContainer/InfoLabel
@onready var drain_preview_label: Label = $CenterContainer/VBoxContainer/TopPanel/VBoxContainer/DrainPreviewLabel

var hand_ingredients: Array[IngredientModel] = []  # 3 cards drawn
var selected_ingredients: Array[IngredientModel] = []  # 1-2 selected via drag
var fridge_manager: FridgeManager
var card_buttons: Array[Control] = []  # Keep reference to card nodes
var hovered_card: Control = null
var dragging_card: Control = null
var drag_offset: Vector2 = Vector2.ZERO

const CARD_BASE_SIZE := Vector2(180, 260)
const CARD_HOVER_SCALE := 1.2
const CARD_SELECTED_COLOR := Color(0.3, 1.0, 0.3, 1.0)  # Green
const CARD_NORMAL_COLOR := Color(1.0, 1.0, 1.0, 1.0)  # White
const CARD_HOVER_OFFSET := -30.0  # Lift card up on hover

signal hand_selection_confirmed(ingredient_1: IngredientModel, ingredient_2: IngredientModel, discarded: IngredientModel)
signal selection_ready(can_start: bool)  # Emitted when 1-2 ingredients are selected

func _ready():
	print("[HandSelector] _ready() called")
	print("[HandSelector] hand_container: ", hand_container)
	print("[HandSelector] title_label: ", title_label)
	print("[HandSelector] info_label: ", info_label)
	
	# Set up layout
	custom_minimum_size = Vector2(1920, 1080)  # Full screen
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	print("[HandSelector] Initial visibility: ", visible)
	hide()

## Show hand selection with 3 cards
func show_hand_selection(fridge: FridgeManager) -> void:
	print("[HandSelector] show_hand_selection called")
	print("[HandSelector] Current visibility before show: ", visible)
	fridge_manager = fridge
	selected_ingredients.clear()
	card_buttons.clear()
	
	# Draw 3 cards from fridge
	hand_ingredients = fridge_manager.draw_cards(3)
	print("[HandSelector] Drew %d cards" % hand_ingredients.size())
	
	# Update labels
	if title_label:
		title_label.text = "Starting Hand"
		print("[HandSelector] Set title label")
	else:
		print("[HandSelector] WARNING: title_label is null!")
		
	if info_label:
		info_label.text = "Drag ingredients onto the microwave to select (1-2)"
		print("[HandSelector] Set info label")
	else:
		print("[HandSelector] WARNING: info_label is null!")
	
	# Populate hand cards
	_populate_hand()
	_update_selection_state()
	_update_drain_preview()
	
	# Wait one frame for layout, then animate cards in
	await get_tree().process_frame
	_animate_cards_draw()
	
	print("[HandSelector] About to show - calling show()")
	show()
	print("[HandSelector] After show() - visibility: ", visible)

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

## Animate cards being drawn into hand
func _animate_cards_draw() -> void:
	for i in range(card_buttons.size()):
		var card = card_buttons[i]
		# Store the final position after layout (use position relative to parent)
		var target_pos = card.position
		
		# Start cards off-screen at the bottom (relative position)
		card.position = target_pos + Vector2(0, 500)
		
		# Animate each card flying up into position with stagger
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(card, "position", target_pos, 0.5).set_delay(i * 0.1)
		
		# After animation completes, store the global position for drag/drop
		tween.finished.connect(func(): card.set_meta("original_global_position", card.global_position))

## Create a Slay the Spire style card with hover effects
func _create_slay_spire_card(ingredient: IngredientModel, index: int) -> IngredientCard:
	# Load and instantiate the card scene
	var card_scene = preload("res://scenes/ingredient_card.tscn")
	var card: IngredientCard = card_scene.instantiate()
	
	# Get upgrade description if any
	var upgrade_desc = fridge_manager.get_upgrade_description(ingredient.name)
	
	# Setup the card with ingredient data
	card.setup(ingredient, upgrade_desc)
	
	# Store metadata
	card.set_meta("ingredient", ingredient)
	card.set_meta("index", index)
	
	# Connect signals
	card.card_hovered.connect(_on_card_hover_start)
	card.card_unhovered.connect(_on_card_hover_end)
	card.card_input_event.connect(_on_card_input)
	
	return card

## Handle card hover start (Slay the Spire lift effect)
func _on_card_hover_start(card: IngredientCard) -> void:
	# End hover on any other card first
	if hovered_card and hovered_card != card:
		_on_card_hover_end(hovered_card)
	
	hovered_card = card
	
	# Kill any existing tweens on this card to prevent conflicts
	var existing_tween = card.get_meta("hover_tween", null)
	if existing_tween and existing_tween is Tween:
		existing_tween.kill()
	
	# Create smooth hover animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Lift card up and scale
	tween.tween_property(card, "position:y", CARD_HOVER_OFFSET, 0.25)
	tween.tween_property(card, "scale", Vector2(CARD_HOVER_SCALE, CARD_HOVER_SCALE), 0.25)
	
	# Brighten border
	var style = card.get_card_style()
	if style:
		tween.tween_property(style, "border_color", Color(0.8, 0.8, 1.0, 1.0), 0.25)
	
	# Move to front (z-index)
	card.z_index = 10
	
	# Store tween reference for cleanup
	card.set_meta("hover_tween", tween)

## Handle card hover end
func _on_card_hover_end(card: Control) -> void:
	# Always reset this card, even if it's not the tracked hovered_card
	if card == hovered_card:
		hovered_card = null
	
	# Kill any existing tweens on this card
	var existing_tween = card.get_meta("hover_tween", null)
	if existing_tween and existing_tween is Tween:
		existing_tween.kill()
	
	# Create smooth return animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Return to original position and scale
	tween.tween_property(card, "position:y", 0.0, 0.2)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Return border color based on selection state
	var style = card.get_meta("style") as StyleBoxFlat
	var ingredient = card.get_meta("ingredient") as IngredientModel
	if style and ingredient:
		var border_color = Color(0.4, 0.4, 0.5, 1.0)
		if ingredient in selected_ingredients:
			border_color = Color(0.3, 1.0, 0.3, 1.0)
		tween.tween_property(style, "border_color", border_color, 0.2)
	
	# Reset z-index
	card.z_index = 0
	
	# Store tween reference
	card.set_meta("hover_tween", tween)

## Handle card input (drag and drop)
func _on_card_input(event: InputEvent, card: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Start dragging
			dragging_card = card
			drag_offset = card.global_position - get_global_mouse_position()
			card.z_index = 100  # Bring to front while dragging
			
			# Original position is already stored from animation
		elif dragging_card == card:
			# End dragging - check if dropped on microwave
			_check_drop_on_microwave(card)
			dragging_card = null
			card.z_index = 0
	
	elif event is InputEventMouseMotion and dragging_card == card:
		# Update card position while dragging
		card.global_position = get_global_mouse_position() + drag_offset

## Check if card was dropped on microwave sprite
func _check_drop_on_microwave(card: Control) -> void:
	# Get microwave sprite from main scene
	var microwave = get_node_or_null("/root/Main/UI/Background/Microwave")
	if not microwave:
		print("[HandSelector] Warning: Microwave sprite not found")
		_snap_card_back(card)
		return
	
	# Check if mouse is over microwave using sprite_frames
	var mouse_pos = get_global_mouse_position()
	
	# Get sprite size from current animation frame
	var sprite_size = Vector2(200, 200)  # Default size
	if microwave.sprite_frames and microwave.sprite_frames.has_animation(microwave.animation):
		var frame_count = microwave.sprite_frames.get_frame_count(microwave.animation)
		if frame_count > 0:
			var texture = microwave.sprite_frames.get_frame_texture(microwave.animation, microwave.frame)
			if texture:
				sprite_size = texture.get_size()
	
	# Create rect centered on microwave position
	var microwave_rect = Rect2(microwave.global_position - sprite_size / 2, sprite_size)
	
	if microwave_rect.has_point(mouse_pos):
		# Dropped on microwave - toggle selection
		var ingredient = card.get_meta("ingredient") as IngredientModel
		_toggle_card_selection(ingredient, card)
	
	# Snap card back to original position
	_snap_card_back(card)

## Snap card back to its original position
func _snap_card_back(card: Control) -> void:
	var original_pos = card.get_meta("original_global_position", card.global_position)
	var tween = create_tween()
	tween.tween_property(card, "global_position", original_pos, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
			status_label.text = "Drag to Microwave"
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
						other_status.text = "Drag to Microwave"
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
	
	_update_selection_state()
	_update_drain_preview()

## Update selection state and emit signal
func _update_selection_state() -> void:
	var can_start = selected_ingredients.size() >= 1 and selected_ingredients.size() <= 2
	print("[HandSelector] _update_selection_state: %d ingredients selected, can_start: %s" % [selected_ingredients.size(), can_start])
	selection_ready.emit(can_start)

## Called by external ON button to confirm selection
func confirm_selection() -> void:
	print("[HandSelector] ========================================")
	print("[HandSelector] confirm_selection() called")
	print("[HandSelector] Selected ingredients: %d" % selected_ingredients.size())
	print("[HandSelector] ========================================")
	
	if selected_ingredients.size() < 1 or selected_ingredients.size() > 2:
		print("[HandSelector] Cannot confirm: need 1-2 ingredients selected")
		return
	
	# All cards from the hand go to discard pile (both used and unused)
	fridge_manager.discard_cards(hand_ingredients)
	
	# Emit signal with selection (handle 1 or 2 ingredients)
	if selected_ingredients.size() == 2:
		print("[HandSelector] Emitting hand_selection_confirmed with 2 ingredients")
		hand_selection_confirmed.emit(selected_ingredients[0], selected_ingredients[1], null)
	else:
		# Solo ingredient - emit same ingredient twice
		print("[HandSelector] Emitting hand_selection_confirmed with 1 ingredient (solo)")
		hand_selection_confirmed.emit(selected_ingredients[0], selected_ingredients[0], null)
	
	print("[HandSelector] Hiding hand selector")
	hide()

## Update drain rate preview based on selected ingredients
func _update_drain_preview() -> void:
	if not drain_preview_label:
		return
	
	if selected_ingredients.is_empty():
		drain_preview_label.text = "Select ingredients to see drain preview"
		return
	
	var ing1 = selected_ingredients[0]
	var ing2 = selected_ingredients[1] if selected_ingredients.size() == 2 else selected_ingredients[0]
	
	# Calculate preview stats (handle solo cooking)
	var combined_water: float
	var worst_spice: float
	var best_heat: float
	
	if selected_ingredients.size() == 2:
		# Duo cooking
		combined_water = ing1.water_content + ing2.water_content
		worst_spice = max(ing1.volatility, ing2.volatility)
		best_heat = max(ing1.heat_resistance, ing2.heat_resistance)
	else:
		# Solo cooking (use same ingredient twice logic)
		combined_water = ing1.water_content
		worst_spice = ing1.volatility
		best_heat = ing1.heat_resistance
	
	# Use the correct formula (0.15 multiplier like in moisture_manager)
	var estimated_drain = 5.0 + (worst_spice * 0.3) - (best_heat * 0.15)
	estimated_drain = max(0.5, estimated_drain)
	
	drain_preview_label.text = "Starting Moisture: %d\nEstimated Drain: ~%.1f/sec" % [
		int(combined_water),
		estimated_drain
	]
