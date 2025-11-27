extends Node

## Singleton storing all recipe definitions and tier system

var recipes: Dictionary = {}

# Recipe tier system - Clear progression gates
# TIER 0: Base ingredients (always available)
# TIER 1: 2-ingredient recipes ONLY (unlocked at game start)
# TIER 2: 3+ ingredient recipes (LOCKED until 6 unique 2-ingredient recipes created)
# TIER 3: Advanced recipes with more complex mechanics
# TIER 4: Legendary/endgame recipes

const TIER_0_UNLOCK_THRESHOLD = 0   # Base ingredients - always available
const TIER_1_UNLOCK_THRESHOLD = 0   # 2-ingredient recipes - unlocked at game start
const TIER_2_UNLOCK_THRESHOLD = 6   # 3+ ingredient recipes - REQUIRES 6 unique 2-ingredient recipes
const TIER_3_UNLOCK_THRESHOLD = 30  # Advanced recipes - after 30 total recipes
const TIER_4_UNLOCK_THRESHOLD = 42  # Legendary recipes - after 42 total recipes

# Maximum ingredients allowed per tier
const TIER_1_MAX_INGREDIENTS = 2    # Tier 1 limited to 2-ingredient recipes
const TIER_2_MAX_INGREDIENTS = 99   # Tier 2+ allows any number of ingredients

# Tier 0: Base ingredients (always available)
const TIER_0_INGREDIENTS = [
	"Chicken Breast", "Steak", "Tofu", "Potato", "Rice", 
	"Peas", "Bread", "Lettuce", "Spinach", "Asparagus", "Carrot"
]

# Signal emitted when a new tier is unlocked
signal tier_unlocked(tier_number: int)

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

	recipes["Chicken Sandwhich"] = RecipeModel.new(
		"chicken_sandwhich",
		"Chicken Sandwhich",
		["Chicken Breast", "Bread"],
		83,  # water_content (50 + 33 = 83)
		50,  # heat_resistance
		11.5    # volatility
	)

	recipes["Hot Chicken Sandwhich"] = RecipeModel.new(
        "hot_chicken_sandwhich",
        "Hot Chicken Sandwhich",
        ["Chicken Sandwhich", "Peas"],
        153,  # water_content (83 + 70 = 153)
        45,  # heat_resistance
        9.5   # volatility
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

## Combine multiple ingredients into a new recipe card
## Water = sum, Heat Resistance = average, Volatility = average
## Returns null if the combination is not allowed based on current tier
func combine_ingredients(ingredients: Array[IngredientModel], current_tier: int = 1) -> IngredientModel:
	print("[RecipesData] === combine_ingredients called ===")
	print("[RecipesData] Input ingredients count: %d" % ingredients.size())
	print("[RecipesData] Current tier: %d" % current_tier)
	
	if ingredients.size() == 0:
		print("[RecipesData] ERROR: No ingredients provided!")
		return null
	
	# TIER RESTRICTION: Check if this combination is allowed based on current tier
	if current_tier < 2 and ingredients.size() > TIER_1_MAX_INGREDIENTS:
		print("[RecipesData] ❌ BLOCKED: %d-ingredient recipe requires Tier 2! (Current: Tier %d)" % [ingredients.size(), current_tier])
		print("[RecipesData] ❌ You must create 6 unique 2-ingredient recipes first!")
		return null
	
	# Debug: Print all input ingredients
	for i in range(ingredients.size()):
		var ing = ingredients[i]
		print("[RecipesData]   Ingredient %d: %s (Water:%d, RST:%d, Vol:%d)" % [
			i, ing.name, ing.water_content, ing.heat_resistance, ing.volatility
		])
	
	var total_water = 0
	var total_heat_resistance = 0
	var total_volatility = 0
	
	for ingredient in ingredients:
		total_water += ingredient.water_content
		total_heat_resistance += ingredient.heat_resistance
		total_volatility += ingredient.volatility
	
	var count = ingredients.size()
	var avg_heat_resistance = int(round(float(total_heat_resistance) / count))
	var avg_volatility = int(round(float(total_volatility) / count))
	
	print("[RecipesData] Totals: Water=%d, RST total=%d, Vol total=%d" % [total_water, total_heat_resistance, total_volatility])
	print("[RecipesData] Averages: RST=%d, Vol=%d" % [avg_heat_resistance, avg_volatility])
	
	# Create combined name
	var ingredient_names: Array[String] = []
	for ingredient in ingredients:
		ingredient_names.append(ingredient.name)
	var combined_name = "+".join(ingredient_names)
	
	print("[RecipesData] Creating combined ingredient: '%s'" % combined_name)
	print("[RecipesData] Final stats: Water=%d, RST=%d, Vol=%d" % [total_water, avg_heat_resistance, avg_volatility])
	
	return IngredientModel.new(
		combined_name,
		total_water,
		avg_heat_resistance,
		avg_volatility
	)

## Get the current unlocked tier based on total recipes created
func get_unlocked_tier(total_recipes: int) -> int:
	if total_recipes >= TIER_4_UNLOCK_THRESHOLD:
		return 4
	elif total_recipes >= TIER_3_UNLOCK_THRESHOLD:
		return 3
	elif total_recipes >= TIER_2_UNLOCK_THRESHOLD:
		return 2
	elif total_recipes >= TIER_1_UNLOCK_THRESHOLD:
		return 1
	else:
		return 0
