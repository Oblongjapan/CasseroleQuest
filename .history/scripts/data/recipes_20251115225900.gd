extends Node

## Singleton storing all recipe definitions

var recipes: Dictionary = {}

func _ready():
	_initialize_recipes()

func _initialize_recipes():
	# Phase 1 recipes (base ingredients)
	recipes["chicken_rice"] = RecipeModel.new(
		"chicken_rice",
		"Chicken+Rice",
		["Chicken Breast", "Rice"],
		80,  # water_content (50 + 30 = 80)
		63,  # heat_resistance (average of 55 + 70 + bonus)
		10   # volatility (average of 15 + 4, reduced)
	)
	
	recipes["bread_lettuce"] = RecipeModel.new(
		"bread_lettuce",
		"Lettuce Sandwich",
		["Bread", "Lettuce"],
		103,  # water_content (33 + 70 = 103)
		33,  # heat_resistance (average of 45 + 20)
		9    # volatility (average of 8 + 10)
	)
	
	recipes["steak_potato"] = RecipeModel.new(
		"steak_potato",
		"Steak+Potato",
		["Steak", "Potato"],
		115,  # water_content (55 + 60 = 115)
		60,  # heat_resistance
		15   # volatility
	)
	
	recipes["broccoli_chicken"] = RecipeModel.new(
		"broccoli_chicken",
		"Chicken+Broccoli",
		["Chicken Breast", "Broccoli"],
		110,  # water_content (50 + 60 = 110)
		48,  # heat_resistance
		17   # volatility
	)
	
	recipes["carrot_peas"] = RecipeModel.new(
		"carrot_peas",
		"Mixed Veggies",
		["Carrot", "Peas"],
		135,  # water_content (65 + 70 = 135)
		45,  # heat_resistance
		10   # volatility
	)
	
	# Phase 2 recipes (with unlocked ingredients - Spinach, Salmon)
	recipes["salmon_spinach"] = RecipeModel.new(
		"salmon_spinach",
		"Salmon+Spinach",
		["Salmon", "Spinach"],
		120,  # water_content (55 + 65 = 120)
		40,  # heat_resistance
		12   # volatility
	)
	
	recipes["chicken_rice_salmon"] = RecipeModel.new(
		"chicken_rice_salmon",
		"Chicken+Rice+Salmon",
		["Chicken Breast", "Rice", "Salmon"],
		135,  # water_content (50 + 30 + 55 = 135)
		58,  # heat_resistance
		11   # volatility
	)
	
	# More complex recipes can be added here
	recipes["mega_bowl"] = RecipeModel.new(
		"mega_bowl",
		"Mega Bowl",
		["Chicken Breast", "Rice", "Broccoli"],
		140,  # water_content (50 + 30 + 60 = 140)
		55,  # heat_resistance
		12   # volatility
	)

## Get a recipe by ID
func get_recipe(recipe_id: String) -> RecipeModel:
	if recipes.has(recipe_id):
		return recipes[recipe_id]
	return null

## Find a recipe that matches the given ingredients
func find_recipe_by_ingredients(ingredient_names: Array[String]) -> RecipeModel:
	# Strip "Organic " prefix from ingredient names if present
	var clean_names: Array[String] = []
	for ingredient_name in ingredient_names:
		clean_names.append(ingredient_name.replace("Organic ", ""))
	
	for recipe in recipes.values():
		if recipe.matches_ingredients(clean_names):
			return recipe
	
	return null

## Get all recipes as an array
func get_all_recipes() -> Array[RecipeModel]:
	var result: Array[RecipeModel] = []
	for key in recipes.keys():
		result.append(recipes[key])
	return result

## Check if ingredients form a valid recipe
func is_valid_recipe(ingredient_names: Array[String]) -> bool:
	return find_recipe_by_ingredients(ingredient_names) != null
