extends Panel

## UI for selecting 2 ingredients from a hand of 3 at game start

@onready var hand_grid: GridContainer = $VBoxContainer/HandGrid
@onready var confirm_button: Button = $VBoxContainer/ConfirmButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var info_label: Label = $VBoxContainer/InfoLabel

var hand_ingredients: Array[IngredientModel] = []  # 3 cards drawn
var selected_ingredients: Array[IngredientModel] = []  # 2 selected
var fridge_manager: FridgeManager

signal hand_selection_confirmed(ingredient_1: IngredientModel, ingredient_2: IngredientModel, discarded: IngredientModel)

func _ready():
	confirm_button.pressed.connect(_on_confirm_pressed)
	hide()

## Show hand selection with 3 cards
func show_hand_selection(fridge: FridgeManager) -> void:
	fridge_manager = fridge
	selected_ingredients.clear()
	
	# Draw 3 cards from fridge
	hand_ingredients = fridge_manager.draw_cards(3)
	
	# Update labels
	title_label.text = "Starting Hand"
	info_label.text = "Select 2 ingredients to cook (1 will be returned to deck)"
	
	# Populate hand cards
	_populate_hand()
	_update_confirm_button()
	
	show()

## Populate hand grid with ingredient cards
func _populate_hand() -> void:
	# Clear existing cards
	for child in hand_grid.get_children():
		child.queue_free()
	
	# Create selectable cards
	for ingredient in hand_ingredients:
		var card = _create_hand_card(ingredient)
		hand_grid.add_child(card)

## Create a selectable ingredient card
func _create_hand_card(ingredient: IngredientModel) -> Button:
	var card = Button.new()
	card.custom_minimum_size = Vector2(180, 140)
	
	# Build card text
	var card_text = "%s\n\n%s" % [ingredient.name, ingredient.get_stats_description()]
	
	# Add upgrade info if any
	var upgrade_desc = fridge_manager.get_upgrade_description(ingredient.name)
	if not upgrade_desc.is_empty():
		card_text += "\n" + upgrade_desc
	
	card.text = card_text
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Connect selection
	card.pressed.connect(_on_card_pressed.bind(ingredient, card))
	
	return card

## Handle card selection
func _on_card_pressed(ingredient: IngredientModel, card: Button) -> void:
	if ingredient in selected_ingredients:
		# Deselect
		selected_ingredients.erase(ingredient)
		card.modulate = Color.WHITE
	else:
		# Select (if under limit)
		if selected_ingredients.size() < 2:
			selected_ingredients.append(ingredient)
			card.modulate = Color.GREEN
		else:
			# Already have 2 selected - replace oldest selection
			var old_card = _find_card_for_ingredient(selected_ingredients[0])
			if old_card:
				old_card.modulate = Color.WHITE
			selected_ingredients[0] = ingredient
			card.modulate = Color.GREEN
	
	_update_confirm_button()

## Find the button widget for an ingredient
func _find_card_for_ingredient(ingredient: IngredientModel) -> Button:
	for child in hand_grid.get_children():
		if child is Button:
			# Check if this button's ingredient matches
			var idx = hand_ingredients.find(ingredient)
			var child_idx = child.get_index()
			if idx == child_idx:
				return child
	return null

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
