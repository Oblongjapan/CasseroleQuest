extends Panel

## UI controller for ingredient selection screen

@onready var ingredient_grid: GridContainer = $VBoxContainer/IngredientGrid
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var title_label: Label = $VBoxContainer/TitleLabel

var available_ingredients: Array[IngredientModel] = []
var selected_ingredients: Array[IngredientModel] = []
const MAX_SELECTIONS: int = 2

# Ingredient card scene (will be created dynamically)
const INGREDIENT_CARD_SCENE = preload("res://scenes/ui/ingredient_card.tscn")

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	hide()

## Show selector with random ingredient pool
func show_selector() -> void:
	selected_ingredients.clear()
	available_ingredients = IngredientsData.get_random_ingredient_pool(6)
	_populate_ingredients()
	show()
	_update_start_button()

## Create ingredient cards in grid
func _populate_ingredients() -> void:
	# Clear existing cards
	for child in ingredient_grid.get_children():
		child.queue_free()
	
	# Create new cards
	for ingredient in available_ingredients:
		var card = _create_ingredient_card(ingredient)
		ingredient_grid.add_child(card)

## Create a single ingredient card button
func _create_ingredient_card(ingredient: IngredientModel) -> Button:
	var card = Button.new()
	card.custom_minimum_size = Vector2(150, 120)
	card.text = "%s\n\n%s" % [ingredient.name, ingredient.get_stats_description()]
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Connect pressed signal
	card.pressed.connect(_on_ingredient_card_pressed.bind(ingredient, card))
	
	return card

## Handle ingredient card selection
func _on_ingredient_card_pressed(ingredient: IngredientModel, card: Button) -> void:
	if ingredient in selected_ingredients:
		# Deselect
		selected_ingredients.erase(ingredient)
		card.modulate = Color.WHITE
		EventBus.ingredient_deselected.emit(ingredient)
	else:
		# Select (if under limit)
		if selected_ingredients.size() < MAX_SELECTIONS:
			selected_ingredients.append(ingredient)
			card.modulate = Color.GREEN
			EventBus.ingredient_selected.emit(ingredient)
	
	_update_start_button()

## Enable/disable start button based on selection
func _update_start_button() -> void:
	start_button.disabled = selected_ingredients.size() != MAX_SELECTIONS
	
	if selected_ingredients.size() < MAX_SELECTIONS:
		start_button.text = "Select %d Ingredients" % MAX_SELECTIONS
	else:
		start_button.text = "Start Cooking!"

## Validate and start round
func _on_start_pressed() -> void:
	if selected_ingredients.size() == MAX_SELECTIONS:
		EventBus.selection_confirmed.emit(selected_ingredients[0], selected_ingredients[1])
		EventBus.round_started.emit(selected_ingredients[0], selected_ingredients[1])
		hide()
