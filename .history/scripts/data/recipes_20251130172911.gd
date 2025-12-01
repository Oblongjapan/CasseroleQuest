extends Node

## Singleton storing all recipe definitions and progression system

var recipes: Dictionary = {}

# RECIPE CLASSIFICATION: Recipes are classified by NUMBER OF INGREDIENTS
# - 2-ingredient recipes (28 base combinations)
# - 3-ingredient recipes (hundreds of combinations)
# - 4-ingredient recipes (thousands of combinations)
# - 5-ingredient recipes (even more combinations)
# - 6-ingredient recipes (massive combinations)
# - 7-ingredient recipes (near-ultimate recipes)
# - 8-ingredient recipes (ultimate recipes - ABSOLUTE MAX)

# PROGRESSION TIERS: Unlock access to higher ingredient counts
# Tiers gate which ingredient-count recipes can be created, NOT how recipes are named
const TIER_0_UNLOCK_THRESHOLD = 0   # Base ingredients - always available
const TIER_1_UNLOCK_THRESHOLD = 0   # 2-ingredient recipes - unlocked at game start
const TIER_2_UNLOCK_THRESHOLD = 6   # 3-4 ingredient recipes - REQUIRES 6 unique 2-ingredient recipes
const TIER_3_UNLOCK_THRESHOLD = 12  # 5-6 ingredient recipes - after 12 total recipes
const TIER_4_UNLOCK_THRESHOLD = 20  # 7-8 ingredient recipes - after 20 total recipes

# Maximum ingredients allowed per tier (progression gates)
const TIER_1_MAX_INGREDIENTS = 2    # Tier 1 limited to 2-ingredient recipes
const TIER_2_MAX_INGREDIENTS = 4    # Tier 2 allows up to 4 ingredients
const TIER_3_MAX_INGREDIENTS = 6    # Tier 3 allows up to 6 ingredients
const TIER_4_MAX_INGREDIENTS = 8    # Tier 4 allows up to 8 ingredients (ABSOLUTE MAX)
const ABSOLUTE_MAX_INGREDIENTS = 8  # No recipe can exceed 8 ingredients

# Base ingredients (available from start) - 8 ingredients
const BASE_INGREDIENTS = [
	"Chicken Breast", "Peas", "Rice", "Bread", "Broccoli", "Potato", "Lettuce", "Carrot"
]

# Premium ingredients (unlock at Tier 2 for 3+ ingredient recipes) - 5 ingredients
const PREMIUM_INGREDIENTS = [
	"Spinach", "Steak", "Salmon", "Tofu", "Asparagus"
]

# Tier 0: All ingredients available for selection (base for Tier 1, base+premium for Tier 2+)
const TIER_0_INGREDIENTS = BASE_INGREDIENTS + PREMIUM_INGREDIENTS

# Signal emitted when a new tier is unlocked
signal tier_unlocked(tier_number: int)

func _ready():
	_initialize_recipes()

func _initialize_recipes():
	# Phase 1 recipes (base ingredients)
	recipes["chicken_rice"] = RecipeModel.new(
		"chicken_rice",
		"Chicken Rice Bowl",
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
		"Steak & Potatoes",
		["Steak", "Potato"],
		115,  # water_content (55 + 60 = 115)
		60,  # heat_resistance
		15   # volatility
	)
	
	recipes["broccoli_chicken"] = RecipeModel.new(
		"broccoli_chicken",
		"Chicken & Broccoli",
		["Chicken Breast", "Broccoli"],
		110,  # water_content (50 + 60 = 110)
		48,  # heat_resistance
		17   # volatility
	)
	
	recipes["carrot_peas"] = RecipeModel.new(
		"carrot_peas",
		"Mixed Vegetables",
		["Carrot", "Peas"],
		135,  # water_content (65 + 70 = 135)
		45,  # heat_resistance
		10   # volatility
	)
	
	# Phase 2 recipes (with unlocked ingredients - Spinach, Salmon)
	recipes["salmon_spinach"] = RecipeModel.new(
		"salmon_spinach",
		"Salmon Florentine",
		["Salmon", "Spinach"],
		120,  # water_content (55 + 65 = 120)
		40,  # heat_resistance
		12   # volatility
	)
	
	recipes["chicken_rice_salmon"] = RecipeModel.new(
		"chicken_rice_salmon",
		"Surf & Turf Bowl",
		["Chicken Breast", "Rice", "Salmon"],
		135,  # water_content (50 + 30 + 55 = 135)
		58,  # heat_resistance
		11   # volatility
	)
	
	# More complex recipes can be added here
	recipes["mega_bowl"] = RecipeModel.new(
		"mega_bowl",
		"Chicken Broccoli Bowl",
		["Chicken Breast", "Rice", "Broccoli"],
		140,  # water_content (50 + 30 + 60 = 140)
		55,  # heat_resistance
		12   # volatility
	)

	recipes["chicken_sandwhich"] = RecipeModel.new(
		"chicken_sandwhich",
		"Chicken Sandwich",
		["Chicken Breast", "Bread"],
		83,  # water_content (50 + 33 = 83)
		50,  # heat_resistance
		11.5    # volatility
	)

	recipes["hot_chicken_sandwhich"] = RecipeModel.new(
		"hot_chicken_sandwhich",
		"Hot Chicken Sandwich",
		["Chicken Sandwich", "Peas"],
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

## Count the total number of base ingredients in a list of ingredient cards
## A combined card like "Chicken+Rice" counts as 2 base ingredients
func count_total_base_ingredients(ingredients: Array[IngredientModel]) -> int:
	var total = 0
	for ingredient in ingredients:
		# Count how many "+" symbols are in the name, then add 1
		# "Chicken" = 0 plus signs = 1 ingredient
		# "Chicken+Rice" = 1 plus sign = 2 ingredients
		# "Chicken+Rice+Steak" = 2 plus signs = 3 ingredients
		var plus_count = ingredient.name.count("+")
		total += (plus_count + 1)
	return total

## Generate a recipe name based on ingredient combination
## Returns a real dish name if found, otherwise a descriptive combination name
## Get base ingredient stats by name
func get_base_ingredient_by_name(ingredient_name: String) -> IngredientModel:
	var clean_name = ingredient_name.strip_edges().replace("Organic ", "")
	
	# Look through IngredientsData.INGREDIENTS dictionary
	for key in IngredientsData.INGREDIENTS.keys():
		var data = IngredientsData.INGREDIENTS[key]
		if data.name == clean_name:
			return IngredientModel.new(
				data.name,
				data.water_content,
				data.heat_resistance,
				data.volatility
			)
	
	print("[RecipesData] WARNING: Could not find base ingredient: %s" % clean_name)
	return null

func get_recipe_name_for_ingredients(ingredient_names: Array[String]) -> String:
	# Sort ingredients for consistent matching
	var sorted_ingredients = ingredient_names.duplicate()
	sorted_ingredients.sort()
	
	# Create a key for lookup (sorted, joined by |)
	var lookup_key = "|".join(sorted_ingredients)
	
	# Recipe name mappings - organized by INGREDIENT COUNT (not tier!)
	# Each combination has a unique, flavorful name
	var recipe_names = {
		# ===== 2 INGREDIENTS =====
		# 8 base ingredients = 8*7/2 = 28 unique combinations
		
		# Bread combinations (7)
		"Bread|Broccoli": "Broccoli Sandwich",
		"Bread|Carrot": "Carrot Sandwich",
		"Bread|Chicken Breast": "Chicken Sandwich",
		"Bread|Lettuce": "Lettuce Sandwich",
		"Bread|Peas": "Pea Sandwich",
		"Bread|Potato": "Potato Sandwich",
		"Bread|Rice": "Rice Sandwich",
		
		# Broccoli combinations (6 remaining)
		"Broccoli|Carrot": "Veggie Crunch",
		"Broccoli|Chicken Breast": "Chicken & Broccoli",
		"Broccoli|Lettuce": "Broccoli Salad",
		"Broccoli|Peas": "Green Vegetables",
		"Broccoli|Potato": "Broccoli Potato Bake",
		"Broccoli|Rice": "Broccoli Rice Bowl",
		
		# Carrot combinations (5 remaining)
		"Carrot|Chicken Breast": "Chicken with Carrots",
		"Carrot|Lettuce": "Garden Salad",
		"Carrot|Peas": "Mixed Vegetables",
		"Carrot|Potato": "Root Vegetables",
		"Carrot|Rice": "Carrot Rice",
		
		# Chicken Breast combinations (4 remaining)
		"Chicken Breast|Lettuce": "Chicken Salad",
		"Chicken Breast|Peas": "Chicken & Peas",
		"Chicken Breast|Potato": "Chicken & Potatoes",
		"Chicken Breast|Rice": "Chicken Rice Bowl",
		
		# Lettuce combinations (3 remaining)
		"Lettuce|Peas": "Pea Salad",
		"Lettuce|Potato": "Potato Salad",
		"Lettuce|Rice": "Rice Salad",
		
		# Peas combinations (2 remaining)
		"Peas|Potato": "Peas & Potatoes",
		"Peas|Rice": "Peas & Rice",
		
		# Potato combinations (1 remaining)
		"Potato|Rice": "Carb Combo",
		
		# ===== 3 INGREDIENTS =====
		# Hundreds of combinations with base ingredients
		# Plus combinations with 1 premium ingredient (Asparagus, Salmon, Spinach, Steak, Tofu)
		
		# 3 Ingredients - Base only (many combinations)
		"Bread|Broccoli|Carrot": "Veggie Sandwich Deluxe",
		"Bread|Broccoli|Chicken Breast": "Chicken Broccoli Sub",
		"Bread|Broccoli|Lettuce": "Green Sandwich",
		"Bread|Broccoli|Peas": "Green Veggie Sandwich",
		"Bread|Broccoli|Potato": "Broccoli Potato Sub",
		"Bread|Broccoli|Rice": "Broccoli Rice Wrap",
		"Bread|Carrot|Chicken Breast": "Chicken Carrot Sandwich",
		"Bread|Carrot|Lettuce": "Carrot Lettuce Wrap",
		"Bread|Carrot|Peas": "Veggie Medley Sandwich",
		"Bread|Carrot|Potato": "Root Veggie Sub",
		"Bread|Carrot|Rice": "Carrot Rice Wrap",
		"Bread|Chicken Breast|Lettuce": "Chicken Lettuce Sandwich",
		"Bread|Chicken Breast|Peas": "Hot Chicken Sandwich",
		"Bread|Chicken Breast|Potato": "Chicken Potato Sub",
		"Bread|Chicken Breast|Rice": "Chicken Rice Sandwich",
		"Bread|Lettuce|Peas": "Fresh Green Sandwich",
		"Bread|Lettuce|Potato": "Veggie Sub",
		"Bread|Lettuce|Rice": "Lettuce Rice Wrap",
		"Bread|Peas|Potato": "Pea Potato Sandwich",
		"Bread|Peas|Rice": "Pea Rice Sandwich",
		"Bread|Potato|Rice": "Carb Loader",
		"Broccoli|Carrot|Chicken Breast": "Chicken Veggie Mix",
		"Broccoli|Carrot|Lettuce": "Triple Green Salad",
		"Broccoli|Carrot|Peas": "Garden Vegetables",
		"Broccoli|Carrot|Potato": "Roasted Vegetable Mix",
		"Broccoli|Carrot|Rice": "Veggie Rice Bowl",
		"Broccoli|Chicken Breast|Lettuce": "Chicken Broccoli Salad",
		"Broccoli|Chicken Breast|Peas": "Chicken Green Mix",
		"Broccoli|Chicken Breast|Potato": "Chicken Harvest Plate",
		"Broccoli|Chicken Breast|Rice": "Chicken Broccoli Bowl",
		"Broccoli|Lettuce|Peas": "Green Salad Mix",
		"Broccoli|Lettuce|Potato": "Veggie Salad Bowl",
		"Broccoli|Lettuce|Rice": "Green Rice Salad",
		"Broccoli|Peas|Potato": "Green Veggie Medley",
		"Broccoli|Peas|Rice": "Green Rice Mix",
		"Broccoli|Potato|Rice": "Broccoli Carb Bowl",
		"Carrot|Chicken Breast|Lettuce": "Chicken Garden Salad",
		"Carrot|Chicken Breast|Peas": "Chicken à la King",
		"Carrot|Chicken Breast|Potato": "Chicken Root Veggie Plate",
		"Carrot|Chicken Breast|Rice": "Chicken Carrot Rice",
		"Carrot|Lettuce|Peas": "Spring Garden Salad",
		"Carrot|Lettuce|Potato": "Root & Leaf Salad",
		"Carrot|Lettuce|Rice": "Carrot Rice Salad",
		"Carrot|Peas|Potato": "Vegetable Medley",
		"Carrot|Peas|Rice": "Veggie Rice Mix",
		"Carrot|Potato|Rice": "Root Carb Bowl",
		"Chicken Breast|Lettuce|Peas": "Chicken Pea Salad",
		"Chicken Breast|Lettuce|Potato": "Chicken Potato Salad",
		"Chicken Breast|Lettuce|Rice": "Chicken Salad Bowl",
		"Chicken Breast|Peas|Potato": "Chicken Veggie Plate",
		"Chicken Breast|Peas|Rice": "Chicken Fried Rice",
		"Chicken Breast|Potato|Rice": "Chicken Carb Bowl",
		"Lettuce|Peas|Potato": "Light Veggie Salad",
		"Lettuce|Peas|Rice": "Pea Rice Salad",
		"Lettuce|Potato|Rice": "Simple Salad Bowl",
		"Peas|Potato|Rice": "Veggie Rice Combo",
		
		# 3 Ingredients - With 1 premium ingredient
		"Asparagus|Bread|Broccoli": "Asparagus Veggie Sandwich",
		"Asparagus|Bread|Carrot": "Asparagus Carrot Sub",
		"Asparagus|Bread|Chicken Breast": "Chicken Asparagus Sandwich",
		"Asparagus|Bread|Lettuce": "Asparagus Lettuce Wrap",
		"Asparagus|Bread|Peas": "Asparagus Pea Sandwich",
		"Asparagus|Bread|Potato": "Asparagus Potato Sub",
		"Asparagus|Bread|Rice": "Asparagus Rice Wrap",
		"Asparagus|Broccoli|Carrot": "Premium Veggie Trio",
		"Asparagus|Broccoli|Chicken Breast": "Chicken Garden Plate",
		"Asparagus|Broccoli|Lettuce": "Asparagus Greens",
		"Asparagus|Broccoli|Peas": "Green Veggie Delight",
		"Asparagus|Broccoli|Potato": "Roasted Garden Mix",
		"Asparagus|Broccoli|Rice": "Asparagus Rice Bowl",
		"Asparagus|Carrot|Chicken Breast": "Chicken Asparagus Plate",
		"Asparagus|Carrot|Lettuce": "Spring Garden Mix",
		"Asparagus|Carrot|Peas": "Spring Vegetable Trio",
		"Asparagus|Carrot|Potato": "Root Garden Plate",
		"Asparagus|Carrot|Rice": "Asparagus Carrot Rice",
		"Asparagus|Chicken Breast|Lettuce": "Chicken Asparagus Salad",
		"Asparagus|Chicken Breast|Peas": "Chicken Asparagus Mix",
		"Asparagus|Chicken Breast|Potato": "Chicken Harvest Combo",
		"Asparagus|Chicken Breast|Rice": "Chicken Asparagus Bowl",
		"Asparagus|Lettuce|Peas": "Light Spring Salad",
		"Asparagus|Lettuce|Potato": "Asparagus Salad Bowl",
		"Asparagus|Lettuce|Rice": "Asparagus Rice Salad",
		"Asparagus|Peas|Potato": "Asparagus Veggie Medley",
		"Asparagus|Peas|Rice": "Asparagus Pea Rice",
		"Asparagus|Potato|Rice": "Asparagus Carb Bowl",
		"Bread|Broccoli|Salmon": "Salmon Broccoli Sandwich",
		"Bread|Broccoli|Spinach": "Green Power Sandwich",
		"Bread|Broccoli|Steak": "Steak Broccoli Sub",
		"Bread|Broccoli|Tofu": "Tofu Broccoli Sandwich",
		"Bread|Carrot|Salmon": "Salmon Carrot Wrap",
		"Bread|Carrot|Spinach": "Spinach Carrot Sandwich",
		"Bread|Carrot|Steak": "Steak Carrot Sub",
		"Bread|Carrot|Tofu": "Tofu Carrot Sandwich",
		"Bread|Chicken Breast|Salmon": "Surf & Turf Sandwich",
		"Bread|Chicken Breast|Spinach": "Chicken Spinach Sub",
		"Bread|Chicken Breast|Steak": "Double Meat Sandwich",
		"Bread|Chicken Breast|Tofu": "Protein Power Sub",
		"Bread|Lettuce|Salmon": "Salmon Lettuce Wrap",
		"Bread|Lettuce|Spinach": "Green Leaf Sandwich",
		"Bread|Lettuce|Steak": "Steak Salad Sandwich",
		"Bread|Lettuce|Tofu": "Veggie Sandwich",
		"Bread|Peas|Salmon": "Salmon Pea Sandwich",
		"Bread|Peas|Spinach": "Spinach Pea Sub",
		"Bread|Peas|Steak": "Steak Pea Sandwich",
		"Bread|Peas|Tofu": "Tofu Pea Wrap",
		"Bread|Potato|Salmon": "Salmon Potato Sub",
		"Bread|Potato|Spinach": "Spinach Potato Sandwich",
		"Bread|Potato|Steak": "Steak Potato Sandwich",
		"Bread|Potato|Tofu": "Tofu Potato Sandwich",
		"Bread|Rice|Salmon": "Salmon Rice Wrap",
		"Bread|Rice|Spinach": "Spinach Rice Sandwich",
		"Bread|Rice|Steak": "Steak Rice Sub",
		"Bread|Rice|Tofu": "Tofu Rice Wrap",
		"Broccoli|Carrot|Salmon": "Salmon Veggie Plate",
		"Broccoli|Carrot|Spinach": "Green Garden Mix",
		"Broccoli|Carrot|Steak": "Steak Veggie Plate",
		"Broccoli|Carrot|Tofu": "Tofu Veggie Mix",
		"Broccoli|Chicken Breast|Salmon": "Surf & Turf Broccoli",
		"Broccoli|Chicken Breast|Spinach": "Chicken Power Greens",
		"Broccoli|Chicken Breast|Steak": "Double Meat Broccoli",
		"Broccoli|Chicken Breast|Tofu": "Protein Broccoli Bowl",
		"Broccoli|Lettuce|Salmon": "Salmon Green Salad",
		"Broccoli|Lettuce|Spinach": "Triple Greens Salad",
		"Broccoli|Lettuce|Steak": "Steak Green Salad",
		"Broccoli|Lettuce|Tofu": "Tofu Green Salad",
		"Broccoli|Peas|Salmon": "Salmon Green Plate",
		"Broccoli|Peas|Spinach": "Super Greens Bowl",
		"Broccoli|Peas|Steak": "Steak Green Mix",
		"Broccoli|Peas|Tofu": "Tofu Green Bowl",
		"Broccoli|Potato|Salmon": "Salmon Broccoli Bake",
		"Broccoli|Potato|Spinach": "Green Veggie Bake",
		"Broccoli|Potato|Steak": "Steak Broccoli Plate",
		"Broccoli|Potato|Tofu": "Tofu Broccoli Bake",
		"Broccoli|Rice|Salmon": "Salmon Broccoli Rice",
		"Broccoli|Rice|Spinach": "Green Rice Power Bowl",
		"Broccoli|Rice|Steak": "Steak Broccoli Rice",
		"Broccoli|Rice|Tofu": "Tofu Broccoli Rice",
		"Broccoli|Salmon|Spinach": "Salmon Power Greens",
		"Broccoli|Salmon|Steak": "Surf & Turf Broccoli Plate",
		"Broccoli|Salmon|Tofu": "Omega Protein Bowl",
		"Broccoli|Spinach|Steak": "Steak Power Greens",
		"Broccoli|Spinach|Tofu": "Vegan Power Bowl",
		"Broccoli|Steak|Tofu": "Protein Broccoli Mix",
		"Carrot|Chicken Breast|Salmon": "Surf & Turf Carrot Bowl",
		"Carrot|Chicken Breast|Spinach": "Chicken Spinach Carrot",
		"Carrot|Chicken Breast|Steak": "Double Meat Carrot Plate",
		"Carrot|Chicken Breast|Tofu": "Protein Carrot Bowl",
		"Carrot|Lettuce|Salmon": "Salmon Garden Salad",
		"Carrot|Lettuce|Spinach": "Super Garden Salad",
		"Carrot|Lettuce|Steak": "Steak Garden Salad",
		"Carrot|Lettuce|Tofu": "Tofu Garden Salad",
		"Carrot|Peas|Salmon": "Salmon Veggie Bowl",
		"Carrot|Peas|Spinach": "Green Veggie Bowl",
		"Carrot|Peas|Steak": "Steak Veggie Bowl",
		"Carrot|Peas|Tofu": "Tofu Veggie Bowl",
		"Carrot|Potato|Salmon": "Salmon Root Bowl",
		"Carrot|Potato|Spinach": "Green Root Veggie",
		"Carrot|Potato|Steak": "Hearty Stew Base",
		"Carrot|Potato|Tofu": "Tofu Root Bowl",
		"Carrot|Rice|Salmon": "Salmon Veggie Bowl",
		"Carrot|Rice|Spinach": "Spinach Carrot Rice",
		"Carrot|Rice|Steak": "Steak Carrot Rice",
		"Carrot|Rice|Tofu": "Tofu Carrot Rice",
		"Carrot|Salmon|Spinach": "Salmon Spinach Plate",
		"Carrot|Salmon|Steak": "Surf & Turf Carrot",
		"Carrot|Salmon|Tofu": "Omega Carrot Bowl",
		"Carrot|Spinach|Steak": "Steak Spinach Carrot",
		"Carrot|Spinach|Tofu": "Vegan Carrot Bowl",
		"Carrot|Steak|Tofu": "Protein Carrot Plate",
		"Chicken Breast|Lettuce|Salmon": "Surf & Turf Salad",
		"Chicken Breast|Lettuce|Spinach": "Chicken Power Salad",
		"Chicken Breast|Lettuce|Steak": "Double Meat Salad",
		"Chicken Breast|Lettuce|Tofu": "Protein Salad Bowl",
		"Chicken Breast|Peas|Salmon": "Surf & Turf Pea Bowl",
		"Chicken Breast|Peas|Spinach": "Chicken Pea Power Bowl",
		"Chicken Breast|Peas|Steak": "Double Meat Pea Plate",
		"Chicken Breast|Peas|Tofu": "Protein Pea Bowl",
		"Chicken Breast|Potato|Salmon": "Surf & Turf Potato Plate",
		"Chicken Breast|Potato|Spinach": "Chicken Spinach Potato",
		"Chicken Breast|Potato|Steak": "Double Meat Potato",
		"Chicken Breast|Potato|Tofu": "Protein Potato Plate",
		"Chicken Breast|Rice|Salmon": "Surf & Turf Bowl",
		"Chicken Breast|Rice|Spinach": "Healthy Chicken Bowl",
		"Chicken Breast|Rice|Steak": "Double Meat Rice Bowl",
		"Chicken Breast|Rice|Tofu": "Protein Rice Bowl",
		"Chicken Breast|Salmon|Spinach": "Omega Protein Plate",
		"Chicken Breast|Salmon|Steak": "Triple Meat Plate",
		"Chicken Breast|Salmon|Tofu": "Ultra Protein Bowl",
		"Chicken Breast|Spinach|Steak": "Power Meat Plate",
		"Chicken Breast|Spinach|Tofu": "Lean Protein Bowl",
		"Chicken Breast|Steak|Tofu": "Triple Protein Plate",
		"Lettuce|Peas|Salmon": "Salmon Pea Salad",
		"Lettuce|Peas|Spinach": "Triple Green Salad",
		"Lettuce|Peas|Steak": "Steak Pea Salad",
		"Lettuce|Peas|Tofu": "Tofu Pea Salad",
		"Lettuce|Potato|Salmon": "Salmon Potato Salad",
		"Lettuce|Potato|Spinach": "Green Potato Salad",
		"Lettuce|Potato|Steak": "Steak Potato Salad",
		"Lettuce|Potato|Tofu": "Tofu Potato Salad",
		"Lettuce|Rice|Salmon": "Salmon Rice Salad",
		"Lettuce|Rice|Spinach": "Green Rice Salad",
		"Lettuce|Rice|Steak": "Steak Rice Salad",
		"Lettuce|Rice|Tofu": "Tofu Rice Salad",
		"Lettuce|Salmon|Spinach": "Ocean Greens Salad",
		"Lettuce|Salmon|Steak": "Surf & Turf Salad Bowl",
		"Lettuce|Salmon|Tofu": "Omega Salad Bowl",
		"Lettuce|Spinach|Steak": "Steak Power Salad",
		"Lettuce|Spinach|Tofu": "Vegan Power Salad",
		"Lettuce|Steak|Tofu": "Protein Salad",
		"Peas|Potato|Salmon": "Salmon Pea Potato",
		"Peas|Potato|Spinach": "Green Veggie Mix",
		"Peas|Potato|Steak": "Steak Pea Potato",
		"Peas|Potato|Tofu": "Tofu Pea Potato",
		"Peas|Rice|Salmon": "Salmon Pea Rice",
		"Peas|Rice|Spinach": "Green Rice Mix",
		"Peas|Rice|Steak": "Steak Pea Rice",
		"Peas|Rice|Tofu": "Tofu Rice Mix",
		"Peas|Salmon|Spinach": "Omega Green Bowl",
		"Peas|Salmon|Steak": "Surf & Turf Peas",
		"Peas|Salmon|Tofu": "Omega Pea Bowl",
		"Peas|Spinach|Steak": "Steak Green Mix",
		"Peas|Spinach|Tofu": "Vegan Green Bowl",
		"Peas|Steak|Tofu": "Protein Pea Plate",
		"Potato|Rice|Salmon": "Salmon Carb Bowl",
		"Potato|Rice|Spinach": "Green Carb Bowl",
		"Potato|Rice|Steak": "Steak Carb Bowl",
		"Potato|Rice|Tofu": "Tofu Carb Bowl",
		"Potato|Salmon|Spinach": "Salmon Spinach Potato",
		"Potato|Salmon|Steak": "Surf & Turf Potato Bowl",
		"Potato|Salmon|Tofu": "Omega Potato Bowl",
		"Potato|Spinach|Steak": "Steak Spinach Potato",
		"Potato|Spinach|Tofu": "Vegan Potato Bowl",
		"Potato|Steak|Tofu": "Protein Potato Bowl",
		"Rice|Salmon|Spinach": "Salmon Spinach Rice",
		"Rice|Salmon|Steak": "Surf & Turf Rice",
		"Rice|Salmon|Tofu": "Omega Rice Bowl",
		"Rice|Spinach|Steak": "Steak Spinach Rice",
		"Rice|Spinach|Tofu": "Vegan Rice Bowl",
		"Rice|Steak|Tofu": "Protein Rice Bowl",
		"Salmon|Spinach|Steak": "Surf & Turf Greens",
		"Salmon|Spinach|Tofu": "Omega Vegan Plate",
		"Salmon|Steak|Tofu": "Ultimate Protein Trio",
		"Spinach|Steak|Tofu": "Power Protein Greens",
		
		# ===== 4 INGREDIENTS =====
		# (Thousands of combinations - can be added as needed)
		# Examples can be added here for common 4-ingredient combos
		
		# ===== 5 INGREDIENTS =====
		# (Even more combinations - providing key examples)
		
		# 5 Ingredients - Key examples
		"Broccoli|Carrot|Chicken Breast|Peas|Rice": "Grand Chicken Bowl",
		"Bread|Chicken Breast|Lettuce|Peas|Spinach": "Supreme Sandwich",
		"Carrot|Chicken Breast|Peas|Potato|Salmon": "Surf & Garden Bowl",
		"Broccoli|Carrot|Peas|Potato|Spinach": "Garden Harvest",
		"Asparagus|Broccoli|Carrot|Chicken Breast|Rice": "Gourmet Chicken Plate",
		"Chicken Breast|Potato|Rice|Salmon|Spinach": "Fisherman's Bounty",
		"Bread|Lettuce|Potato|Steak|Tofu": "Ultimate Protein Sandwich",
		"Broccoli|Chicken Breast|Rice|Salmon|Tofu": "Omega Fusion Bowl",
		
		# 6 Ingredients - Key examples  
		"Broccoli|Carrot|Chicken Breast|Peas|Potato|Rice": "Chef's Special Bowl",
		"Asparagus|Broccoli|Carrot|Chicken Breast|Peas|Rice": "Premium Chicken Feast",
		"Broccoli|Carrot|Peas|Potato|Spinach|Tofu": "Vegan Delight",
		"Chicken Breast|Lettuce|Peas|Rice|Salmon|Spinach": "Ocean Garden Bowl",
		"Bread|Broccoli|Chicken Breast|Salmon|Steak|Tofu": "Protein Paradise Sandwich",
		"Carrot|Lettuce|Potato|Rice|Salmon|Steak": "Deluxe Meat & Veggie Bowl",
		
		# ===== TIER 4: 7-8 Ingredients =====
		
		# 7 Ingredients
		"Asparagus|Broccoli|Carrot|Chicken Breast|Peas|Potato|Rice": "Kitchen Sink Bowl",
		"Broccoli|Carrot|Chicken Breast|Lettuce|Peas|Spinach|Tofu": "Everything Protein Bowl",
		"Bread|Carrot|Chicken Breast|Potato|Salmon|Spinach|Steak": "Grand Feast Sandwich",
		"Broccoli|Lettuce|Peas|Rice|Salmon|Steak|Tofu": "Ultimate Power Bowl",
		
		# 8 Ingredients - The ultimate recipes
		"Asparagus|Bread|Broccoli|Chicken Breast|Lettuce|Salmon|Steak|Tofu": "Supreme Protein Sandwich",
		"Broccoli|Carrot|Chicken Breast|Peas|Potato|Rice|Salmon|Spinach": "Master Chef's Creation",
		"Asparagus|Broccoli|Carrot|Lettuce|Potato|Salmon|Steak|Tofu": "Legendary Feast Bowl",
		"Asparagus|Broccoli|Carrot|Chicken Breast|Lettuce|Peas|Potato|Rice": "Ultimate Feast",
		"Asparagus|Broccoli|Carrot|Lettuce|Peas|Potato|Spinach|Tofu": "Mega Veggie Bowl",
	}
	
	# Check if we have a predefined name
	if recipe_names.has(lookup_key):
		return recipe_names[lookup_key]
	
	# Fallback: Create a descriptive name
	var ingredient_count = sorted_ingredients.size()
	if ingredient_count <= 2:
		return " & ".join(sorted_ingredients)
	elif ingredient_count <= 4:
		return sorted_ingredients[0] + " Mix Bowl"
	else:
		return "Custom " + str(ingredient_count) + "-Ingredient Bowl"

## Combine multiple ingredients into a new recipe card
## Water = sum, Heat Resistance = average
## Volatility = average for 2 ingredients, SUM for 3+ (more ingredients = more chaos!)
## Returns null if the combination is not allowed based on current tier
func combine_ingredients(ingredients: Array[IngredientModel], current_tier: int = 1) -> IngredientModel:
	print("[RecipesData] === combine_ingredients called ===")
	print("[RecipesData] Input ingredients count (cards): %d" % ingredients.size())
	print("[RecipesData] Current tier: %d" % current_tier)
	
	if ingredients.size() == 0:
		print("[RecipesData] ERROR: No ingredients provided!")
		return null
	
	# Count the ACTUAL number of base ingredients (accounting for combined cards)
	var total_base_ingredients = count_total_base_ingredients(ingredients)
	print("[RecipesData] Total BASE ingredients (counting combined cards): %d" % total_base_ingredients)
	
	# MAXIMUM INGREDIENT LIMIT: No recipe can have more than 8 ingredients
	if total_base_ingredients > ABSOLUTE_MAX_INGREDIENTS:
		print("[RecipesData] ❌ BLOCKED: Recipe has %d ingredients! Maximum is %d." % [total_base_ingredients, ABSOLUTE_MAX_INGREDIENTS])
		print("[RecipesData] ❌ Maximum 8 ingredients per recipe!")
		return null
	
	# TIER RESTRICTIONS: Check if this combination is allowed based on current tier
	if current_tier < 2 and total_base_ingredients > TIER_1_MAX_INGREDIENTS:
		print("[RecipesData] ❌ BLOCKED: %d-ingredient recipe requires Tier 2! (Current: Tier %d)" % [total_base_ingredients, current_tier])
		print("[RecipesData] ❌ Need Tier 2 for 3+ ingredient recipes!")
		return null
	
	if current_tier < 3 and total_base_ingredients > TIER_2_MAX_INGREDIENTS:
		print("[RecipesData] ❌ BLOCKED: %d-ingredient recipe requires Tier 3! (Current: Tier %d)" % [total_base_ingredients, current_tier])
		print("[RecipesData] ❌ Need Tier 3 for 5+ ingredient recipes!")
		return null
	
	if current_tier < 4 and total_base_ingredients > TIER_3_MAX_INGREDIENTS:
		print("[RecipesData] ❌ BLOCKED: %d-ingredient recipe requires Tier 4! (Current: Tier %d)" % [total_base_ingredients, current_tier])
		print("[RecipesData] ❌ Need Tier 4 for 7+ ingredient recipes!")
		return null
	
	# Debug: Print all input ingredients
	for i in range(ingredients.size()):
		var ing = ingredients[i]
		print("[RecipesData]   Ingredient %d: %s (Water:%d, RST:%d, Vol:%d)" % [
			i, ing.name, ing.water_content, ing.heat_resistance, ing.volatility
		])
	
	# Extract unique base ingredients from all input cards
	# This handles combined ingredients and removes duplicates
	var unique_base_ingredients: Dictionary = {}  # name -> IngredientModel
	
	for ingredient in ingredients:
		# Split by "+" to handle combined ingredients
		var parts = ingredient.name.split("+")
		for part in parts:
			var clean_name = part.strip_edges()
			# If this base ingredient isn't in our dict yet, get its base stats
			if not unique_base_ingredients.has(clean_name):
				# Try to find the base ingredient stats from BASE_INGREDIENTS
				var base_ing = get_base_ingredient_by_name(clean_name)
				if base_ing:
					unique_base_ingredients[clean_name] = base_ing
					print("[RecipesData]   Found unique base: %s (Water:%d, RST:%d, Vol:%d)" % [
						clean_name, base_ing.water_content, base_ing.heat_resistance, base_ing.volatility
					])
	
	# Calculate stats based on unique base ingredients only
	var total_water = 0
	var total_heat_resistance = 0
	var total_volatility = 0
	var unique_count = unique_base_ingredients.size()
	
	for base_name in unique_base_ingredients.keys():
		var base_ing = unique_base_ingredients[base_name]
		total_water += base_ing.water_content
		total_heat_resistance += base_ing.heat_resistance
		total_volatility += base_ing.volatility
	
	print("[RecipesData] Using %d unique base ingredients for stats calculation" % unique_count)
	var avg_heat_resistance = int(round(float(total_heat_resistance) / unique_count))
	
	# Volatility calculation:
	# - 2 ingredients: Use AVERAGE (keeps early game balanced)
	# - 3+ ingredients: Use SUM (more stuff = more chaos!)
	var final_volatility: int
	if unique_count <= 2:
		final_volatility = int(round(float(total_volatility) / unique_count))
		print("[RecipesData] 2-ingredient recipe: Using AVERAGED volatility")
	else:
		final_volatility = total_volatility
		print("[RecipesData] 3+ ingredient recipe: Using SUMMED volatility (more chaos!)")
	
	print("[RecipesData] Totals: Water=%d, RST total=%d, Vol total=%d" % [total_water, total_heat_resistance, total_volatility])
	print("[RecipesData] Final stats: RST (avg)=%d, Vol=%d" % [avg_heat_resistance, final_volatility])
	
	# Create combined identity using UNIQUE base ingredient names only
	# Sort alphabetically for consistent identity
	var unique_names: Array[String] = []
	for base_name in unique_base_ingredients.keys():
		unique_names.append(base_name)
	unique_names.sort()
	var combined_identity = "+".join(unique_names)
	
	# Generate the friendly display name based on unique ingredients
	var display_name = get_recipe_name_for_ingredients(unique_names)
	
	print("[RecipesData] Creating recipe:")
	print("[RecipesData]   Identity (internal): '%s'" % combined_identity)
	print("[RecipesData]   Display Name: '%s'" % display_name)
	print("[RecipesData] Final stats: Water=%d, RST=%d, Vol=%d" % [total_water, avg_heat_resistance, final_volatility])
	
	# Create the ingredient with identity as name, but store display name as metadata
	var new_ingredient = IngredientModel.new(
		combined_identity,
		total_water,
		avg_heat_resistance,
		final_volatility
	)
	
	# Store the display name as metadata
	new_ingredient.set_meta("display_name", display_name)
	
	return new_ingredient

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
