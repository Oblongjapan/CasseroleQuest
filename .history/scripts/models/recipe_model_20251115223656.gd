class_name RecipeModel
extends Resource

## Model for recipe cards - combinations of ingredients

## Unique identifier for this recipe
@export var id: String = ""

## Display name (e.g., "Chicken+Rice")
@export var name: String = ""

## Array of ingredient names required to make this recipe
@export var required_ingredients: Array[String] = []

## Stats for the recipe card
@export var water_content: int = 0
@export var heat_resistance: int = 0
@export var volatility: int = 0

## Whether this recipe has been created
@export var is_unlocked: bool = false

func _init(
	p_id: String = "",
	p_name: String = "",
	p_required_ingredients: Array[String] = [],
	p_water_content: int = 0,
	p_heat_resistance: int = 0,
	p_volatility: int = 0
):
	id = p_id
	name = p_name
	required_ingredients = p_required_ingredients.duplicate()
	water_content = p_water_content
	heat_resistance = p_heat_resistance
	volatility = p_volatility

## Check if the given ingredients match this recipe
func matches_ingredients(ingredient_names: Array[String]) -> bool:
	if ingredient_names.size() != required_ingredients.size():
		return false
	
	# Sort both arrays and compare
	var sorted_input = ingredient_names.duplicate()
	var sorted_required = required_ingredients.duplicate()
	sorted_input.sort()
	sorted_required.sort()
	
	for i in range(sorted_input.size()):
		if sorted_input[i] != sorted_required[i]:
			return false
	
	return true

## Create an IngredientModel from this recipe
func to_ingredient_model() -> IngredientModel:
	return IngredientModel.new(
		name,
		water_content,
		heat_resistance,
		volatility
	)
