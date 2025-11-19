extends Control

## UI for selecting ingredients from a hand of 3 using drag-and-drop
## Drag cards onto the microwave to select them

@onready var hand_container: Control = get_node_or_null("VBoxContainer/HandContainer") as Control
@onready var title_label: Label = null  # Removed from scene
@onready var info_label: Label = null  # Removed from scene
@onready var drain_preview_label: Label = get_node_or_null("VBoxContainer/TopPanel/VBoxContainer/DrainPreviewLabel") as Label

var hand_ingredients: Array[IngredientModel] = []  # 3 cards drawn
var selected_ingredients: Array[IngredientModel] = []  # 1-2 selected via drag
var fridge_manager: FridgeManager
var game_state_manager: GameStateManager  # For water cup check
var card_buttons: Array[IngredientCard] = []  # Keep reference to card nodes
var hovered_card: IngredientCard = null
var dragging_card: IngredientCard = null
var drag_offset: Vector2 = Vector2.ZERO

const CARD_BASE_SIZE := Vector2(180, 260)
const CARD_HOVER_SCALE := 1.2
const CARD_SELECTED_COLOR := Color(0.3, 1.0, 0.3, 1.0)  # Green
const CARD_NORMAL_COLOR := Color(1.0, 1.0, 1.0, 1.0)  # White
const CARD_HOVER_OFFSET := -30.0  # Lift card up on hover
const CARD_SPACING := 40.0  # Horizontal spacing between cards in hand (for manual layout)

signal hand_selection_confirmed(ingredient_1: IngredientModel, ingredient_2: IngredientModel, discarded: IngredientModel)
signal selection_ready(can_start: bool)  # Emitted when 1-2 ingredients are selected
signal ingredient_selected(ingredient: IngredientModel, overlay_index: int)  # overlay_index: which overlay slot (0 or 1) to use
signal ingredient_deselected(overlay_index: int)  # overlay_index: which overlay slot (0 or 1) was freed

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

## Show hand selection with cards
## If after_shop is true, clears hand and draws 5 new cards
## If after_shop is false (between rounds), draws 1 card to add to existing hand
func show_hand_selection(fridge: FridgeManager, game_state_mgr: GameStateManager = null, after_shop: bool = false) -> void:
	print("[HandSelector] show_hand_selection called (after_shop: %s)" % after_shop)
	print("[HandSelector] Current visibility before show: ", visible)
	fridge_manager = fridge
	game_state_manager = game_state_mgr
	selected_ingredients.clear()
	card_buttons.clear()
	
	# Check if we should add Water Cup from first shop visit
	_check_and_add_water_cup()
	
	# Handle card drawing based on context
	if after_shop:
		# After shop: discard any remaining cards in hand, then draw 5 new cards
		if hand_ingredients.size() > 0:
			print("[HandSelector] Discarding %d remaining cards from previous hand" % hand_ingredients.size())
			fridge_manager.discard_cards(hand_ingredients)
		hand_ingredients.clear()
		var new_cards = fridge_manager.draw_cards(5)
		hand_ingredients.append_array(new_cards)
		print("[HandSelector] After shop - drew 5 new cards, hand size: %d" % hand_ingredients.size())
	else:
		# Between rounds: draw 1 card to add to existing hand
		var new_cards = fridge_manager.draw_cards(1)
		hand_ingredients.append_array(new_cards)
		print("[HandSelector] Between rounds - drew 1 card, hand size now: %d" % hand_ingredients.size())
	
	# Safety check - if no cards were drawn, something is wrong with the deck
	if hand_ingredients.is_empty():
		print("[HandSelector] ERROR: No cards were drawn! Deck and discard might both be empty!")
		return
	
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
	# Clear existing cards immediately (not deferred) to ensure clean layout
	if hand_container:
		for child in hand_container.get_children():
			hand_container.remove_child(child)
			child.queue_free()
	
	# Wait for removal and layout to complete
	await get_tree().process_frame
	
	print("[HandSelector] Populating hand with %d ingredients" % hand_ingredients.size())
	
	# Cards are positioned manually (not using HBoxContainer auto-layout) so they spread across the hand
	# Spacing and centering are computed below to prevent cards from stacking
	var spacing := CARD_SPACING
	var n := hand_ingredients.size()

	# Get container width - prefer custom_minimum_size for consistency, fallback to size or default
	var container_width: float = 800.0  # Default fallback
	if hand_container:
		if hand_container.custom_minimum_size.x > 10:
			container_width = hand_container.custom_minimum_size.x
		elif hand_container.size.x > 10:
			container_width = hand_container.size.x
		print("[HandSelector] Using container width: %.1f" % container_width)

	# Estimate card width from base size (cards might scale, but base is fine for layout)
	var card_w := CARD_BASE_SIZE.x
	var total_width := card_w * n + spacing * (n - 1)
	var start_x := (container_width - total_width) / 2.0

	for i in range(n):
		var ingredient = hand_ingredients[i]
		var card = _create_slay_spire_card(ingredient, i)
		if hand_container:
			hand_container.add_child(card)

			# Now that card is in tree, _ready has been called and we can setup
			var pending_ingredient = card.get_meta("pending_ingredient") as IngredientModel
			var pending_upgrade = card.get_meta("pending_upgrade", "") as String
			card.setup(pending_ingredient, pending_upgrade)

			# Compute desired position for this card (centered horizontally in container)
			var target_x := start_x + i * (card_w + spacing)
			var target_pos := Vector2(target_x, 0)

			# Set initial position to the target so animation can use it
			card.position = target_pos

			card_buttons.append(card)
			print("[HandSelector] Added card %d: %s (size: %v) pos: %v" % [i, ingredient.name, card.size, target_pos])

## Animate cards being drawn into hand
func _animate_cards_draw() -> void:
	print("[HandSelector] Starting card animation, cards count: %d" % card_buttons.size())
	for i in range(card_buttons.size()):
		var card = card_buttons[i]
		# Store the final position after layout (use position relative to parent)
		var target_pos = card.position
		
		print("[HandSelector] Card %d - target_pos: %v, size: %v, global_pos: %v" % [i, target_pos, card.size, card.global_position])
		
		# Start cards off-screen at the bottom (relative position)
		card.position = target_pos + Vector2(0, 500)
		
		# Animate each card flying up into position with stagger
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(card, "position", target_pos, 0.5).set_delay(i * 0.1)
		
		# After animation completes, store the global position for drag/drop
		# Capture card in a local variable to avoid scope issues
		var card_ref = card
		tween.finished.connect(func(): 
			if card_ref and is_instance_valid(card_ref):
				card_ref.set_meta("original_global_position", card_ref.global_position)
				print("[HandSelector] Card %d animation finished - final global_pos: %v" % [i, card_ref.global_position])
		)

## Create a Slay the Spire style card with hover effects
func _create_slay_spire_card(ingredient: IngredientModel, index: int) -> IngredientCard:
	# Load and instantiate the card scene
	var card_scene = preload("res://scenes/ingredient_card.tscn")
	var card: IngredientCard = card_scene.instantiate()
	
	# Get upgrade description if any
	var upgrade_desc = fridge_manager.get_upgrade_description(ingredient.name)
	
	# Store data for setup after _ready
	card.set_meta("pending_ingredient", ingredient)
	card.set_meta("pending_upgrade", upgrade_desc)
	
	# Connect signals
	card.card_hovered.connect(_on_card_hover_start)
	card.card_unhovered.connect(_on_card_hover_end)
	card.card_input_event.connect(_on_card_input)
	
	return card

## Handle card hover start (Slay the Spire lift effect)
func _on_card_hover_start(card) -> void:
	# Check if card is still valid (not freed)
	if not is_instance_valid(card):
		return
	
	# Ignore hover events while dragging any card
	if dragging_card:
		return
	
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
func _on_card_hover_end(card) -> void:
	# Check if card is still valid (not freed)
	if not is_instance_valid(card):
		return
	
	# Ignore hover events while dragging any card
	if dragging_card:
		return
	
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
	var style = card.get_card_style()
	var ingredient = card.ingredient
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
func _on_card_input(event: InputEvent, card) -> void:
	# Check if card is still valid (not freed)
	if not is_instance_valid(card):
		return
	
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
func _check_drop_on_microwave(card: IngredientCard) -> void:
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
		var ingredient = card.ingredient
		_toggle_card_selection(ingredient, card)
	
	# Snap card back to original position
	_snap_card_back(card)

## Snap card back to its original position
func _snap_card_back(card: IngredientCard) -> void:
	var original_pos = card.get_meta("original_global_position", card.global_position)
	var tween = create_tween()
	tween.tween_property(card, "global_position", original_pos, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Toggle card selection
func _toggle_card_selection(ingredient: IngredientModel, card: IngredientCard) -> void:
	if ingredient in selected_ingredients:
		# Deselect - find which overlay slot this card is using
		var index = selected_ingredients.find(ingredient)
		var overlay_slot = card.get_meta("overlay_index", -1)
		selected_ingredients.erase(ingredient)
		card.set_selected(false)
		card.show()  # Show the card again
		
		# Clear the overlay assignment for this card
		card.set_meta("overlay_index", -1)
		print("[HandSelector] Deselecting %s from overlay slot %d" % [ingredient.name, overlay_slot])
		ingredient_deselected.emit(overlay_slot)
	else:
		# Select (if under limit)
		if selected_ingredients.size() < 2:
			# Find first available overlay slot (0 or 1)
			var overlay_slot = _find_available_overlay_slot()
			
			selected_ingredients.append(ingredient)
			card.set_selected(true)
			card.hide()  # Hide the card when selected
			
			# Tether this card to the overlay slot
			card.set_meta("overlay_index", overlay_slot)
			print("[HandSelector] Selecting %s to overlay slot %d" % [ingredient.name, overlay_slot])
			ingredient_selected.emit(ingredient, overlay_slot)
		else:
			# Already have 2 selected - replace oldest
			var old_ingredient = selected_ingredients[0]
			var old_overlay_slot = -1
			
			# Find and update old card, get its overlay slot
			for other_card in card_buttons:
				if other_card.ingredient == old_ingredient:
					old_overlay_slot = other_card.get_meta("overlay_index", 0)
					other_card.set_selected(false)
					other_card.show()  # Show the old card again
					other_card.set_meta("overlay_index", -1)
					print("[HandSelector] Deselecting %s from overlay slot %d (replacing)" % [old_ingredient.name, old_overlay_slot])
					break
			
			selected_ingredients.erase(old_ingredient)
			ingredient_deselected.emit(old_overlay_slot)
			
			# Select new card using the same overlay slot that was freed
			selected_ingredients.append(ingredient)
			card.set_selected(true)
			card.hide()  # Hide the new card
			card.set_meta("overlay_index", old_overlay_slot)
			print("[HandSelector] Selecting %s to overlay slot %d (replacement)" % [ingredient.name, old_overlay_slot])
			ingredient_selected.emit(ingredient, old_overlay_slot)
	
	_update_selection_state()
	_update_drain_preview()

## Find the first available overlay slot (0 or 1)
func _find_available_overlay_slot() -> int:
	# Check which slots are currently in use
	var slot_0_used = false
	var slot_1_used = false
	
	for card in card_buttons:
		var slot = card.get_meta("overlay_index", -1)
		if slot == 0:
			slot_0_used = true
		elif slot == 1:
			slot_1_used = true
	
	# Return first available slot
	if not slot_0_used:
		return 0
	elif not slot_1_used:
		return 1
	else:
		return 0  # Fallback (shouldn't happen)

## Update selection state and emit signal
func _update_selection_state() -> void:
	var can_start = selected_ingredients.size() >= 1 and selected_ingredients.size() <= 2
	print("[HandSelector] _update_selection_state: %d ingredients selected, can_start: %s" % [selected_ingredients.size(), can_start])
	
	selection_ready.emit(can_start)

## Deselect ingredient by overlay index (called when overlay is dragged out)
func deselect_by_index(overlay_index: int) -> void:
	# Find the card that's using this overlay slot
	var card_to_deselect: IngredientCard = null
	
	for card in card_buttons:
		if card.get_meta("overlay_index", -1) == overlay_index:
			card_to_deselect = card
			break
	
	if not card_to_deselect:
		print("[HandSelector] Warning: No card found for overlay index %d" % overlay_index)
		return
	
	var ingredient = card_to_deselect.ingredient
	
	# Remove from selected ingredients
	if ingredient in selected_ingredients:
		selected_ingredients.erase(ingredient)
	
	# Show the card again and clear its overlay assignment
	card_to_deselect.set_selected(false)
	card_to_deselect.show()
	card_to_deselect.set_meta("overlay_index", -1)
	
	_update_selection_state()
	_update_drain_preview()

## Deselect ingredient by name (called when overlay is dragged out)
func deselect_by_ingredient_name(ingredient_name: String) -> void:
	# Find the card with this ingredient
	var card_to_deselect: IngredientCard = null
	
	for card in card_buttons:
		if card.ingredient and card.ingredient.name == ingredient_name:
			card_to_deselect = card
			break
	
	if not card_to_deselect:
		print("[HandSelector] Warning: No card found for ingredient: %s" % ingredient_name)
		return
	
	var ingredient = card_to_deselect.ingredient
	
	# Remove from selected ingredients
	if ingredient in selected_ingredients:
		selected_ingredients.erase(ingredient)
		print("[HandSelector] Deselected %s by name" % ingredient_name)
	
	# Show the card again and clear its overlay assignment
	card_to_deselect.set_selected(false)
	card_to_deselect.show()
	card_to_deselect.set_meta("overlay_index", -1)
	
	_update_selection_state()
	_update_drain_preview()

## Called by external ONButton (microwave button) via microwave_start_button.gd
func external_start() -> void:
	confirm_selection()

## Called by external ONButton (microwave button) to confirm selection
func confirm_selection() -> void:
	print("[HandSelector] ========================================")
	print("[HandSelector] confirm_selection() called")
	print("[HandSelector] Selected ingredients: %d" % selected_ingredients.size())
	print("[HandSelector] hand_ingredients count: %d" % hand_ingredients.size())
	print("[HandSelector] ========================================")
	
	if selected_ingredients.size() < 1 or selected_ingredients.size() > 2:
		print("[HandSelector] Cannot confirm: need 1-2 ingredients selected")
		return
	
	# Remove selected cards from hand_ingredients
	# Unselected cards stay in hand for next round
	print("[HandSelector] Removing %d selected cards from hand..." % selected_ingredients.size())
	for ingredient in selected_ingredients:
		hand_ingredients.erase(ingredient)
	
	print("[HandSelector] Remaining cards in hand: %d" % hand_ingredients.size())
	print("[HandSelector] Selected cards will be handled by main.gd (discarded or consumed for recipe)")
	
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
	var avg_spice: float
	var avg_heat: float
	
	if selected_ingredients.size() == 2:
		# Duo cooking
		combined_water = ing1.water_content + ing2.water_content
		avg_spice = (ing1.volatility + ing2.volatility) / 2.0
		avg_heat = (ing1.heat_resistance + ing2.heat_resistance) / 2.0
	else:
		# Solo cooking (use same ingredient twice logic)
		combined_water = ing1.water_content
		avg_spice = ing1.volatility
		avg_heat = ing1.heat_resistance
	
	# Use the correct formula (updated multipliers to match moisture_manager)
	var estimated_drain = 5.0 + (avg_spice * 0.4) - (avg_heat * 0.10)
	estimated_drain = max(0.5, estimated_drain)
	
	drain_preview_label.text = "Starting Moisture: %d\nEstimated Drain: ~%.1f/sec" % [
		int(combined_water),
		estimated_drain
	]

## Check if we should add Water Cup from first shop visit
func _check_and_add_water_cup() -> void:
	if not game_state_manager:
		print("[HandSelector] No game_state_manager, skipping water cup check")
		return
	
	# Check if we should give water cup
	if game_state_manager.should_give_water_cup:
		game_state_manager.should_give_water_cup = false
		print("[HandSelector] Water cup flag is TRUE! Adding Water Cup to hand")
		
		# Create Water Cup ingredient
		var water_cup = IngredientModel.new(
			"Water Cup",
			100,  # water_content
			0,    # heat_resistance
			0     # volatility
		)
		
		# Add to hand
		hand_ingredients.append(water_cup)
		print("[HandSelector] Added Water Cup to hand as gift!")
	else:
		print("[HandSelector] Water cup flag is false, not adding")
