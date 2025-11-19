extends Control

## Visual display of the plate with ingredients spread across it
## Shows current ingredients during cooking round

@onready var ingredient_container: HBoxContainer = $IngredientContainer

var current_ingredient_1: IngredientModel = null
var current_ingredient_2: IngredientModel = null

func _ready():
	# Connect to round events
	EventBus.round_started.connect(_on_round_started)
	EventBus.round_completed.connect(_on_round_completed)
	hide()

## Show plate with ingredients when round starts
func _on_round_started(ingredient_1: IngredientModel, ingredient_2: IngredientModel) -> void:
	current_ingredient_1 = ingredient_1
	current_ingredient_2 = ingredient_2
	
	# Build ingredients array (handle duplicate ingredient case)
	var ingredients: Array[IngredientModel] = []
	if ingredient_1:
		ingredients.append(ingredient_1)
	if ingredient_2 and ingredient_2 != ingredient_1:
		ingredients.append(ingredient_2)
	elif ingredient_2:
		# Same ingredient used twice, show it twice
		ingredients.append(ingredient_2)
	
	# Display ingredients on plate
	if ingredient_container:
		ingredient_container.display_ingredients(ingredients)
	
	show()

## Hide plate when round completes
func _on_round_completed(success: bool, final_moisture: float) -> void:
	hide()
