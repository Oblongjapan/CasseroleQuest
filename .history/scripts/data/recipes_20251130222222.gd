extends Node

## Singleton storing all recipe definitions and progression system
## 
## DESIGN PHILOSOPHY:
## - Recipes are CLASSIFIED by INGREDIENT COUNT (2, 3, 4, 5, 6, 7, 8)
## - Each unique combination has its own creative name
## - Tiers control PROGRESSION (when you unlock access to create higher ingredient counts)
## 
## EXAMPLE:
## - "Chicken Sandwich" = 2-ingredient recipe (Chicken + Bread)
## - "Hot Chicken Sandwich" = 3-ingredient recipe (Chicken + Bread + Peas)
## - "Kitchen Sink Bowl" = 7-ingredient recipe (all the things!)
## 
## Player starts at Tier 1 → can only make 2-ingredient recipes
## Unlock Tier 2 → can now make 3-4 ingredient recipes
## Unlock Tier 3 → can now make 5-6 ingredient recipes
## Unlock Tier 4 → can now make 7-8 ingredient recipes (ultimate!)

var recipes: Dictionary = {}

# RECIPE CLASSIFICATION: Recipes are classified by NUMBER OF INGREDIENTS
# This determines their NAME and identity, not when they're unlocked
# 
# INGREDIENT COUNT TOTALS:
# - 2 ingredients: 28 base combinations (from 8 base ingredients)
# - 3 ingredients: ~200+ combinations (base + 1 premium)
# - 4 ingredients: 1000+ combinations (exponential growth)
# - 5 ingredients: Many thousands of combinations
# - 6 ingredients: Tens of thousands of combinations
# - 7 ingredients: Hundreds of thousands of combinations
# - 8 ingredients: Millions of combinations (ultimate recipes!)
#
# Each combination gets a unique, flavorful name based on its ingredients

# PROGRESSION TIERS: Unlock access to higher ingredient counts
# Tiers gate which ingredient-count recipes can be created, NOT how recipes are named
const TIER_0_UNLOCK_THRESHOLD = 0   # Base ingredients - always available
const TIER_1_UNLOCK_THRESHOLD = 0   # 2-ingredient recipes - unlocked at game start
const TIER_2_UNLOCK_THRESHOLD = 6   # 3-4 ingredient recipes - REQUIRES 6 unique 2-ingredient recipes
const TIER_3_UNLOCK_THRESHOLD = 12  # 5-6 ingredient recipes - after 12 total recipes
const TIER_4_UNLOCK_THRESHOLD = 20  # 7-8 ingredient recipes - after 20 total recipes
const TIER_5_UNLOCK_THRESHOLD = 30  # 9-ingredient recipes - after 30 total recipes
const TIER_6_UNLOCK_THRESHOLD = 42  # 10-ingredient recipes - after 42 total recipes
const TIER_7_UNLOCK_THRESHOLD = 56  # 11-ingredient recipes - after 56 total recipes
const TIER_8_UNLOCK_THRESHOLD = 72  # 12-13 ingredient recipes - after 72 total recipes

# Maximum ingredients allowed per tier (progression gates)
const TIER_1_MAX_INGREDIENTS = 2    # Tier 1 limited to 2-ingredient recipes
const TIER_2_MAX_INGREDIENTS = 4    # Tier 2 allows up to 4 ingredients
const TIER_3_MAX_INGREDIENTS = 6    # Tier 3 allows up to 6 ingredients
const TIER_4_MAX_INGREDIENTS = 8    # Tier 4 allows up to 8 ingredients
const TIER_5_MAX_INGREDIENTS = 9    # Tier 5 allows up to 9 ingredients
const TIER_6_MAX_INGREDIENTS = 10   # Tier 6 allows up to 10 ingredients
const TIER_7_MAX_INGREDIENTS = 11   # Tier 7 allows up to 11 ingredients
const TIER_8_MAX_INGREDIENTS = 13   # Tier 8 allows up to 13 ingredients (ULTIMATE)
const ABSOLUTE_MAX_INGREDIENTS = 13 # No recipe can exceed 13 ingredients

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
		# Mix of realistic and creative names for mid-game recipes
		# Total possible: 715 combinations (Batch 1 of 8: 100 recipes)
		
		# Bread-based 4-ingredient combos (sandwiches and wraps)
		"Asparagus|Bread|Broccoli|Carrot": "Garden Fresh Sandwich",
		"Asparagus|Bread|Broccoli|Chicken Breast": "Healthy Chicken Wrap",
		"Asparagus|Bread|Broccoli|Lettuce": "Springtime Veggie Sub",
		"Asparagus|Bread|Broccoli|Peas": "Green Garden Sandwich",
		"Asparagus|Bread|Broccoli|Potato": "Roasted Veggie Sub",
		"Asparagus|Bread|Broccoli|Rice": "Veggie Rice Wrap",
		"Asparagus|Bread|Carrot|Chicken Breast": "Harvest Chicken Sandwich",
		"Asparagus|Bread|Carrot|Lettuce": "Fresh Garden Wrap",
		"Asparagus|Bread|Carrot|Peas": "Spring Veggie Delight",
		"Asparagus|Bread|Carrot|Potato": "Root Veggie Special",
		"Asparagus|Bread|Carrot|Rice": "Garden Grain Wrap",
		"Asparagus|Bread|Chicken Breast|Lettuce": "Asparagus Chicken Club",
		"Asparagus|Bread|Chicken Breast|Peas": "Chicken Garden Sandwich",
		"Asparagus|Bread|Chicken Breast|Potato": "Hearty Chicken Sub",
		"Asparagus|Bread|Chicken Breast|Rice": "Chicken Asparagus Wrap",
		"Asparagus|Bread|Lettuce|Peas": "Light Spring Sandwich",
		"Asparagus|Bread|Lettuce|Potato": "Fresh Garden Sub",
		"Asparagus|Bread|Lettuce|Rice": "Crisp Veggie Wrap",
		"Asparagus|Bread|Peas|Potato": "Green Potato Sub",
		"Asparagus|Bread|Peas|Rice": "Spring Rice Sandwich",
		"Asparagus|Bread|Potato|Rice": "Carb Garden Wrap",
		"Bread|Broccoli|Carrot|Chicken Breast": "Classic Chicken Veggie Sub",
		"Bread|Broccoli|Carrot|Lettuce": "Triple Veggie Sandwich",
		"Bread|Broccoli|Carrot|Peas": "Garden Crunch Wrap",
		"Bread|Broccoli|Carrot|Potato": "Roasted Veggie Medley Sub",
		"Bread|Broccoli|Carrot|Rice": "Veggie Grain Sandwich",
		"Bread|Broccoli|Chicken Breast|Lettuce": "Healthy Chicken Club",
		"Bread|Broccoli|Chicken Breast|Peas": "Green Chicken Sandwich",
		"Bread|Broccoli|Chicken Breast|Potato": "Hearty Broccoli Chicken Sub",
		"Bread|Broccoli|Chicken Breast|Rice": "Chicken Veggie Rice Wrap",
		"Bread|Broccoli|Lettuce|Peas": "Fresh Greens Sandwich",
		"Bread|Broccoli|Lettuce|Potato": "Garden Salad Sub",
		"Bread|Broccoli|Lettuce|Rice": "Green Grain Wrap",
		"Bread|Broccoli|Peas|Potato": "Double Green Sub",
		"Bread|Broccoli|Peas|Rice": "Green Rice Sandwich",
		"Bread|Broccoli|Potato|Rice": "Veggie Carb Loader",
		"Bread|Carrot|Chicken Breast|Lettuce": "Garden Chicken Club",
		"Bread|Carrot|Chicken Breast|Peas": "Chicken Harvest Sandwich",
		"Bread|Carrot|Chicken Breast|Potato": "Farmhouse Chicken Sub",
		"Bread|Carrot|Chicken Breast|Rice": "Chicken Carrot Rice Wrap",
		
		# Bread + Premium proteins (Salmon, Steak, Tofu)
		"Asparagus|Bread|Salmon|Spinach": "Gourmet Salmon Sandwich",
		"Asparagus|Bread|Steak|Spinach": "Premium Steak Sub",
		"Asparagus|Bread|Tofu|Spinach": "Vegan Garden Wrap",
		"Bread|Broccoli|Salmon|Spinach": "Omega Green Sandwich",
		"Bread|Broccoli|Steak|Spinach": "Power Steak Sub",
		"Bread|Broccoli|Tofu|Spinach": "Super Vegan Sandwich",
		"Bread|Carrot|Salmon|Spinach": "Salmon Garden Wrap",
		"Bread|Carrot|Steak|Spinach": "Steak Root Veggie Sub",
		"Bread|Carrot|Tofu|Spinach": "Tofu Garden Sandwich",
		"Bread|Chicken Breast|Salmon|Spinach": "Surf & Turf Club",
		"Bread|Chicken Breast|Steak|Spinach": "Double Protein Sandwich",
		"Bread|Chicken Breast|Tofu|Spinach": "Protein Power Wrap",
		"Bread|Lettuce|Salmon|Spinach": "Light Ocean Sandwich",
		"Bread|Lettuce|Steak|Spinach": "Greens & Meat Sub",
		"Bread|Lettuce|Tofu|Spinach": "Fresh Vegan Wrap",
		"Bread|Peas|Salmon|Spinach": "Ocean Garden Sandwich",
		"Bread|Peas|Steak|Spinach": "Protein Green Sub",
		"Bread|Peas|Tofu|Spinach": "Green Vegan Delight",
		"Bread|Potato|Salmon|Spinach": "Hearty Salmon Sub",
		"Bread|Potato|Steak|Spinach": "Power Steak Sandwich",
		"Bread|Potato|Tofu|Spinach": "Loaded Vegan Wrap",
		"Bread|Rice|Salmon|Spinach": "Salmon Grain Sandwich",
		"Bread|Rice|Steak|Spinach": "Steak Rice Wrap",
		"Bread|Rice|Tofu|Spinach": "Tofu Rice Sub",
		
		# Bowl combinations (no bread, 4 ingredients)
		"Asparagus|Broccoli|Carrot|Chicken Breast": "Garden Harvest Bowl",
		"Asparagus|Broccoli|Carrot|Lettuce": "Premium Spring Mix",
		"Asparagus|Broccoli|Carrot|Peas": "Green Garden Medley",
		"Asparagus|Broccoli|Carrot|Potato": "Roasted Root Bowl",
		"Asparagus|Broccoli|Carrot|Rice": "Veggie Grain Bowl",
		"Asparagus|Broccoli|Chicken Breast|Lettuce": "Spring Chicken Salad",
		"Asparagus|Broccoli|Chicken Breast|Peas": "Garden Protein Bowl",
		"Asparagus|Broccoli|Chicken Breast|Potato": "Hearty Chicken Mix",
		"Asparagus|Broccoli|Chicken Breast|Rice": "Asparagus Chicken Bowl",
		"Asparagus|Broccoli|Lettuce|Peas": "Super Greens Salad",
		"Asparagus|Broccoli|Lettuce|Potato": "Garden Fresh Bowl",
		"Asparagus|Broccoli|Lettuce|Rice": "Spring Rice Salad",
		"Asparagus|Broccoli|Peas|Potato": "Green Veggie Harmony",
		"Asparagus|Broccoli|Peas|Rice": "Springtime Rice Bowl",
		"Asparagus|Broccoli|Potato|Rice": "Garden Carb Bowl",
		"Asparagus|Carrot|Chicken Breast|Lettuce": "Fresh Harvest Salad",
		"Asparagus|Carrot|Chicken Breast|Peas": "Chicken Spring Mix",
		"Asparagus|Carrot|Chicken Breast|Potato": "Rustic Chicken Bowl",
		"Asparagus|Carrot|Chicken Breast|Rice": "Garden Chicken Rice",
		"Asparagus|Carrot|Lettuce|Peas": "Spring Garden Bowl",
		"Asparagus|Carrot|Lettuce|Potato": "Root & Leaf Medley",
		"Asparagus|Carrot|Lettuce|Rice": "Fresh Spring Rice",
		"Asparagus|Carrot|Peas|Potato": "Spring Root Mix",
		"Asparagus|Carrot|Peas|Rice": "Garden Pea Rice",
		"Asparagus|Carrot|Potato|Rice": "Harvest Grain Bowl",
		"Asparagus|Chicken Breast|Lettuce|Peas": "Light Protein Salad",
		"Asparagus|Chicken Breast|Lettuce|Potato": "Chicken Garden Mix",
		"Asparagus|Chicken Breast|Lettuce|Rice": "Fresh Chicken Rice Bowl",
		"Asparagus|Chicken Breast|Peas|Potato": "Protein Veggie Medley",
		"Asparagus|Chicken Breast|Peas|Rice": "Spring Chicken Fried Rice",
		"Asparagus|Chicken Breast|Potato|Rice": "Hearty Chicken Grain Bowl",
		"Asparagus|Lettuce|Peas|Potato": "Light Garden Mix",
		"Asparagus|Lettuce|Peas|Rice": "Spring Pea Salad",
		"Asparagus|Lettuce|Potato|Rice": "Fresh Grain Salad",
		
		# 4-ingredient with premium proteins (Batch 2: +100 recipes)
		"Asparagus|Broccoli|Salmon|Spinach": "Omega Garden Bowl",
		"Asparagus|Broccoli|Steak|Spinach": "Power Green Steak",
		"Asparagus|Broccoli|Tofu|Spinach": "Vegan Green Power",
		"Asparagus|Carrot|Salmon|Spinach": "Spring Salmon Bowl",
		"Asparagus|Carrot|Steak|Spinach": "Garden Steak Medley",
		"Asparagus|Carrot|Tofu|Spinach": "Vegan Spring Mix",
		"Asparagus|Chicken Breast|Salmon|Spinach": "Protein Fusion Bowl",
		"Asparagus|Chicken Breast|Steak|Spinach": "Triple Protein Mix",
		"Asparagus|Chicken Breast|Tofu|Spinach": "Lean Protein Medley",
		"Asparagus|Lettuce|Salmon|Spinach": "Ocean Spring Salad",
		"Asparagus|Lettuce|Steak|Spinach": "Power Greens & Steak",
		"Asparagus|Lettuce|Tofu|Spinach": "Light Vegan Bowl",
		"Asparagus|Peas|Salmon|Spinach": "Green Omega Bowl",
		"Asparagus|Peas|Steak|Spinach": "Protein Garden Mix",
		"Asparagus|Peas|Tofu|Spinach": "Vegan Greens Bowl",
		"Asparagus|Potato|Salmon|Spinach": "Hearty Salmon Mix",
		"Asparagus|Potato|Steak|Spinach": "Power Steak Bowl",
		"Asparagus|Potato|Tofu|Spinach": "Loaded Vegan Bowl",
		"Asparagus|Rice|Salmon|Spinach": "Omega Grain Bowl",
		"Asparagus|Rice|Steak|Spinach": "Steak Grain Mix",
		"Asparagus|Rice|Tofu|Spinach": "Vegan Grain Harmony",
		"Broccoli|Carrot|Chicken Breast|Lettuce": "Classic Garden Chicken",
		"Broccoli|Carrot|Chicken Breast|Peas": "Chicken Veggie Delight",
		"Broccoli|Carrot|Chicken Breast|Potato": "Roasted Chicken Bowl",
		"Broccoli|Carrot|Chicken Breast|Rice": "Chicken Stir Fry",
		"Broccoli|Carrot|Lettuce|Peas": "Rainbow Veggie Salad",
		"Broccoli|Carrot|Lettuce|Potato": "Garden Harvest Salad",
		"Broccoli|Carrot|Lettuce|Rice": "Veggie Rice Salad",
		"Broccoli|Carrot|Peas|Potato": "Root & Green Medley",
		"Broccoli|Carrot|Peas|Rice": "Garden Rice Bowl",
		"Broccoli|Carrot|Potato|Rice": "Veggie Comfort Bowl",
		"Broccoli|Carrot|Salmon|Spinach": "Omega Veggie Bowl",
		"Broccoli|Carrot|Steak|Spinach": "Steak Garden Mix",
		"Broccoli|Carrot|Tofu|Spinach": "Vegan Garden Bowl",
		"Broccoli|Chicken Breast|Lettuce|Peas": "Fresh Chicken Greens",
		"Broccoli|Chicken Breast|Lettuce|Potato": "Chicken Garden Plate",
		"Broccoli|Chicken Breast|Lettuce|Rice": "Healthy Chicken Salad Bowl",
		"Broccoli|Chicken Breast|Peas|Potato": "Hearty Chicken Veggie",
		"Broccoli|Chicken Breast|Peas|Rice": "Chicken Green Rice",
		"Broccoli|Chicken Breast|Potato|Rice": "Classic Chicken Combo",
		"Broccoli|Chicken Breast|Salmon|Spinach": "Surf & Turf Greens",
		"Broccoli|Chicken Breast|Steak|Spinach": "Double Meat Power Bowl",
		"Broccoli|Chicken Breast|Tofu|Spinach": "Protein Greens Mix",
		"Broccoli|Lettuce|Peas|Potato": "Fresh Green Medley",
		"Broccoli|Lettuce|Peas|Rice": "Light Green Rice Bowl",
		"Broccoli|Lettuce|Potato|Rice": "Garden Grain Salad",
		"Broccoli|Lettuce|Salmon|Spinach": "Ocean Greens Bowl",
		"Broccoli|Lettuce|Steak|Spinach": "Steak Power Salad",
		"Broccoli|Lettuce|Tofu|Spinach": "Vegan Greens Delight",
		"Broccoli|Peas|Potato|Rice": "Green Comfort Bowl",
		"Broccoli|Peas|Salmon|Spinach": "Omega Super Greens",
		"Broccoli|Peas|Steak|Spinach": "Power Green Steak Bowl",
		"Broccoli|Peas|Tofu|Spinach": "Vegan Green Harmony",
		"Broccoli|Potato|Rice|Salmon": "Salmon Veggie Grain",
		"Broccoli|Potato|Rice|Spinach": "Green Grain Comfort",
		"Broccoli|Potato|Rice|Steak": "Steak Veggie Bowl",
		"Broccoli|Potato|Rice|Tofu": "Tofu Comfort Bowl",
		"Broccoli|Potato|Salmon|Spinach": "Omega Comfort Bowl",
		"Broccoli|Potato|Steak|Spinach": "Power Steak Veggie",
		"Broccoli|Potato|Tofu|Spinach": "Vegan Comfort Mix",
		"Broccoli|Rice|Salmon|Spinach": "Omega Green Rice",
		"Broccoli|Rice|Steak|Spinach": "Steak Green Grain",
		"Broccoli|Rice|Tofu|Spinach": "Vegan Rice Power",
		"Carrot|Chicken Breast|Lettuce|Peas": "Garden Fresh Chicken",
		"Carrot|Chicken Breast|Lettuce|Potato": "Chicken Harvest Salad",
		"Carrot|Chicken Breast|Lettuce|Rice": "Chicken Garden Rice",
		"Carrot|Chicken Breast|Peas|Potato": "Rustic Chicken Bowl",
		"Carrot|Chicken Breast|Peas|Rice": "Chicken Veggie Rice",
		"Carrot|Chicken Breast|Potato|Rice": "Farmhouse Chicken Bowl",
		"Carrot|Chicken Breast|Salmon|Spinach": "Protein Garden Fusion",
		"Carrot|Chicken Breast|Steak|Spinach": "Meat Lover's Veggie Bowl",
		"Carrot|Chicken Breast|Tofu|Spinach": "Balanced Protein Bowl",
		"Carrot|Lettuce|Peas|Potato": "Garden Veggie Mix",
		"Carrot|Lettuce|Peas|Rice": "Fresh Garden Rice",
		"Carrot|Lettuce|Potato|Rice": "Root Grain Salad",
		"Carrot|Lettuce|Salmon|Spinach": "Ocean Garden Delight",
		"Carrot|Lettuce|Steak|Spinach": "Steak Garden Plate",
		"Carrot|Lettuce|Tofu|Spinach": "Vegan Garden Fresh",
		"Carrot|Peas|Potato|Rice": "Veggie Harmony Bowl",
		"Carrot|Peas|Salmon|Spinach": "Omega Veggie Delight",
		"Carrot|Peas|Steak|Spinach": "Steak Veggie Power",
		"Carrot|Peas|Tofu|Spinach": "Vegan Veggie Bowl",
		"Carrot|Potato|Rice|Salmon": "Salmon Root Grain",
		"Carrot|Potato|Rice|Spinach": "Green Root Rice",
		"Carrot|Potato|Rice|Steak": "Steak Root Bowl",
		"Carrot|Potato|Rice|Tofu": "Tofu Root Grain",
		"Carrot|Potato|Salmon|Spinach": "Omega Root Bowl",
		"Carrot|Potato|Steak|Spinach": "Hearty Steak Mix",
		"Carrot|Potato|Tofu|Spinach": "Vegan Root Bowl",
		"Carrot|Rice|Salmon|Spinach": "Salmon Carrot Rice",
		"Carrot|Rice|Steak|Spinach": "Steak Carrot Grain",
		"Carrot|Rice|Tofu|Spinach": "Tofu Carrot Bowl",
		"Chicken Breast|Lettuce|Peas|Potato": "Classic Chicken Salad Mix",
		"Chicken Breast|Lettuce|Peas|Rice": "Light Chicken Rice Bowl",
		"Chicken Breast|Lettuce|Potato|Rice": "Chicken Grain Salad",
		"Chicken Breast|Lettuce|Salmon|Spinach": "Surf & Turf Greens Bowl",
		"Chicken Breast|Lettuce|Steak|Spinach": "Double Meat Salad Bowl",
		"Chicken Breast|Lettuce|Tofu|Spinach": "Protein Greens Salad",
		"Chicken Breast|Peas|Potato|Rice": "Hearty Chicken Combo",
		"Chicken Breast|Peas|Salmon|Spinach": "Surf & Turf Greens",
		"Chicken Breast|Peas|Steak|Spinach": "Power Meat Bowl",
		"Chicken Breast|Peas|Tofu|Spinach": "Protein Green Mix",
		"Chicken Breast|Potato|Rice|Salmon": "Surf & Grain Bowl",
		"Chicken Breast|Potato|Rice|Spinach": "Green Chicken Grain",
		"Chicken Breast|Potato|Rice|Steak": "Double Meat Grain Bowl",
		"Chicken Breast|Potato|Rice|Tofu": "Protein Grain Mix",
		"Chicken Breast|Potato|Salmon|Spinach": "Hearty Surf & Turf",
		"Chicken Breast|Potato|Steak|Spinach": "Power Protein Plate",
		"Chicken Breast|Potato|Tofu|Spinach": "Loaded Protein Bowl",
		"Chicken Breast|Rice|Salmon|Spinach": "Omega Chicken Rice",
		"Chicken Breast|Rice|Steak|Spinach": "Double Meat Rice",
		"Chicken Breast|Rice|Tofu|Spinach": "Protein Power Rice",
		"Lettuce|Peas|Potato|Rice": "Light Veggie Grain Bowl",
		"Lettuce|Peas|Salmon|Spinach": "Ocean Fresh Greens",
		"Lettuce|Peas|Steak|Spinach": "Steak Green Salad",
		"Lettuce|Peas|Tofu|Spinach": "Vegan Fresh Bowl",
		"Lettuce|Potato|Rice|Salmon": "Salmon Comfort Salad",
		"Lettuce|Potato|Rice|Spinach": "Green Grain Salad",
		"Lettuce|Potato|Rice|Steak": "Steak Salad Bowl",
		"Lettuce|Potato|Rice|Tofu": "Tofu Comfort Salad",
		"Lettuce|Potato|Salmon|Spinach": "Ocean Garden Mix",
		"Lettuce|Potato|Steak|Spinach": "Hearty Steak Salad",
		"Lettuce|Potato|Tofu|Spinach": "Vegan Comfort Salad",
		"Lettuce|Rice|Salmon|Spinach": "Light Omega Bowl",
		"Lettuce|Rice|Steak|Spinach": "Steak Grain Salad",
		"Lettuce|Rice|Tofu|Spinach": "Vegan Grain Salad",
		"Peas|Potato|Rice|Salmon": "Salmon Veggie Grain",
		"Peas|Potato|Rice|Spinach": "Green Comfort Rice",
		"Peas|Potato|Rice|Steak": "Steak Veggie Grain",
		"Peas|Potato|Rice|Tofu": "Tofu Veggie Grain",
		"Peas|Potato|Salmon|Spinach": "Omega Green Mix",
		"Peas|Potato|Steak|Spinach": "Power Green Bowl",
		"Peas|Potato|Tofu|Spinach": "Vegan Green Comfort",
		"Peas|Rice|Salmon|Spinach": "Omega Green Rice",
		"Peas|Rice|Steak|Spinach": "Steak Green Grain",
		"Peas|Rice|Tofu|Spinach": "Vegan Green Rice",
		"Potato|Rice|Salmon|Spinach": "Omega Comfort Grain",
		"Potato|Rice|Steak|Spinach": "Power Grain Bowl",
		"Potato|Rice|Tofu|Spinach": "Vegan Comfort Grain",
		"Asparagus|Salmon|Steak|Tofu": "Ultimate Protein Asparagus",
		"Broccoli|Salmon|Steak|Tofu": "Triple Protein Greens",
		"Carrot|Salmon|Steak|Tofu": "Protein Root Bowl",
		"Chicken Breast|Salmon|Steak|Tofu": "Quad Protein Power",
		"Lettuce|Salmon|Steak|Tofu": "Ultimate Protein Salad",
		"Peas|Salmon|Steak|Tofu": "Protein Green Bowl",
		"Potato|Salmon|Steak|Tofu": "Hearty Protein Mix",
		"Rice|Salmon|Steak|Tofu": "Ultimate Protein Grain",
		"Asparagus|Salmon|Spinach|Steak": "Power Protein Spring",
		"Asparagus|Salmon|Spinach|Tofu": "Omega Vegan Mix",
		"Asparagus|Steak|Spinach|Tofu": "Power Vegan Protein",
		"Broccoli|Salmon|Spinach|Steak": "Super Green Protein",
		"Broccoli|Salmon|Spinach|Tofu": "Omega Vegan Greens",
		"Broccoli|Steak|Spinach|Tofu": "Vegan Power Greens",
		"Carrot|Salmon|Spinach|Steak": "Protein Garden Bowl",
		"Carrot|Salmon|Spinach|Tofu": "Omega Garden Mix",
		"Carrot|Steak|Spinach|Tofu": "Power Garden Protein",
		"Chicken Breast|Salmon|Spinach|Steak": "Triple Meat Power",
		"Chicken Breast|Salmon|Spinach|Tofu": "Balanced Protein Mix",
		"Chicken Breast|Steak|Spinach|Tofu": "Power Protein Fusion",
		"Lettuce|Salmon|Spinach|Steak": "Ultimate Protein Greens",
		"Lettuce|Salmon|Spinach|Tofu": "Omega Vegan Salad",
		"Lettuce|Steak|Spinach|Tofu": "Power Vegan Salad",
		"Peas|Salmon|Spinach|Steak": "Green Protein Power",
		"Peas|Salmon|Spinach|Tofu": "Vegan Omega Greens",
		"Peas|Steak|Spinach|Tofu": "Vegan Power Peas",
		"Potato|Salmon|Spinach|Steak": "Hearty Power Bowl",
		"Potato|Salmon|Spinach|Tofu": "Omega Vegan Comfort",
		"Potato|Steak|Spinach|Tofu": "Power Vegan Comfort",
		"Rice|Salmon|Spinach|Steak": "Ultimate Protein Rice",
		"Rice|Salmon|Spinach|Tofu": "Omega Vegan Grain",
		"Rice|Steak|Spinach|Tofu": "Power Vegan Rice",
		"Asparagus|Bread|Salmon|Steak": "Premium Meat Sandwich",
		"Asparagus|Bread|Salmon|Tofu": "Omega Protein Sub",
		"Asparagus|Bread|Steak|Tofu": "Power Protein Sandwich",
		"Bread|Broccoli|Salmon|Steak": "Double Meat Green Sub",
		"Bread|Broccoli|Salmon|Tofu": "Omega Green Sandwich",
		"Bread|Broccoli|Steak|Tofu": "Power Vegan Sub",
		"Bread|Carrot|Salmon|Steak": "Surf & Turf Garden Sub",
		"Bread|Carrot|Salmon|Tofu": "Omega Garden Sandwich",
		"Bread|Carrot|Steak|Tofu": "Power Garden Sub",
		"Bread|Chicken Breast|Salmon|Steak": "Triple Meat Sandwich",
		"Bread|Chicken Breast|Salmon|Tofu": "Protein Fusion Sub",
		"Bread|Chicken Breast|Steak|Tofu": "Ultimate Protein Sub",
		"Bread|Lettuce|Salmon|Steak": "Surf & Turf Salad Sub",
		"Bread|Lettuce|Salmon|Tofu": "Omega Fresh Sandwich",
		"Bread|Lettuce|Steak|Tofu": "Power Salad Sub",
		"Bread|Peas|Salmon|Steak": "Protein Pea Sandwich",
		"Bread|Peas|Salmon|Tofu": "Omega Pea Sub",
		"Bread|Peas|Steak|Tofu": "Power Pea Sandwich",
		"Bread|Potato|Salmon|Steak": "Hearty Meat Sandwich",
		"Bread|Potato|Salmon|Tofu": "Omega Comfort Sub",
		"Bread|Potato|Steak|Tofu": "Power Comfort Sandwich",
		"Bread|Rice|Salmon|Steak": "Protein Grain Sandwich",
		"Bread|Rice|Salmon|Tofu": "Omega Rice Sub",
		"Bread|Rice|Steak|Tofu": "Power Grain Sandwich",
		
		# 4-ingredient continued (Batch 4: +100 recipes)
		"Bread|Carrot|Lettuce|Peas": "Fresh Veggie Sandwich",
		"Bread|Carrot|Lettuce|Potato": "Garden Root Sub",
		"Bread|Carrot|Lettuce|Rice": "Fresh Grain Sandwich",
		"Bread|Carrot|Peas|Potato": "Veggie Root Sub",
		"Bread|Carrot|Peas|Rice": "Garden Grain Sandwich",
		"Bread|Carrot|Potato|Rice": "Root Carb Sub",
		"Bread|Chicken Breast|Peas|Potato": "Hearty Chicken Sub",
		"Bread|Chicken Breast|Peas|Rice": "Chicken Veggie Rice Wrap",
		"Bread|Chicken Breast|Potato|Rice": "Loaded Chicken Sandwich",
		"Bread|Lettuce|Peas|Potato": "Fresh Garden Sub",
		"Bread|Lettuce|Peas|Rice": "Light Veggie Wrap",
		"Bread|Lettuce|Potato|Rice": "Simple Garden Sub",
		"Bread|Peas|Potato|Rice": "Triple Carb Sandwich",
		"Broccoli|Carrot|Chicken Breast|Salmon": "Surf & Garden Chicken",
		"Broccoli|Carrot|Chicken Breast|Steak": "Double Meat Veggie Bowl",
		"Broccoli|Carrot|Chicken Breast|Tofu": "Balanced Protein Garden",
		"Broccoli|Carrot|Lettuce|Salmon": "Ocean Garden Salad",
		"Broccoli|Carrot|Lettuce|Steak": "Steak Garden Salad",
		"Broccoli|Carrot|Lettuce|Tofu": "Vegan Garden Mix",
		"Broccoli|Carrot|Peas|Salmon": "Omega Veggie Medley",
		"Broccoli|Carrot|Peas|Steak": "Steak Garden Greens",
		"Broccoli|Carrot|Peas|Tofu": "Vegan Veggie Power",
		"Broccoli|Carrot|Potato|Salmon": "Salmon Root Garden",
		"Broccoli|Carrot|Potato|Steak": "Steak Root Medley",
		"Broccoli|Carrot|Potato|Tofu": "Vegan Root Garden",
		"Broccoli|Carrot|Rice|Salmon": "Salmon Veggie Rice",
		"Broccoli|Carrot|Rice|Steak": "Steak Veggie Rice",
		"Broccoli|Carrot|Rice|Tofu": "Tofu Veggie Rice",
		"Broccoli|Chicken Breast|Lettuce|Salmon": "Surf & Turf Green Bowl",
		"Broccoli|Chicken Breast|Lettuce|Steak": "Double Meat Green Salad",
		"Broccoli|Chicken Breast|Lettuce|Tofu": "Protein Green Salad",
		"Broccoli|Chicken Breast|Peas|Salmon": "Surf & Turf Greens Mix",
		"Broccoli|Chicken Breast|Peas|Steak": "Power Meat Greens",
		"Broccoli|Chicken Breast|Peas|Tofu": "Balanced Protein Greens",
		"Broccoli|Chicken Breast|Potato|Salmon": "Hearty Surf & Turf Bowl",
		"Broccoli|Chicken Breast|Potato|Steak": "Power Meat Comfort",
		"Broccoli|Chicken Breast|Potato|Tofu": "Protein Comfort Bowl",
		"Broccoli|Chicken Breast|Rice|Salmon": "Surf & Turf Green Rice",
		"Broccoli|Chicken Breast|Rice|Steak": "Double Meat Green Rice",
		"Broccoli|Chicken Breast|Rice|Tofu": "Protein Green Rice",
		"Broccoli|Lettuce|Peas|Salmon": "Omega Triple Greens",
		"Broccoli|Lettuce|Peas|Steak": "Steak Triple Greens",
		"Broccoli|Lettuce|Peas|Tofu": "Vegan Triple Greens",
		"Broccoli|Lettuce|Potato|Salmon": "Ocean Garden Comfort",
		"Broccoli|Lettuce|Potato|Steak": "Steak Garden Comfort",
		"Broccoli|Lettuce|Potato|Tofu": "Vegan Garden Comfort",
		"Broccoli|Lettuce|Rice|Salmon": "Light Omega Rice",
		"Broccoli|Lettuce|Rice|Steak": "Steak Green Rice Bowl",
		"Broccoli|Lettuce|Rice|Tofu": "Vegan Green Rice",
		"Broccoli|Peas|Potato|Salmon": "Omega Green Comfort",
		"Broccoli|Peas|Potato|Steak": "Power Green Comfort",
		"Broccoli|Peas|Potato|Tofu": "Vegan Green Harmony",
		"Broccoli|Peas|Rice|Salmon": "Omega Green Grain",
		"Broccoli|Peas|Rice|Steak": "Power Green Grain",
		"Broccoli|Peas|Rice|Tofu": "Vegan Green Grain",
		"Broccoli|Potato|Salmon|Steak": "Double Meat Green Bowl",
		"Broccoli|Potato|Salmon|Tofu": "Omega Green Comfort",
		"Broccoli|Potato|Steak|Tofu": "Power Green Comfort",
		"Broccoli|Rice|Salmon|Steak": "Double Protein Green Rice",
		"Broccoli|Rice|Salmon|Tofu": "Omega Green Grain Bowl",
		"Broccoli|Rice|Steak|Tofu": "Power Green Grain Bowl",
		"Broccoli|Salmon|Steak|Spinach": "Triple Protein Greens Power",
		"Broccoli|Salmon|Tofu|Spinach": "Omega Vegan Power",
		"Broccoli|Steak|Tofu|Spinach": "Power Vegan Greens",
		"Carrot|Chicken Breast|Lettuce|Salmon": "Surf & Garden Salad",
		"Carrot|Chicken Breast|Lettuce|Steak": "Double Meat Garden Salad",
		"Carrot|Chicken Breast|Lettuce|Tofu": "Protein Garden Salad",
		"Carrot|Chicken Breast|Peas|Salmon": "Surf & Garden Medley",
		"Carrot|Chicken Breast|Peas|Steak": "Double Meat Garden Bowl",
		"Carrot|Chicken Breast|Peas|Tofu": "Balanced Garden Protein",
		"Carrot|Chicken Breast|Potato|Salmon": "Hearty Surf & Garden",
		"Carrot|Chicken Breast|Potato|Steak": "Double Meat Root Bowl",
		"Carrot|Chicken Breast|Potato|Tofu": "Protein Root Comfort",
		"Carrot|Chicken Breast|Rice|Salmon": "Surf & Garden Rice",
		"Carrot|Chicken Breast|Rice|Steak": "Double Meat Carrot Rice",
		"Carrot|Chicken Breast|Rice|Tofu": "Protein Carrot Grain",
		"Carrot|Lettuce|Peas|Salmon": "Ocean Garden Fresh",
		"Carrot|Lettuce|Peas|Steak": "Steak Garden Fresh",
		"Carrot|Lettuce|Peas|Tofu": "Vegan Garden Fresh",
		"Carrot|Lettuce|Potato|Salmon": "Ocean Root Salad",
		"Carrot|Lettuce|Potato|Steak": "Steak Root Salad",
		"Carrot|Lettuce|Potato|Tofu": "Vegan Root Salad",
		"Carrot|Lettuce|Rice|Salmon": "Light Salmon Carrot Bowl",
		"Carrot|Lettuce|Rice|Steak": "Steak Carrot Salad Bowl",
		"Carrot|Lettuce|Rice|Tofu": "Vegan Carrot Grain",
		"Carrot|Peas|Potato|Salmon": "Omega Root Veggie",
		"Carrot|Peas|Potato|Steak": "Power Root Veggie",
		"Carrot|Peas|Potato|Tofu": "Vegan Root Veggie",
		"Carrot|Peas|Rice|Salmon": "Omega Garden Rice",
		"Carrot|Peas|Rice|Steak": "Power Garden Rice",
		"Carrot|Peas|Rice|Tofu": "Vegan Garden Rice",
		"Carrot|Potato|Salmon|Steak": "Double Protein Root",
		"Carrot|Potato|Salmon|Tofu": "Omega Root Comfort",
		"Carrot|Potato|Steak|Tofu": "Power Root Comfort",
		"Carrot|Rice|Salmon|Steak": "Double Protein Carrot Grain",
		"Carrot|Rice|Salmon|Tofu": "Omega Carrot Grain",
		"Carrot|Rice|Steak|Tofu": "Power Carrot Grain",
		"Carrot|Salmon|Steak|Spinach": "Triple Protein Garden",
		"Carrot|Salmon|Tofu|Spinach": "Omega Vegan Garden",
		"Carrot|Steak|Tofu|Spinach": "Power Vegan Garden",
		"Chicken Breast|Lettuce|Peas|Salmon": "Surf & Turf Fresh Greens",
		"Chicken Breast|Lettuce|Peas|Steak": "Double Meat Fresh Bowl",
		"Chicken Breast|Lettuce|Peas|Tofu": "Protein Fresh Bowl",
		"Chicken Breast|Lettuce|Potato|Salmon": "Hearty Surf & Turf Salad",
		"Chicken Breast|Lettuce|Potato|Steak": "Double Meat Comfort Salad",
		"Chicken Breast|Lettuce|Potato|Tofu": "Protein Comfort Salad",
		"Chicken Breast|Lettuce|Rice|Salmon": "Surf & Turf Light Bowl",
		"Chicken Breast|Lettuce|Rice|Steak": "Double Meat Rice Salad",
		"Chicken Breast|Lettuce|Rice|Tofu": "Protein Rice Salad",
		"Chicken Breast|Peas|Potato|Salmon": "Hearty Surf & Garden",
		"Chicken Breast|Peas|Potato|Steak": "Double Meat Green Comfort",
		"Chicken Breast|Peas|Potato|Tofu": "Balanced Protein Comfort",
		"Chicken Breast|Peas|Rice|Salmon": "Surf & Turf Green Rice",
		"Chicken Breast|Peas|Rice|Steak": "Double Meat Green Grain",
		"Chicken Breast|Peas|Rice|Tofu": "Protein Green Grain",
		"Chicken Breast|Potato|Salmon|Steak": "Triple Meat Comfort",
		"Chicken Breast|Potato|Salmon|Tofu": "Omega Protein Comfort",
		"Chicken Breast|Potato|Steak|Tofu": "Power Protein Comfort",
		"Chicken Breast|Rice|Salmon|Steak": "Triple Meat Rice Bowl",
		"Chicken Breast|Rice|Salmon|Tofu": "Omega Protein Rice",
		"Chicken Breast|Rice|Steak|Tofu": "Power Protein Rice",
		"Chicken Breast|Salmon|Steak|Spinach": "Quad Protein Bowl",
		"Chicken Breast|Salmon|Tofu|Spinach": "Balanced Omega Protein",
		"Chicken Breast|Steak|Tofu|Spinach": "Triple Power Protein",
		"Lettuce|Peas|Potato|Salmon": "Ocean Fresh Comfort",
		"Lettuce|Peas|Potato|Steak": "Steak Fresh Comfort",
		"Lettuce|Peas|Potato|Tofu": "Vegan Fresh Comfort",
		"Lettuce|Peas|Rice|Salmon": "Light Omega Green",
		"Lettuce|Peas|Rice|Steak": "Steak Light Green",
		"Lettuce|Peas|Rice|Tofu": "Vegan Light Green",
		"Lettuce|Potato|Salmon|Steak": "Double Meat Salad Bowl",
		"Lettuce|Potato|Salmon|Tofu": "Omega Comfort Salad",
		"Lettuce|Potato|Steak|Tofu": "Power Comfort Salad",
		"Lettuce|Rice|Salmon|Steak": "Double Protein Salad Grain",
		"Lettuce|Rice|Salmon|Tofu": "Omega Fresh Grain",
		"Lettuce|Rice|Steak|Tofu": "Power Fresh Grain",
		"Lettuce|Salmon|Steak|Spinach": "Triple Protein Fresh Bowl",
		"Lettuce|Salmon|Tofu|Spinach": "Omega Vegan Fresh",
		"Lettuce|Steak|Tofu|Spinach": "Power Vegan Fresh",
		"Peas|Potato|Salmon|Steak": "Double Protein Green Bowl",
		"Peas|Potato|Salmon|Tofu": "Omega Green Comfort",
		"Peas|Potato|Steak|Tofu": "Power Green Comfort",
		"Peas|Rice|Salmon|Steak": "Double Protein Green Grain",
		"Peas|Rice|Salmon|Tofu": "Omega Green Rice Bowl",
		"Peas|Rice|Steak|Tofu": "Power Green Rice Bowl",
		"Peas|Salmon|Steak|Spinach": "Triple Protein Greens",
		"Peas|Salmon|Tofu|Spinach": "Omega Vegan Peas",
		"Peas|Steak|Tofu|Spinach": "Power Vegan Peas",
		"Potato|Salmon|Steak|Spinach": "Triple Protein Comfort",
		"Potato|Salmon|Tofu|Spinach": "Omega Vegan Comfort Bowl",
		"Potato|Steak|Tofu|Spinach": "Power Vegan Comfort Bowl",
		"Rice|Salmon|Steak|Spinach": "Triple Protein Grain",
		"Rice|Salmon|Tofu|Spinach": "Omega Vegan Grain Bowl",
		"Rice|Steak|Tofu|Spinach": "Power Vegan Grain Bowl",
		"Asparagus|Broccoli|Carrot|Salmon": "Premium Omega Garden",
		"Asparagus|Broccoli|Carrot|Steak": "Premium Steak Garden",
		"Asparagus|Broccoli|Carrot|Tofu": "Premium Vegan Garden",
		"Asparagus|Broccoli|Chicken Breast|Salmon": "Spring Surf & Turf",
		"Asparagus|Broccoli|Chicken Breast|Steak": "Spring Double Meat",
		"Asparagus|Broccoli|Chicken Breast|Tofu": "Spring Protein Bowl",
		"Asparagus|Broccoli|Lettuce|Salmon": "Omega Spring Greens",
		"Asparagus|Broccoli|Lettuce|Steak": "Steak Spring Greens",
		"Asparagus|Broccoli|Lettuce|Tofu": "Vegan Spring Greens",
		"Asparagus|Broccoli|Peas|Salmon": "Premium Green Omega",
		"Asparagus|Broccoli|Peas|Steak": "Premium Green Steak",
		"Asparagus|Broccoli|Peas|Tofu": "Premium Vegan Greens",
		"Asparagus|Broccoli|Potato|Salmon": "Hearty Spring Omega",
		"Asparagus|Broccoli|Potato|Steak": "Hearty Spring Steak",
		"Asparagus|Broccoli|Potato|Tofu": "Hearty Spring Vegan",
		"Asparagus|Broccoli|Rice|Salmon": "Spring Omega Rice",
		"Asparagus|Broccoli|Rice|Steak": "Spring Steak Rice",
		"Asparagus|Broccoli|Rice|Tofu": "Spring Vegan Rice",
		"Asparagus|Broccoli|Salmon|Steak": "Spring Double Protein",
		"Asparagus|Broccoli|Salmon|Tofu": "Spring Omega Vegan",
		"Asparagus|Broccoli|Steak|Tofu": "Spring Power Vegan",
		"Asparagus|Carrot|Chicken Breast|Salmon": "Garden Surf & Turf",
		"Asparagus|Carrot|Chicken Breast|Steak": "Garden Double Meat",
		"Asparagus|Carrot|Chicken Breast|Tofu": "Garden Protein Bowl",
		"Asparagus|Carrot|Lettuce|Salmon": "Spring Salmon Salad",
		"Asparagus|Carrot|Lettuce|Steak": "Spring Steak Salad",
		"Asparagus|Carrot|Lettuce|Tofu": "Spring Vegan Salad",
		"Asparagus|Carrot|Peas|Salmon": "Spring Garden Omega",
		"Asparagus|Carrot|Peas|Steak": "Spring Garden Steak",
		"Asparagus|Carrot|Peas|Tofu": "Spring Garden Vegan",
		"Asparagus|Carrot|Potato|Salmon": "Root Spring Omega",
		"Asparagus|Carrot|Potato|Steak": "Root Spring Steak",
		"Asparagus|Carrot|Potato|Tofu": "Root Spring Vegan",
		"Asparagus|Carrot|Rice|Salmon": "Spring Omega Grain",
		"Asparagus|Carrot|Rice|Steak": "Spring Steak Grain",
		"Asparagus|Carrot|Rice|Tofu": "Spring Vegan Grain",
		"Asparagus|Carrot|Salmon|Steak": "Spring Protein Medley",
		"Asparagus|Carrot|Salmon|Tofu": "Spring Omega Bowl",
		"Asparagus|Carrot|Steak|Tofu": "Spring Power Bowl",
		"Bread|Carrot|Lettuce|Salmon": "Ocean Garden Wrap",
		"Bread|Carrot|Lettuce|Steak": "Steak Garden Wrap",
		"Bread|Carrot|Lettuce|Tofu": "Vegan Garden Wrap",
		"Bread|Carrot|Peas|Salmon": "Salmon Veggie Sub",
		"Bread|Carrot|Peas|Steak": "Steak Veggie Sub",
		"Bread|Carrot|Peas|Tofu": "Tofu Veggie Sub",
		"Bread|Carrot|Potato|Salmon": "Salmon Root Sandwich",
		"Bread|Carrot|Potato|Steak": "Steak Root Sandwich",
		"Bread|Carrot|Potato|Tofu": "Tofu Root Sandwich",
		"Bread|Carrot|Rice|Salmon": "Salmon Carrot Wrap",
		"Bread|Carrot|Rice|Steak": "Steak Carrot Wrap",
		"Bread|Carrot|Rice|Tofu": "Tofu Carrot Wrap",
		"Bread|Chicken Breast|Lettuce|Salmon": "Surf & Turf Club Sandwich",
		"Bread|Chicken Breast|Lettuce|Steak": "Ultimate Meat Club",
		"Bread|Chicken Breast|Lettuce|Tofu": "Protein Club Sandwich",
		"Bread|Chicken Breast|Peas|Salmon": "Surf & Turf Green Sub",
		"Bread|Chicken Breast|Peas|Steak": "Power Meat Sub",
		"Bread|Chicken Breast|Peas|Tofu": "Balanced Protein Sub",
		"Bread|Chicken Breast|Potato|Salmon": "Hearty Surf & Turf Sub",
		"Bread|Chicken Breast|Potato|Steak": "Hearty Double Meat Sub",
		"Bread|Chicken Breast|Potato|Tofu": "Hearty Protein Sub",
		"Bread|Chicken Breast|Rice|Salmon": "Surf & Turf Rice Wrap",
		"Bread|Chicken Breast|Rice|Steak": "Double Meat Rice Wrap",
		"Bread|Chicken Breast|Rice|Tofu": "Protein Rice Wrap",
		"Bread|Lettuce|Peas|Salmon": "Light Ocean Sandwich",
		"Bread|Lettuce|Peas|Steak": "Light Steak Sandwich",
		"Bread|Lettuce|Peas|Tofu": "Light Vegan Sandwich",
		"Bread|Lettuce|Potato|Salmon": "Ocean Comfort Sub",
		"Bread|Lettuce|Potato|Steak": "Steak Comfort Sub",
		"Bread|Lettuce|Potato|Tofu": "Vegan Comfort Sub",
		"Bread|Lettuce|Rice|Salmon": "Light Salmon Grain Sub",
		"Bread|Lettuce|Rice|Steak": "Light Steak Grain Sub",
		"Bread|Lettuce|Rice|Tofu": "Light Vegan Grain Sub",
		"Bread|Peas|Potato|Salmon": "Salmon Green Comfort Sub",
		"Bread|Peas|Potato|Steak": "Steak Green Comfort Sub",
		"Bread|Peas|Potato|Tofu": "Vegan Green Comfort Sub",
		"Bread|Peas|Rice|Salmon": "Salmon Green Grain Sub",
		"Bread|Peas|Rice|Steak": "Steak Green Grain Sub",
		"Bread|Peas|Rice|Tofu": "Vegan Green Grain Sub",
		"Bread|Potato|Rice|Salmon": "Salmon Carb Sub",
		"Bread|Potato|Rice|Steak": "Steak Carb Sub",
		"Bread|Potato|Rice|Tofu": "Vegan Carb Sub",
		"Bread|Salmon|Spinach|Steak": "Premium Protein Sandwich",
		"Bread|Salmon|Spinach|Tofu": "Omega Power Sub",
		"Bread|Spinach|Steak|Tofu": "Power Vegan Sandwich",
		"Bread|Broccoli|Carrot|Salmon": "Ocean Garden Green Sub",
		"Bread|Broccoli|Carrot|Steak": "Steak Garden Green Sub",
		"Bread|Broccoli|Carrot|Tofu": "Vegan Garden Green Sub",
		"Bread|Broccoli|Chicken Breast|Salmon": "Surf & Turf Greens Sub",
		"Bread|Broccoli|Chicken Breast|Steak": "Power Meat Greens Sub",
		"Bread|Broccoli|Chicken Breast|Tofu": "Balanced Protein Green Sub",
		"Bread|Broccoli|Lettuce|Salmon": "Ocean Triple Greens Sub",
		"Bread|Broccoli|Lettuce|Steak": "Steak Triple Greens Sub",
		"Bread|Broccoli|Lettuce|Tofu": "Vegan Triple Greens Sub",
		"Bread|Broccoli|Peas|Salmon": "Salmon Super Greens Sub",
		"Bread|Broccoli|Peas|Steak": "Steak Super Greens Sub",
		"Bread|Broccoli|Peas|Tofu": "Vegan Super Greens Sub",
		"Bread|Broccoli|Potato|Salmon": "Salmon Green Comfort Wrap",
		"Bread|Broccoli|Potato|Steak": "Steak Green Comfort Wrap",
		"Bread|Broccoli|Potato|Tofu": "Vegan Green Comfort Wrap",
		"Bread|Broccoli|Rice|Salmon": "Salmon Green Grain Wrap",
		"Bread|Broccoli|Rice|Steak": "Steak Green Grain Wrap",
		"Bread|Broccoli|Rice|Tofu": "Vegan Green Grain Wrap",
		"Asparagus|Chicken Breast|Lettuce|Salmon": "Spring Surf & Turf Salad",
		"Asparagus|Chicken Breast|Lettuce|Steak": "Spring Double Meat Salad",
		"Asparagus|Chicken Breast|Lettuce|Tofu": "Spring Protein Salad",
		"Asparagus|Chicken Breast|Peas|Salmon": "Spring Omega Chicken",
		"Asparagus|Chicken Breast|Peas|Steak": "Spring Power Chicken",
		"Asparagus|Chicken Breast|Peas|Tofu": "Spring Lean Protein",
		"Asparagus|Chicken Breast|Potato|Salmon": "Hearty Spring Protein Bowl",
		"Asparagus|Chicken Breast|Potato|Steak": "Hearty Spring Power Bowl",
		"Asparagus|Chicken Breast|Potato|Tofu": "Hearty Spring Balance Bowl",
		"Asparagus|Chicken Breast|Rice|Salmon": "Spring Omega Rice Bowl",
		"Asparagus|Chicken Breast|Rice|Steak": "Spring Power Rice Bowl",
		"Asparagus|Chicken Breast|Rice|Tofu": "Spring Protein Rice Bowl",
		"Asparagus|Chicken Breast|Salmon|Steak": "Spring Triple Meat Bowl",
		"Asparagus|Chicken Breast|Salmon|Tofu": "Spring Omega Fusion Bowl",
		"Asparagus|Chicken Breast|Steak|Tofu": "Spring Power Fusion Bowl",
		"Asparagus|Lettuce|Peas|Salmon": "Light Spring Omega Bowl",
		"Asparagus|Lettuce|Peas|Steak": "Light Spring Power Bowl",
		"Asparagus|Lettuce|Peas|Tofu": "Light Spring Vegan Bowl",
		"Asparagus|Lettuce|Potato|Salmon": "Fresh Spring Omega Bowl",
		"Asparagus|Lettuce|Potato|Steak": "Fresh Spring Steak Bowl",
		"Asparagus|Lettuce|Potato|Tofu": "Fresh Spring Vegan Bowl",
		"Asparagus|Lettuce|Rice|Salmon": "Spring Salmon Grain Bowl",
		"Asparagus|Lettuce|Rice|Steak": "Spring Steak Grain Bowl",
		"Asparagus|Lettuce|Rice|Tofu": "Spring Vegan Grain Bowl",
		"Asparagus|Lettuce|Salmon|Steak": "Spring Protein Salad Bowl",
		"Asparagus|Lettuce|Salmon|Tofu": "Spring Omega Salad Bowl",
		"Asparagus|Lettuce|Steak|Tofu": "Spring Power Salad Bowl",
		"Asparagus|Peas|Potato|Salmon": "Hearty Green Omega Bowl",
		"Asparagus|Peas|Potato|Steak": "Hearty Green Steak Bowl",
		"Asparagus|Peas|Potato|Tofu": "Hearty Green Vegan Bowl",
		"Asparagus|Peas|Rice|Salmon": "Spring Green Omega Rice",
		"Asparagus|Peas|Rice|Steak": "Spring Green Steak Rice",
		"Asparagus|Peas|Rice|Tofu": "Spring Green Vegan Rice",
		"Asparagus|Peas|Salmon|Steak": "Green Spring Protein Bowl",
		"Asparagus|Peas|Salmon|Tofu": "Green Spring Omega Bowl",
		"Asparagus|Peas|Steak|Tofu": "Green Spring Power Bowl",
		"Asparagus|Potato|Rice|Salmon": "Spring Comfort Omega Bowl",
		"Asparagus|Potato|Rice|Steak": "Spring Comfort Steak Bowl",
		"Asparagus|Potato|Rice|Tofu": "Spring Comfort Vegan Bowl",
		"Asparagus|Potato|Salmon|Steak": "Hearty Spring Protein Mix",
		"Asparagus|Potato|Salmon|Tofu": "Hearty Spring Omega Mix",
		"Asparagus|Potato|Steak|Tofu": "Hearty Spring Power Mix",
		"Asparagus|Rice|Salmon|Steak": "Spring Protein Grain Bowl",
		"Asparagus|Rice|Salmon|Tofu": "Spring Omega Fusion Grain",
		"Asparagus|Rice|Steak|Tofu": "Spring Power Fusion Grain",
		"Asparagus|Broccoli|Carrot|Spinach": "Super Spring Garden",
		"Asparagus|Broccoli|Chicken Breast|Spinach": "Spring Power Protein",
		"Asparagus|Broccoli|Lettuce|Spinach": "Premium Green Salad",
		"Asparagus|Broccoli|Peas|Spinach": "Ultra Green Bowl",
		"Asparagus|Broccoli|Potato|Spinach": "Hearty Spring Greens",
		"Asparagus|Broccoli|Rice|Spinach": "Spring Green Grain",
		"Asparagus|Carrot|Chicken Breast|Spinach": "Garden Protein Power",
		"Asparagus|Carrot|Lettuce|Spinach": "Spring Fresh Mix",
		"Asparagus|Carrot|Peas|Spinach": "Garden Spring Greens",
		"Asparagus|Carrot|Potato|Spinach": "Root Spring Power",
		"Asparagus|Carrot|Rice|Spinach": "Spring Garden Grain",
		"Asparagus|Chicken Breast|Lettuce|Spinach": "Fresh Spring Protein",
		"Asparagus|Chicken Breast|Peas|Spinach": "Green Spring Protein",
		"Asparagus|Chicken Breast|Potato|Spinach": "Hearty Spring Protein",
		"Asparagus|Chicken Breast|Rice|Spinach": "Spring Protein Grain",
		"Asparagus|Lettuce|Peas|Spinach": "Ultra Fresh Greens",
		"Asparagus|Lettuce|Potato|Spinach": "Spring Comfort Salad",
		"Asparagus|Lettuce|Rice|Spinach": "Spring Fresh Grain",
		"Asparagus|Peas|Potato|Spinach": "Green Spring Comfort",
		"Asparagus|Peas|Rice|Spinach": "Green Spring Rice",
		"Asparagus|Potato|Rice|Spinach": "Spring Comfort Grain",
		"Bread|Broccoli|Carrot|Spinach": "Power Garden Sub",
		"Bread|Broccoli|Chicken Breast|Spinach": "Green Protein Sub",
		"Bread|Broccoli|Lettuce|Spinach": "Super Green Sandwich",
		"Bread|Broccoli|Peas|Spinach": "Ultra Green Sub",
		"Bread|Broccoli|Potato|Spinach": "Hearty Green Sandwich",
		"Bread|Broccoli|Rice|Spinach": "Green Grain Sub",
		"Bread|Carrot|Chicken Breast|Spinach": "Garden Power Sub",
		"Bread|Carrot|Lettuce|Spinach": "Fresh Garden Sub",
		"Bread|Carrot|Peas|Spinach": "Green Garden Sub",
		"Bread|Carrot|Potato|Spinach": "Root Power Sandwich",
		"Bread|Carrot|Rice|Spinach": "Garden Grain Sub",
		"Bread|Chicken Breast|Lettuce|Spinach": "Fresh Protein Sandwich",
		"Bread|Chicken Breast|Peas|Spinach": "Green Protein Sub",
		"Bread|Chicken Breast|Potato|Spinach": "Hearty Protein Sandwich",
		"Bread|Chicken Breast|Rice|Spinach": "Protein Grain Wrap",
		"Bread|Lettuce|Peas|Spinach": "Ultra Fresh Sub",
		"Bread|Lettuce|Potato|Spinach": "Garden Comfort Sandwich",
		"Bread|Lettuce|Rice|Spinach": "Fresh Grain Sub",
		"Bread|Peas|Potato|Spinach": "Green Comfort Sub",
		"Bread|Peas|Rice|Spinach": "Green Grain Sandwich",
		"Bread|Potato|Rice|Spinach": "Comfort Grain Sandwich",
		"Broccoli|Carrot|Chicken Breast|Spinach": "Power Garden Protein",
		"Broccoli|Carrot|Lettuce|Spinach": "Ultimate Green Salad",
		"Broccoli|Carrot|Peas|Spinach": "Super Green Medley",
		"Broccoli|Carrot|Potato|Spinach": "Hearty Green Mix",
		"Broccoli|Carrot|Rice|Spinach": "Green Veggie Grain",
		"Broccoli|Chicken Breast|Lettuce|Spinach": "Fresh Protein Greens",
		"Broccoli|Chicken Breast|Peas|Spinach": "Super Protein Greens",
		"Broccoli|Chicken Breast|Potato|Spinach": "Hearty Protein Greens",
		"Broccoli|Chicken Breast|Rice|Spinach": "Protein Green Grain",
		"Broccoli|Lettuce|Peas|Spinach": "Quad Green Salad",
		"Broccoli|Lettuce|Potato|Spinach": "Garden Green Comfort",
		"Broccoli|Lettuce|Rice|Spinach": "Fresh Green Grain",
		"Broccoli|Peas|Potato|Spinach": "Ultimate Green Comfort",
		"Broccoli|Peas|Rice|Spinach": "Super Green Grain",
		"Carrot|Chicken Breast|Lettuce|Spinach": "Garden Protein Salad",
		"Carrot|Chicken Breast|Peas|Spinach": "Power Garden Chicken",
		"Carrot|Chicken Breast|Potato|Spinach": "Hearty Garden Protein",
		"Carrot|Chicken Breast|Rice|Spinach": "Garden Protein Grain",
		"Carrot|Lettuce|Peas|Spinach": "Fresh Garden Power",
		"Carrot|Lettuce|Potato|Spinach": "Root Garden Salad",
		"Carrot|Lettuce|Rice|Spinach": "Fresh Carrot Grain",
		"Carrot|Peas|Potato|Spinach": "Green Root Power",
		"Carrot|Peas|Rice|Spinach": "Green Carrot Grain",
		"Chicken Breast|Lettuce|Peas|Spinach": "Fresh Protein Power",
		"Chicken Breast|Lettuce|Potato|Spinach": "Comfort Protein Salad",
		"Chicken Breast|Lettuce|Rice|Spinach": "Fresh Protein Grain",
		"Chicken Breast|Peas|Potato|Spinach": "Hearty Green Protein",
		"Chicken Breast|Peas|Rice|Spinach": "Green Protein Grain",
		"Salmon|Spinach|Steak|Tofu": "Ultimate Protein Quartet",
		"Asparagus|Bread|Broccoli|Salmon": "Spring Salmon Sub",
		"Asparagus|Bread|Broccoli|Spinach": "Spring Power Wrap",
		"Asparagus|Bread|Broccoli|Steak": "Spring Steak Sandwich",
		"Asparagus|Bread|Broccoli|Tofu": "Spring Tofu Wrap",
		"Asparagus|Bread|Carrot|Salmon": "Spring Salmon Sandwich",
		"Asparagus|Bread|Carrot|Spinach": "Garden Spring Sub",
		"Asparagus|Bread|Carrot|Steak": "Spring Steak Wrap",
		"Asparagus|Bread|Carrot|Tofu": "Spring Tofu Sandwich",
		"Asparagus|Bread|Chicken Breast|Salmon": "Spring Surf & Turf Sub",
		"Asparagus|Bread|Chicken Breast|Spinach": "Power Spring Chicken",
		"Asparagus|Bread|Chicken Breast|Steak": "Spring Meat Sandwich",
		"Asparagus|Bread|Chicken Breast|Tofu": "Spring Protein Sandwich",
		"Asparagus|Bread|Lettuce|Salmon": "Light Spring Salmon Sub",
		"Asparagus|Bread|Lettuce|Spinach": "Fresh Spring Power",
		"Asparagus|Bread|Lettuce|Steak": "Light Spring Steak Sub",
		"Asparagus|Bread|Lettuce|Tofu": "Light Spring Tofu Sub",
		"Asparagus|Bread|Peas|Salmon": "Green Spring Salmon Sub",
		"Asparagus|Bread|Peas|Spinach": "Power Spring Green Sub",
		"Asparagus|Bread|Peas|Steak": "Green Spring Steak Sub",
		"Asparagus|Bread|Peas|Tofu": "Green Spring Tofu Sub",
		"Asparagus|Bread|Potato|Salmon": "Hearty Spring Salmon Sub",
		"Asparagus|Bread|Potato|Spinach": "Power Spring Comfort Sub",
		"Asparagus|Bread|Potato|Steak": "Hearty Spring Steak Sub",
		"Asparagus|Bread|Potato|Tofu": "Hearty Spring Tofu Sub",
		"Asparagus|Bread|Rice|Salmon": "Spring Salmon Grain Sub",
		"Asparagus|Bread|Rice|Spinach": "Power Spring Grain Sub",
		"Asparagus|Bread|Rice|Steak": "Spring Steak Grain Sub",
		"Asparagus|Bread|Rice|Tofu": "Spring Tofu Grain Sub",
		"Asparagus|Bread|Spinach|Steak": "Premium Spring Meat Sub",
		"Asparagus|Bread|Spinach|Tofu": "Premium Spring Vegan Sub",
		"Asparagus|Broccoli|Spinach|Steak": "Spring Power Steak Bowl",
		"Asparagus|Broccoli|Spinach|Tofu": "Spring Power Tofu Bowl",
		"Asparagus|Carrot|Spinach|Steak": "Spring Garden Steak",
		"Asparagus|Carrot|Spinach|Tofu": "Spring Garden Tofu",
		"Asparagus|Chicken Breast|Spinach|Steak": "Spring Double Meat Power",
		"Asparagus|Chicken Breast|Spinach|Tofu": "Spring Protein Fusion",
		"Asparagus|Lettuce|Spinach|Steak": "Fresh Spring Steak Bowl",
		"Asparagus|Lettuce|Spinach|Tofu": "Fresh Spring Tofu Bowl",
		"Asparagus|Peas|Potato|Rice": "Spring Veggie Medley",
		"Asparagus|Peas|Spinach|Steak": "Green Spring Steak Power",
		"Asparagus|Peas|Spinach|Tofu": "Green Spring Tofu Power",
		"Asparagus|Potato|Spinach|Steak": "Hearty Spring Steak Mix",
		"Asparagus|Potato|Spinach|Tofu": "Hearty Spring Tofu Mix",
		"Asparagus|Rice|Spinach|Steak": "Spring Steak Grain Bowl",
		"Asparagus|Rice|Spinach|Tofu": "Spring Tofu Grain Bowl",
		"Asparagus|Spinach|Steak|Tofu": "Spring Premium Protein Mix",
		"Bread|Broccoli|Spinach|Steak": "Power Green Steak Sub",
		"Bread|Broccoli|Spinach|Tofu": "Power Green Tofu Sub",
		"Bread|Carrot|Chicken Breast|Salmon": "Garden Surf & Turf Sub",
		"Bread|Carrot|Chicken Breast|Steak": "Garden Double Meat Sub",
		"Bread|Carrot|Chicken Breast|Tofu": "Garden Protein Sub",
		"Bread|Carrot|Spinach|Steak": "Garden Steak Power Sub",
		"Bread|Carrot|Spinach|Tofu": "Garden Tofu Power Sub",
		"Bread|Chicken Breast|Lettuce|Peas": "Fresh Chicken Club",
		"Bread|Chicken Breast|Lettuce|Potato": "Classic Chicken Club Sub",
		"Bread|Chicken Breast|Lettuce|Rice": "Chicken Rice Club",
		"Bread|Chicken Breast|Spinach|Steak": "Double Meat Power Sub",
		"Bread|Chicken Breast|Spinach|Tofu": "Protein Power Sandwich",
		"Bread|Lettuce|Spinach|Steak": "Fresh Steak Power Sub",
		"Bread|Lettuce|Spinach|Tofu": "Fresh Tofu Power Sub",
		"Bread|Peas|Spinach|Steak": "Green Steak Power Sub",
		"Bread|Peas|Spinach|Tofu": "Green Tofu Power Sub",
		"Bread|Potato|Spinach|Steak": "Hearty Steak Power Sub",
		"Bread|Potato|Spinach|Tofu": "Hearty Tofu Power Sub",
		"Bread|Rice|Spinach|Steak": "Steak Grain Power Sub",
		"Bread|Rice|Spinach|Tofu": "Tofu Grain Power Sub",
		"Bread|Salmon|Steak|Tofu": "Triple Protein Sandwich",
		"Broccoli|Carrot|Salmon|Steak": "Garden Double Protein Bowl",
		"Broccoli|Carrot|Salmon|Tofu": "Garden Omega Bowl",
		"Broccoli|Carrot|Spinach|Steak": "Power Garden Steak Bowl",
		"Broccoli|Carrot|Spinach|Tofu": "Power Garden Tofu Bowl",
		"Broccoli|Carrot|Steak|Tofu": "Garden Double Protein Mix",
		"Broccoli|Chicken Breast|Salmon|Steak": "Green Double Meat Bowl",
		"Broccoli|Chicken Breast|Salmon|Tofu": "Green Protein Fusion",
		"Broccoli|Chicken Breast|Spinach|Steak": "Power Chicken Steak Bowl",
		"Broccoli|Chicken Breast|Spinach|Tofu": "Power Chicken Tofu Bowl",
		"Broccoli|Chicken Breast|Steak|Tofu": "Green Triple Protein",
		"Broccoli|Lettuce|Salmon|Steak": "Fresh Green Double Protein",
		"Broccoli|Lettuce|Salmon|Tofu": "Fresh Green Omega Bowl",
		"Broccoli|Lettuce|Spinach|Steak": "Green Power Steak Salad",
		"Broccoli|Lettuce|Spinach|Tofu": "Green Power Tofu Salad",
		"Broccoli|Lettuce|Steak|Tofu": "Fresh Green Protein Mix",
		"Broccoli|Peas|Salmon|Steak": "Super Green Protein Bowl",
		"Broccoli|Peas|Salmon|Tofu": "Super Green Omega Bowl",
		"Broccoli|Peas|Spinach|Steak": "Ultra Green Steak Bowl",
		"Broccoli|Peas|Spinach|Tofu": "Ultra Green Tofu Bowl",
		"Broccoli|Peas|Steak|Tofu": "Green Power Protein Bowl",
		"Broccoli|Potato|Spinach|Steak": "Hearty Green Steak Bowl",
		"Broccoli|Potato|Spinach|Tofu": "Hearty Green Tofu Bowl",
		"Broccoli|Rice|Spinach|Steak": "Green Steak Grain Power",
		"Broccoli|Rice|Spinach|Tofu": "Green Tofu Grain Power",
		"Broccoli|Spinach|Steak|Tofu": "Green Premium Protein Bowl",
		"Carrot|Chicken Breast|Salmon|Steak": "Garden Surf & Turf Bowl",
		"Carrot|Chicken Breast|Salmon|Tofu": "Garden Omega Protein",
		"Carrot|Chicken Breast|Spinach|Steak": "Power Garden Chicken Steak",
		"Carrot|Chicken Breast|Spinach|Tofu": "Power Garden Chicken Tofu",
		"Carrot|Chicken Breast|Steak|Tofu": "Garden Triple Protein",
		"Carrot|Lettuce|Salmon|Steak": "Fresh Garden Double Protein",
		"Carrot|Lettuce|Salmon|Tofu": "Fresh Garden Omega",
		"Carrot|Lettuce|Spinach|Steak": "Garden Power Steak Salad",
		"Carrot|Lettuce|Spinach|Tofu": "Garden Power Tofu Salad",
		"Carrot|Lettuce|Steak|Tofu": "Fresh Garden Protein Mix",
		"Carrot|Peas|Salmon|Steak": "Garden Green Protein Bowl",
		"Carrot|Peas|Salmon|Tofu": "Garden Green Omega Bowl",
		"Carrot|Peas|Spinach|Steak": "Power Green Garden Steak",
		"Carrot|Peas|Spinach|Tofu": "Power Green Garden Tofu",
		"Carrot|Peas|Steak|Tofu": "Garden Green Protein Mix",
		"Carrot|Potato|Spinach|Steak": "Root Power Steak Bowl",
		"Carrot|Potato|Spinach|Tofu": "Root Power Tofu Bowl",
		"Carrot|Rice|Spinach|Steak": "Carrot Steak Grain Power",
		"Carrot|Rice|Spinach|Tofu": "Carrot Tofu Grain Power",
		"Carrot|Spinach|Steak|Tofu": "Garden Premium Protein Bowl",
		"Chicken Breast|Lettuce|Salmon|Steak": "Fresh Double Meat Salad",
		"Chicken Breast|Lettuce|Salmon|Tofu": "Fresh Omega Protein Salad",
		"Chicken Breast|Lettuce|Spinach|Steak": "Power Fresh Steak Salad",
		"Chicken Breast|Lettuce|Spinach|Tofu": "Power Fresh Tofu Salad",
		"Chicken Breast|Lettuce|Steak|Tofu": "Fresh Triple Protein Salad",
		"Chicken Breast|Peas|Salmon|Steak": "Green Double Meat Bowl",
		"Chicken Breast|Peas|Salmon|Tofu": "Green Omega Protein Bowl",
		"Chicken Breast|Peas|Spinach|Steak": "Power Green Chicken Steak",
		"Chicken Breast|Peas|Spinach|Tofu": "Power Green Chicken Tofu",
		"Chicken Breast|Peas|Steak|Tofu": "Green Triple Protein Bowl",
		"Chicken Breast|Potato|Spinach|Steak": "Hearty Power Chicken Steak",
		"Chicken Breast|Potato|Spinach|Tofu": "Hearty Power Chicken Tofu",
		"Chicken Breast|Rice|Spinach|Steak": "Chicken Steak Grain Power",
		"Chicken Breast|Rice|Spinach|Tofu": "Chicken Tofu Grain Power",
		"Chicken Breast|Spinach|Steak|Tofu": "Premium Triple Protein Bowl",
		"Lettuce|Peas|Potato|Spinach": "Fresh Green Power Salad",
		"Lettuce|Peas|Rice|Spinach": "Light Green Power Grain",
		"Lettuce|Peas|Salmon|Steak": "Fresh Green Double Protein",
		"Lettuce|Peas|Salmon|Tofu": "Fresh Green Omega Mix",
		"Lettuce|Peas|Spinach|Steak": "Light Power Steak Salad",
		"Lettuce|Peas|Spinach|Tofu": "Light Power Tofu Salad",
		"Lettuce|Peas|Steak|Tofu": "Fresh Green Triple Protein",
		"Lettuce|Potato|Spinach|Steak": "Comfort Power Steak Salad",
		"Lettuce|Potato|Spinach|Tofu": "Comfort Power Tofu Salad",
		"Lettuce|Rice|Spinach|Steak": "Light Steak Grain Power",
		"Lettuce|Rice|Spinach|Tofu": "Light Tofu Grain Power",
		"Lettuce|Spinach|Steak|Tofu": "Fresh Premium Protein Salad",
		"Peas|Potato|Spinach|Steak": "Hearty Green Power Steak",
		"Peas|Potato|Spinach|Tofu": "Hearty Green Power Tofu",
		"Peas|Rice|Spinach|Steak": "Green Steak Grain Power",
		"Peas|Rice|Spinach|Tofu": "Green Tofu Grain Power",
		"Peas|Spinach|Steak|Tofu": "Green Premium Protein Bowl",
		"Potato|Rice|Salmon|Steak": "Hearty Double Protein Grain",
		"Potato|Rice|Salmon|Tofu": "Hearty Omega Protein Grain",
		"Potato|Rice|Spinach|Steak": "Comfort Steak Grain Power",
		"Potato|Rice|Spinach|Tofu": "Comfort Tofu Grain Power",
		"Potato|Rice|Steak|Tofu": "Hearty Triple Protein Grain",
		"Potato|Spinach|Steak|Tofu": "Comfort Premium Protein Bowl",
		"Rice|Spinach|Steak|Tofu": "Ultimate Grain Protein Bowl",
		
		# ===== 5 INGREDIENTS =====
		# Total combinations: 1,287
		
		"Asparagus|Bread|Broccoli|Carrot|Chicken Breast": "Spring Garden Chicken Sandwich",
		"Asparagus|Bread|Broccoli|Carrot|Lettuce": "Ultimate Spring Veggie Sub",
		"Asparagus|Bread|Broccoli|Carrot|Peas": "Green Garden Delight Sub",
		"Asparagus|Bread|Broccoli|Carrot|Potato": "Hearty Spring Harvest Sub",
		"Asparagus|Bread|Broccoli|Carrot|Rice": "Spring Grain Garden Wrap",
		"Asparagus|Bread|Broccoli|Carrot|Salmon": "Premium Spring Salmon Sub",
		"Asparagus|Bread|Broccoli|Carrot|Spinach": "Power Spring Garden Sub",
		"Asparagus|Bread|Broccoli|Carrot|Steak": "Spring Steak Garden Sub",
		"Asparagus|Bread|Broccoli|Carrot|Tofu": "Spring Vegan Garden Sub",
		"Asparagus|Bread|Broccoli|Chicken Breast|Lettuce": "Fresh Spring Chicken Club",
		"Asparagus|Bread|Broccoli|Chicken Breast|Peas": "Green Spring Protein Sub",
		"Asparagus|Bread|Broccoli|Chicken Breast|Potato": "Hearty Spring Chicken Wrap",
		"Asparagus|Bread|Broccoli|Chicken Breast|Rice": "Gourmet Chicken Plate",
		"Asparagus|Bread|Broccoli|Chicken Breast|Salmon": "Spring Surf & Turf Sandwich",
		"Asparagus|Bread|Broccoli|Chicken Breast|Spinach": "Power Spring Chicken Sub",
		"Asparagus|Bread|Broccoli|Chicken Breast|Steak": "Spring Double Meat Sub",
		"Asparagus|Bread|Broccoli|Chicken Breast|Tofu": "Spring Protein Fusion Sub",
		"Asparagus|Bread|Broccoli|Lettuce|Peas": "Fresh Spring Greens Sub",
		"Asparagus|Bread|Broccoli|Lettuce|Potato": "Garden Spring Comfort Sub",
		"Asparagus|Bread|Broccoli|Lettuce|Rice": "Light Spring Grain Sub",
		"Asparagus|Bread|Broccoli|Lettuce|Salmon": "Spring Salmon Greens Sub",
		"Asparagus|Bread|Broccoli|Lettuce|Spinach": "Ultra Green Spring Sub",
		"Asparagus|Bread|Broccoli|Lettuce|Steak": "Spring Steak Greens Sub",
		"Asparagus|Bread|Broccoli|Lettuce|Tofu": "Spring Vegan Fresh Sub",
		"Asparagus|Bread|Broccoli|Peas|Potato": "Hearty Green Spring Sub",
		"Asparagus|Bread|Broccoli|Peas|Rice": "Spring Green Grain Wrap",
		"Asparagus|Bread|Broccoli|Peas|Salmon": "Spring Omega Greens Sub",
		"Asparagus|Bread|Broccoli|Peas|Spinach": "Power Green Spring Sub",
		"Asparagus|Bread|Broccoli|Peas|Steak": "Spring Steak Greens Wrap",
		"Asparagus|Bread|Broccoli|Peas|Tofu": "Spring Vegan Greens Sub",
		"Asparagus|Bread|Broccoli|Potato|Rice": "Spring Comfort Grain Sub",
		"Asparagus|Bread|Broccoli|Potato|Salmon": "Hearty Spring Salmon Sub",
		"Asparagus|Bread|Broccoli|Potato|Spinach": "Power Spring Comfort Sub",
		"Asparagus|Bread|Broccoli|Potato|Steak": "Hearty Spring Steak Sub",
		"Asparagus|Bread|Broccoli|Potato|Tofu": "Hearty Spring Vegan Sub",
		"Asparagus|Bread|Broccoli|Rice|Salmon": "Spring Salmon Grain Sub",
		"Asparagus|Bread|Broccoli|Rice|Spinach": "Power Spring Rice Sub",
		"Asparagus|Bread|Broccoli|Rice|Steak": "Spring Steak Grain Sub",
		"Asparagus|Bread|Broccoli|Rice|Tofu": "Spring Vegan Grain Sub",
		"Asparagus|Bread|Broccoli|Salmon|Spinach": "Premium Spring Omega Sub",
		"Asparagus|Bread|Broccoli|Salmon|Steak": "Spring Double Fish & Meat",
		"Asparagus|Bread|Broccoli|Salmon|Tofu": "Spring Omega Fusion Sub",
		"Asparagus|Bread|Broccoli|Spinach|Steak": "Power Spring Meat Sub",
		"Asparagus|Bread|Broccoli|Spinach|Tofu": "Power Spring Vegan Sub",
		"Asparagus|Bread|Broccoli|Steak|Tofu": "Spring Triple Protein Sub",
		"Asparagus|Bread|Carrot|Chicken Breast|Lettuce": "Fresh Garden Spring Club",
		"Asparagus|Bread|Carrot|Chicken Breast|Peas": "Garden Spring Chicken Sub",
		"Asparagus|Bread|Carrot|Chicken Breast|Potato": "Rustic Spring Chicken Sub",
		"Asparagus|Bread|Carrot|Chicken Breast|Rice": "Spring Chicken Harvest Wrap",
		"Asparagus|Bread|Carrot|Chicken Breast|Salmon": "Spring Surf Garden Sandwich",
		"Asparagus|Bread|Carrot|Chicken Breast|Spinach": "Power Garden Spring Sub",
		"Asparagus|Bread|Carrot|Chicken Breast|Steak": "Spring Meat Garden Sub",
		"Asparagus|Bread|Carrot|Chicken Breast|Tofu": "Spring Garden Protein Sub",
		"Asparagus|Bread|Carrot|Lettuce|Peas": "Light Spring Garden Sub",
		"Asparagus|Bread|Carrot|Lettuce|Potato": "Fresh Spring Root Sub",
		"Asparagus|Bread|Carrot|Lettuce|Rice": "Spring Fresh Grain Sub",
		"Asparagus|Bread|Carrot|Lettuce|Salmon": "Light Spring Salmon Sub",
		"Asparagus|Bread|Carrot|Lettuce|Spinach": "Fresh Spring Power Sub",
		"Asparagus|Bread|Carrot|Lettuce|Steak": "Light Spring Steak Sub",
		"Asparagus|Bread|Carrot|Lettuce|Tofu": "Light Spring Vegan Sub",
		"Asparagus|Bread|Carrot|Peas|Potato": "Hearty Spring Veggie Sub",
		"Asparagus|Bread|Carrot|Peas|Rice": "Spring Veggie Grain Sub",
		"Asparagus|Bread|Carrot|Peas|Salmon": "Spring Garden Salmon Sub",
		"Asparagus|Bread|Carrot|Peas|Spinach": "Power Spring Veggie Sub",
		"Asparagus|Bread|Carrot|Peas|Steak": "Spring Garden Steak Sub",
		"Asparagus|Bread|Carrot|Peas|Tofu": "Spring Garden Vegan Sub",
		"Asparagus|Bread|Carrot|Potato|Rice": "Spring Root Grain Sub",
		"Asparagus|Bread|Carrot|Potato|Salmon": "Hearty Spring Root Salmon",
		"Asparagus|Bread|Carrot|Potato|Spinach": "Power Spring Root Sub",
		"Asparagus|Bread|Carrot|Potato|Steak": "Hearty Spring Root Steak",
		"Asparagus|Bread|Carrot|Potato|Tofu": "Hearty Spring Root Vegan",
		"Asparagus|Bread|Carrot|Rice|Salmon": "Spring Salmon Carrot Wrap",
		"Asparagus|Bread|Carrot|Rice|Spinach": "Power Spring Carrot Sub",
		"Asparagus|Bread|Carrot|Rice|Steak": "Spring Steak Carrot Wrap",
		"Asparagus|Bread|Carrot|Rice|Tofu": "Spring Vegan Carrot Wrap",
		"Asparagus|Bread|Carrot|Salmon|Spinach": "Premium Spring Garden Sub",
		"Asparagus|Bread|Carrot|Salmon|Steak": "Spring Surf & Turf Garden",
		"Asparagus|Bread|Carrot|Salmon|Tofu": "Spring Omega Garden Sub",
		"Asparagus|Bread|Carrot|Spinach|Steak": "Power Spring Garden Meat",
		"Asparagus|Bread|Carrot|Spinach|Tofu": "Power Spring Garden Vegan",
		"Asparagus|Bread|Carrot|Steak|Tofu": "Spring Garden Protein Mix",
		"Asparagus|Bread|Chicken Breast|Lettuce|Peas": "Fresh Spring Chicken Club",
		"Asparagus|Bread|Chicken Breast|Lettuce|Potato": "Classic Spring Chicken Sub",
		"Asparagus|Bread|Chicken Breast|Lettuce|Rice": "Light Spring Chicken Wrap",
		"Asparagus|Bread|Chicken Breast|Lettuce|Salmon": "Spring Surf Chicken Club",
		"Asparagus|Bread|Chicken Breast|Lettuce|Spinach": "Supreme Sandwich",
		"Asparagus|Bread|Chicken Breast|Lettuce|Steak": "Spring Double Meat Club",
		"Asparagus|Bread|Chicken Breast|Lettuce|Tofu": "Spring Protein Club",
		"Asparagus|Bread|Chicken Breast|Peas|Potato": "Hearty Spring Chicken Sub",
		"Asparagus|Bread|Chicken Breast|Peas|Rice": "Spring Chicken Green Wrap",
		"Asparagus|Bread|Chicken Breast|Peas|Salmon": "Spring Surf Green Sub",
		"Asparagus|Bread|Chicken Breast|Peas|Spinach": "Power Spring Green Chicken",
		"Asparagus|Bread|Chicken Breast|Peas|Steak": "Spring Meat Green Sub",
		"Asparagus|Bread|Chicken Breast|Peas|Tofu": "Spring Protein Green Sub",
		"Asparagus|Bread|Chicken Breast|Potato|Rice": "Hearty Spring Chicken Wrap",
		"Asparagus|Bread|Chicken Breast|Potato|Salmon": "Spring Surf Comfort Sub",
		"Asparagus|Bread|Chicken Breast|Potato|Spinach": "Power Spring Chicken Comfort",
		"Asparagus|Bread|Chicken Breast|Potato|Steak": "Spring Meat Comfort Sub",
		"Asparagus|Bread|Chicken Breast|Potato|Tofu": "Spring Protein Comfort Sub",
		"Asparagus|Bread|Chicken Breast|Rice|Salmon": "Spring Surf Grain Wrap",
		"Asparagus|Bread|Chicken Breast|Rice|Spinach": "Power Spring Chicken Rice",
		"Asparagus|Bread|Chicken Breast|Rice|Steak": "Spring Meat Grain Wrap",
		"Asparagus|Bread|Chicken Breast|Rice|Tofu": "Spring Protein Rice Wrap",
		"Asparagus|Bread|Chicken Breast|Salmon|Spinach": "Premium Spring Surf Sub",
		"Asparagus|Bread|Chicken Breast|Salmon|Steak": "Spring Surf & Turf Deluxe",
		"Asparagus|Bread|Chicken Breast|Salmon|Tofu": "Spring Omega Protein Sub",
		"Asparagus|Bread|Chicken Breast|Spinach|Steak": "Power Spring Meat Sub",
		"Asparagus|Bread|Chicken Breast|Spinach|Tofu": "Power Spring Protein Sub",
		"Asparagus|Bread|Chicken Breast|Steak|Tofu": "Spring Triple Protein Sub",
		"Asparagus|Bread|Lettuce|Peas|Potato": "Fresh Spring Garden Sub",
		"Asparagus|Bread|Lettuce|Peas|Rice": "Light Spring Green Wrap",
		"Asparagus|Bread|Lettuce|Peas|Salmon": "Spring Salmon Fresh Sub",
		"Asparagus|Bread|Lettuce|Peas|Spinach": "Ultra Fresh Spring Sub",
		"Asparagus|Bread|Lettuce|Peas|Steak": "Spring Steak Fresh Sub",
		"Asparagus|Bread|Lettuce|Peas|Tofu": "Spring Vegan Fresh Sub",
		"Asparagus|Bread|Lettuce|Potato|Rice": "Spring Comfort Fresh Sub",
		"Asparagus|Bread|Lettuce|Potato|Salmon": "Hearty Spring Salmon Sub",
		"Asparagus|Bread|Lettuce|Potato|Spinach": "Power Spring Fresh Sub",
		"Asparagus|Bread|Lettuce|Potato|Steak": "Hearty Spring Steak Sub",
		"Asparagus|Bread|Lettuce|Potato|Tofu": "Hearty Spring Vegan Sub",
		"Asparagus|Bread|Lettuce|Rice|Salmon": "Light Spring Salmon Wrap",
		"Asparagus|Bread|Lettuce|Rice|Spinach": "Power Spring Light Wrap",
		"Asparagus|Bread|Lettuce|Rice|Steak": "Light Spring Steak Wrap",
		"Asparagus|Bread|Lettuce|Rice|Tofu": "Light Spring Vegan Wrap",
		"Asparagus|Bread|Lettuce|Salmon|Spinach": "Premium Spring Fresh Sub",
		"Asparagus|Bread|Lettuce|Salmon|Steak": "Spring Surf Fresh Deluxe",
		"Asparagus|Bread|Lettuce|Salmon|Tofu": "Spring Omega Fresh Sub",
		"Asparagus|Bread|Lettuce|Spinach|Steak": "Power Spring Fresh Meat",
		"Asparagus|Bread|Lettuce|Spinach|Tofu": "Power Spring Fresh Vegan",
		"Asparagus|Bread|Lettuce|Steak|Tofu": "Spring Fresh Protein Mix",
		"Asparagus|Bread|Peas|Potato|Rice": "Hearty Spring Green Sub",
		"Asparagus|Bread|Peas|Potato|Salmon": "Spring Salmon Green Comfort",
		"Asparagus|Bread|Peas|Potato|Spinach": "Power Spring Green Comfort",
		"Asparagus|Bread|Peas|Potato|Steak": "Spring Steak Green Comfort",
		"Asparagus|Bread|Peas|Potato|Tofu": "Spring Vegan Green Comfort",
		"Asparagus|Bread|Peas|Rice|Salmon": "Spring Salmon Green Wrap",
		"Asparagus|Bread|Peas|Rice|Spinach": "Power Spring Green Wrap",
		"Asparagus|Bread|Peas|Rice|Steak": "Spring Steak Green Wrap",
		"Asparagus|Bread|Peas|Rice|Tofu": "Spring Vegan Green Wrap",
		"Asparagus|Bread|Peas|Salmon|Spinach": "Premium Spring Green Sub",
		"Asparagus|Bread|Peas|Salmon|Steak": "Spring Surf Green Deluxe",
		"Asparagus|Bread|Peas|Salmon|Tofu": "Spring Omega Green Sub",
		"Asparagus|Bread|Peas|Spinach|Steak": "Power Spring Green Meat",
		"Asparagus|Bread|Peas|Spinach|Tofu": "Power Spring Green Vegan",
		"Asparagus|Bread|Peas|Steak|Tofu": "Spring Green Protein Mix",
		"Asparagus|Bread|Potato|Rice|Salmon": "Hearty Spring Salmon Wrap",
		"Asparagus|Bread|Potato|Rice|Spinach": "Power Spring Comfort Wrap",
		"Asparagus|Bread|Potato|Rice|Steak": "Hearty Spring Steak Wrap",
		"Asparagus|Bread|Potato|Rice|Tofu": "Hearty Spring Vegan Wrap",
		"Asparagus|Bread|Potato|Salmon|Spinach": "Premium Spring Comfort Sub",
		"Asparagus|Bread|Potato|Salmon|Steak": "Spring Surf Comfort Deluxe",
		"Asparagus|Bread|Potato|Salmon|Tofu": "Spring Omega Comfort Sub",
		"Asparagus|Bread|Potato|Spinach|Steak": "Power Spring Comfort Meat",
		"Asparagus|Bread|Potato|Spinach|Tofu": "Power Spring Comfort Vegan",
		"Asparagus|Bread|Potato|Steak|Tofu": "Spring Comfort Protein Mix",
		"Asparagus|Bread|Rice|Salmon|Spinach": "Premium Spring Grain Sub",
		"Asparagus|Bread|Rice|Salmon|Steak": "Spring Surf Grain Deluxe",
		"Asparagus|Bread|Rice|Salmon|Tofu": "Spring Omega Grain Sub",
		"Asparagus|Bread|Rice|Spinach|Steak": "Power Spring Grain Meat",
		"Asparagus|Bread|Rice|Spinach|Tofu": "Power Spring Grain Vegan",
		"Asparagus|Bread|Rice|Steak|Tofu": "Spring Grain Protein Mix",
		"Asparagus|Bread|Salmon|Spinach|Steak": "Ultimate Spring Protein Sub",
		"Asparagus|Bread|Salmon|Spinach|Tofu": "Premium Spring Omega Sub",
		"Asparagus|Bread|Salmon|Steak|Tofu": "Spring Triple Surf Sub",
		"Asparagus|Bread|Spinach|Steak|Tofu": "Ultimate Spring Power Sub",
		"Asparagus|Broccoli|Carrot|Chicken Breast|Lettuce": "Spring Garden Chicken Bowl",
		"Asparagus|Broccoli|Carrot|Chicken Breast|Peas": "Green Spring Chicken Mix",
		"Asparagus|Broccoli|Carrot|Chicken Breast|Potato": "Hearty Spring Chicken Bowl",
		"Asparagus|Broccoli|Carrot|Chicken Breast|Rice": "Spring Chicken Harvest",
		"Asparagus|Broccoli|Carrot|Chicken Breast|Salmon": "Spring Surf Garden Bowl",
		"Asparagus|Broccoli|Carrot|Chicken Breast|Spinach": "Power Spring Garden Chicken",
		"Asparagus|Broccoli|Carrot|Chicken Breast|Steak": "Spring Meat Garden Bowl",
		"Asparagus|Broccoli|Carrot|Chicken Breast|Tofu": "Spring Protein Garden Bowl",
		"Asparagus|Broccoli|Carrot|Lettuce|Peas": "Ultra Spring Greens Bowl",
		"Asparagus|Broccoli|Carrot|Lettuce|Potato": "Fresh Spring Harvest Bowl",
		"Asparagus|Broccoli|Carrot|Lettuce|Rice": "Light Spring Garden Bowl",
		"Asparagus|Broccoli|Carrot|Lettuce|Salmon": "Spring Salmon Garden Mix",
		"Asparagus|Broccoli|Carrot|Lettuce|Spinach": "Ultra Green Spring Bowl",
		"Asparagus|Broccoli|Carrot|Lettuce|Steak": "Spring Steak Garden Mix",
		"Asparagus|Broccoli|Carrot|Lettuce|Tofu": "Spring Vegan Garden Mix",
		"Asparagus|Broccoli|Carrot|Peas|Potato": "Hearty Spring Veggie Bowl",
		"Asparagus|Broccoli|Carrot|Peas|Rice": "Spring Veggie Grain Bowl",
		"Asparagus|Broccoli|Carrot|Peas|Salmon": "Spring Salmon Veggie Mix",
		"Asparagus|Broccoli|Carrot|Peas|Spinach": "Power Spring Veggie Bowl",
		"Asparagus|Broccoli|Carrot|Peas|Steak": "Spring Steak Veggie Mix",
		"Asparagus|Broccoli|Carrot|Peas|Tofu": "Spring Vegan Veggie Mix",
		"Asparagus|Broccoli|Carrot|Potato|Rice": "Spring Root Grain Bowl",
		"Asparagus|Broccoli|Carrot|Potato|Salmon": "Hearty Spring Salmon Bowl",
		"Asparagus|Broccoli|Carrot|Potato|Spinach": "Power Spring Root Bowl",
		"Asparagus|Broccoli|Carrot|Potato|Steak": "Hearty Spring Steak Bowl",
		"Asparagus|Broccoli|Carrot|Potato|Tofu": "Hearty Spring Vegan Bowl",
		"Asparagus|Broccoli|Carrot|Rice|Salmon": "Spring Salmon Grain Mix",
		"Asparagus|Broccoli|Carrot|Rice|Spinach": "Power Spring Grain Bowl",
		"Asparagus|Broccoli|Carrot|Rice|Steak": "Spring Steak Grain Mix",
		"Asparagus|Broccoli|Carrot|Rice|Tofu": "Spring Vegan Grain Mix",
		"Asparagus|Broccoli|Carrot|Salmon|Spinach": "Premium Spring Garden Bowl",
		"Asparagus|Broccoli|Carrot|Salmon|Steak": "Spring Surf Garden Deluxe",
		"Asparagus|Broccoli|Carrot|Salmon|Tofu": "Spring Omega Garden Bowl",
		"Asparagus|Broccoli|Carrot|Spinach|Steak": "Power Spring Garden Mix",
		"Asparagus|Broccoli|Carrot|Spinach|Tofu": "Power Spring Garden Vegan",
		"Asparagus|Broccoli|Carrot|Steak|Tofu": "Spring Garden Protein Bowl",
		"Asparagus|Broccoli|Chicken Breast|Lettuce|Peas": "Fresh Spring Protein Bowl",
		"Asparagus|Broccoli|Chicken Breast|Lettuce|Potato": "Classic Spring Chicken Bowl",
		"Asparagus|Broccoli|Chicken Breast|Lettuce|Rice": "Light Spring Chicken Mix",
		"Asparagus|Broccoli|Chicken Breast|Lettuce|Salmon": "Spring Surf Chicken Bowl",
		"Asparagus|Broccoli|Chicken Breast|Lettuce|Spinach": "Power Spring Fresh Chicken",
		"Asparagus|Broccoli|Chicken Breast|Lettuce|Steak": "Spring Double Meat Bowl",
		"Asparagus|Broccoli|Chicken Breast|Lettuce|Tofu": "Spring Protein Fresh Bowl",
		"Asparagus|Broccoli|Chicken Breast|Peas|Potato": "Hearty Spring Green Chicken",
		"Asparagus|Broccoli|Chicken Breast|Peas|Rice": "Spring Green Chicken Rice",
		"Asparagus|Broccoli|Chicken Breast|Peas|Salmon": "Spring Surf Green Chicken",
		"Asparagus|Broccoli|Chicken Breast|Peas|Spinach": "Power Spring Green Protein",
		"Asparagus|Broccoli|Chicken Breast|Peas|Steak": "Spring Meat Green Bowl",
		"Asparagus|Broccoli|Chicken Breast|Peas|Tofu": "Spring Protein Green Bowl",
		"Asparagus|Broccoli|Chicken Breast|Potato|Rice": "Hearty Spring Chicken Grain",
		"Asparagus|Broccoli|Chicken Breast|Potato|Salmon": "Spring Surf Comfort Chicken",
		"Asparagus|Broccoli|Chicken Breast|Potato|Spinach": "Power Spring Hearty Chicken",
		"Asparagus|Broccoli|Chicken Breast|Potato|Steak": "Spring Meat Comfort Bowl",
		"Asparagus|Broccoli|Chicken Breast|Potato|Tofu": "Spring Protein Comfort Bowl",
		"Asparagus|Broccoli|Chicken Breast|Rice|Salmon": "Spring Surf Chicken Grain",
		"Asparagus|Broccoli|Chicken Breast|Rice|Spinach": "Power Spring Chicken Rice",
		"Asparagus|Broccoli|Chicken Breast|Rice|Steak": "Spring Meat Chicken Grain",
		"Asparagus|Broccoli|Chicken Breast|Rice|Tofu": "Spring Protein Chicken Rice",
		"Asparagus|Broccoli|Chicken Breast|Salmon|Spinach": "Premium Spring Surf Bowl",
		"Asparagus|Broccoli|Chicken Breast|Salmon|Steak": "Ultimate Spring Meat Bowl",
		"Asparagus|Broccoli|Chicken Breast|Salmon|Tofu": "Spring Omega Protein Bowl",
		"Asparagus|Broccoli|Chicken Breast|Spinach|Steak": "Power Spring Double Meat",
		"Asparagus|Broccoli|Chicken Breast|Spinach|Tofu": "Power Spring Protein Bowl",
		"Asparagus|Broccoli|Chicken Breast|Steak|Tofu": "Spring Triple Protein Bowl",
		"Asparagus|Broccoli|Lettuce|Peas|Potato": "Fresh Spring Green Bowl",
		"Asparagus|Broccoli|Lettuce|Peas|Rice": "Light Spring Green Grain",
		"Asparagus|Broccoli|Lettuce|Peas|Salmon": "Spring Salmon Green Bowl",
		"Asparagus|Broccoli|Lettuce|Peas|Spinach": "Ultra Fresh Spring Greens",
		"Asparagus|Broccoli|Lettuce|Peas|Steak": "Spring Steak Green Bowl",
		"Asparagus|Broccoli|Lettuce|Peas|Tofu": "Spring Vegan Green Bowl",
		"Asparagus|Broccoli|Lettuce|Potato|Rice": "Spring Fresh Comfort Bowl",
		"Asparagus|Broccoli|Lettuce|Potato|Salmon": "Hearty Spring Salmon Mix",
		"Asparagus|Broccoli|Lettuce|Potato|Spinach": "Power Spring Fresh Bowl",
		"Asparagus|Broccoli|Lettuce|Potato|Steak": "Hearty Spring Steak Mix",
		"Asparagus|Broccoli|Lettuce|Potato|Tofu": "Hearty Spring Vegan Mix",
		"Asparagus|Broccoli|Lettuce|Rice|Salmon": "Light Spring Salmon Bowl",
		"Asparagus|Broccoli|Lettuce|Rice|Spinach": "Power Spring Light Bowl",
		"Asparagus|Broccoli|Lettuce|Rice|Steak": "Light Spring Steak Bowl",
		"Asparagus|Broccoli|Lettuce|Rice|Tofu": "Light Spring Vegan Bowl",
		"Asparagus|Broccoli|Lettuce|Salmon|Spinach": "Premium Spring Fresh Mix",
		"Asparagus|Broccoli|Lettuce|Salmon|Steak": "Spring Surf Fresh Bowl",
		"Asparagus|Broccoli|Lettuce|Salmon|Tofu": "Spring Omega Fresh Bowl",
		"Asparagus|Broccoli|Lettuce|Spinach|Steak": "Power Spring Fresh Mix",
		"Asparagus|Broccoli|Lettuce|Spinach|Tofu": "Power Spring Fresh Vegan",
		"Asparagus|Broccoli|Lettuce|Steak|Tofu": "Spring Fresh Protein Bowl",
		"Asparagus|Broccoli|Peas|Potato|Rice": "Hearty Spring Green Grain",
		"Asparagus|Broccoli|Peas|Potato|Salmon": "Spring Salmon Green Comfort",
		"Asparagus|Broccoli|Peas|Potato|Spinach": "Power Spring Green Hearty",
		"Asparagus|Broccoli|Peas|Potato|Steak": "Spring Steak Green Comfort",
		"Asparagus|Broccoli|Peas|Potato|Tofu": "Spring Vegan Green Comfort",
		"Asparagus|Broccoli|Peas|Rice|Salmon": "Spring Salmon Green Grain",
		"Asparagus|Broccoli|Peas|Rice|Spinach": "Power Spring Green Rice",
		"Asparagus|Broccoli|Peas|Rice|Steak": "Spring Steak Green Grain",
		"Asparagus|Broccoli|Peas|Rice|Tofu": "Spring Vegan Green Grain",
		"Asparagus|Broccoli|Peas|Salmon|Spinach": "Premium Spring Green Bowl",
		"Asparagus|Broccoli|Peas|Salmon|Steak": "Spring Surf Green Bowl",
		"Asparagus|Broccoli|Peas|Salmon|Tofu": "Spring Omega Green Bowl",
		"Asparagus|Broccoli|Peas|Spinach|Steak": "Power Spring Green Meat",
		"Asparagus|Broccoli|Peas|Spinach|Tofu": "Power Spring Green Vegan",
		"Asparagus|Broccoli|Peas|Steak|Tofu": "Spring Green Protein Bowl",
		"Asparagus|Broccoli|Potato|Rice|Salmon": "Hearty Spring Salmon Grain",
		"Asparagus|Broccoli|Potato|Rice|Spinach": "Power Spring Comfort Grain",
		"Asparagus|Broccoli|Potato|Rice|Steak": "Hearty Spring Steak Grain",
		"Asparagus|Broccoli|Potato|Rice|Tofu": "Hearty Spring Vegan Grain",
		"Asparagus|Broccoli|Potato|Salmon|Spinach": "Premium Spring Comfort Bowl",
		"Asparagus|Broccoli|Potato|Salmon|Steak": "Spring Surf Comfort Bowl",
		"Asparagus|Broccoli|Potato|Salmon|Tofu": "Spring Omega Comfort Bowl",
		"Asparagus|Broccoli|Potato|Spinach|Steak": "Power Spring Hearty Meat",
		"Asparagus|Broccoli|Potato|Spinach|Tofu": "Power Spring Hearty Vegan",
		"Asparagus|Broccoli|Potato|Steak|Tofu": "Spring Comfort Protein Bowl",
		"Asparagus|Broccoli|Rice|Salmon|Spinach": "Premium Spring Grain Bowl",
		"Asparagus|Broccoli|Rice|Salmon|Steak": "Spring Surf Grain Bowl",
		"Asparagus|Broccoli|Rice|Salmon|Tofu": "Spring Omega Grain Bowl",
		"Asparagus|Broccoli|Rice|Spinach|Steak": "Power Spring Grain Meat",
		"Asparagus|Broccoli|Rice|Spinach|Tofu": "Power Spring Grain Vegan",
		"Asparagus|Broccoli|Rice|Steak|Tofu": "Spring Grain Protein Bowl",
		"Asparagus|Broccoli|Salmon|Spinach|Steak": "Ultimate Spring Protein Mix",
		"Asparagus|Broccoli|Salmon|Spinach|Tofu": "Premium Spring Omega Bowl",
		"Asparagus|Broccoli|Salmon|Steak|Tofu": "Spring Triple Protein Mix",
		"Asparagus|Broccoli|Spinach|Steak|Tofu": "Ultimate Spring Power Bowl",
		"Asparagus|Carrot|Chicken Breast|Lettuce|Peas": "Fresh Garden Spring Chicken",
		"Asparagus|Carrot|Chicken Breast|Lettuce|Potato": "Classic Garden Chicken Bowl",
		"Asparagus|Carrot|Chicken Breast|Lettuce|Rice": "Light Garden Chicken Mix",
		"Asparagus|Carrot|Chicken Breast|Lettuce|Salmon": "Garden Surf Chicken Bowl",
		"Asparagus|Carrot|Chicken Breast|Lettuce|Spinach": "Power Garden Fresh Chicken",
		"Asparagus|Carrot|Chicken Breast|Lettuce|Steak": "Garden Double Meat Bowl",
		"Asparagus|Carrot|Chicken Breast|Lettuce|Tofu": "Garden Protein Fresh Bowl",
		"Asparagus|Carrot|Chicken Breast|Peas|Potato": "Hearty Garden Chicken Mix",
		"Asparagus|Carrot|Chicken Breast|Peas|Rice": "Garden Chicken Green Rice",
		"Asparagus|Carrot|Chicken Breast|Peas|Salmon": "Garden Surf Green Chicken",
		"Asparagus|Carrot|Chicken Breast|Peas|Spinach": "Surf & Garden Bowl",
		"Asparagus|Carrot|Chicken Breast|Peas|Steak": "Garden Meat Green Bowl",
		"Asparagus|Carrot|Chicken Breast|Peas|Tofu": "Garden Protein Green Bowl",
		"Asparagus|Carrot|Chicken Breast|Potato|Rice": "Hearty Garden Chicken Grain",
		"Asparagus|Carrot|Chicken Breast|Potato|Salmon": "Garden Surf Comfort Bowl",
		"Asparagus|Carrot|Chicken Breast|Potato|Spinach": "Power Garden Hearty Chicken",
		"Asparagus|Carrot|Chicken Breast|Potato|Steak": "Garden Meat Comfort Bowl",
		"Asparagus|Carrot|Chicken Breast|Potato|Tofu": "Garden Protein Comfort Bowl",
		"Asparagus|Carrot|Chicken Breast|Rice|Salmon": "Garden Surf Chicken Grain",
		"Asparagus|Carrot|Chicken Breast|Rice|Spinach": "Power Garden Chicken Rice",
		"Asparagus|Carrot|Chicken Breast|Rice|Steak": "Garden Meat Chicken Grain",
		"Asparagus|Carrot|Chicken Breast|Rice|Tofu": "Garden Protein Chicken Rice",
		"Asparagus|Carrot|Chicken Breast|Salmon|Spinach": "Premium Garden Surf Bowl",
		"Asparagus|Carrot|Chicken Breast|Salmon|Steak": "Ultimate Garden Meat Bowl",
		"Asparagus|Carrot|Chicken Breast|Salmon|Tofu": "Garden Omega Protein Bowl",
		"Asparagus|Carrot|Chicken Breast|Spinach|Steak": "Power Garden Double Meat",
		"Asparagus|Carrot|Chicken Breast|Spinach|Tofu": "Power Garden Protein Bowl",
		"Asparagus|Carrot|Chicken Breast|Steak|Tofu": "Garden Triple Protein Bowl",
		"Asparagus|Carrot|Lettuce|Peas|Potato": "Fresh Garden Spring Mix",
		"Asparagus|Carrot|Lettuce|Peas|Rice": "Light Garden Spring Grain",
		"Asparagus|Carrot|Lettuce|Peas|Salmon": "Garden Salmon Fresh Bowl",
		"Asparagus|Carrot|Lettuce|Peas|Spinach": "Ultra Fresh Garden Bowl",
		"Asparagus|Carrot|Lettuce|Peas|Steak": "Garden Steak Fresh Bowl",
		"Asparagus|Carrot|Lettuce|Peas|Tofu": "Garden Vegan Fresh Bowl",
		"Asparagus|Carrot|Lettuce|Potato|Rice": "Garden Fresh Comfort Bowl",
		"Asparagus|Carrot|Lettuce|Potato|Salmon": "Hearty Garden Salmon Mix",
		"Asparagus|Carrot|Lettuce|Potato|Spinach": "Power Garden Fresh Bowl",
		"Asparagus|Carrot|Lettuce|Potato|Steak": "Hearty Garden Steak Mix",
		"Asparagus|Carrot|Lettuce|Potato|Tofu": "Hearty Garden Vegan Mix",
		"Asparagus|Carrot|Lettuce|Rice|Salmon": "Light Garden Salmon Bowl",
		"Asparagus|Carrot|Lettuce|Rice|Spinach": "Power Garden Light Bowl",
		"Asparagus|Carrot|Lettuce|Rice|Steak": "Light Garden Steak Bowl",
		"Asparagus|Carrot|Lettuce|Rice|Tofu": "Light Garden Vegan Bowl",
		"Asparagus|Carrot|Lettuce|Salmon|Spinach": "Premium Garden Fresh Mix",
		"Asparagus|Carrot|Lettuce|Salmon|Steak": "Garden Surf Fresh Bowl",
		"Asparagus|Carrot|Lettuce|Salmon|Tofu": "Garden Omega Fresh Bowl",
		"Asparagus|Carrot|Lettuce|Spinach|Steak": "Power Garden Fresh Mix",
		"Asparagus|Carrot|Lettuce|Spinach|Tofu": "Power Garden Fresh Vegan",
		"Asparagus|Carrot|Lettuce|Steak|Tofu": "Garden Fresh Protein Bowl",
		"Asparagus|Carrot|Peas|Potato|Rice": "Hearty Garden Veggie Grain",
		"Asparagus|Carrot|Peas|Potato|Salmon": "Garden Salmon Green Comfort",
		"Asparagus|Carrot|Peas|Potato|Spinach": "Power Garden Green Hearty",
		"Asparagus|Carrot|Peas|Potato|Steak": "Garden Steak Green Comfort",
		"Asparagus|Carrot|Peas|Potato|Tofu": "Garden Vegan Green Comfort",
		"Asparagus|Carrot|Peas|Rice|Salmon": "Garden Salmon Green Grain",
		"Asparagus|Carrot|Peas|Rice|Spinach": "Power Garden Green Rice",
		"Asparagus|Carrot|Peas|Rice|Steak": "Garden Steak Green Grain",
		"Asparagus|Carrot|Peas|Rice|Tofu": "Garden Vegan Green Grain",
		"Asparagus|Carrot|Peas|Salmon|Spinach": "Premium Garden Green Bowl",
		"Asparagus|Carrot|Peas|Salmon|Steak": "Garden Surf Green Bowl",
		"Asparagus|Carrot|Peas|Salmon|Tofu": "Garden Omega Green Bowl",
		"Asparagus|Carrot|Peas|Spinach|Steak": "Power Garden Green Meat",
		"Asparagus|Carrot|Peas|Spinach|Tofu": "Power Garden Green Vegan",
		"Asparagus|Carrot|Peas|Steak|Tofu": "Garden Green Protein Bowl",
		"Asparagus|Carrot|Potato|Rice|Salmon": "Hearty Garden Salmon Grain",
		"Asparagus|Carrot|Potato|Rice|Spinach": "Power Garden Comfort Grain",
		"Asparagus|Carrot|Potato|Rice|Steak": "Hearty Garden Steak Grain",
		"Asparagus|Carrot|Potato|Rice|Tofu": "Hearty Garden Vegan Grain",
		"Asparagus|Carrot|Potato|Salmon|Spinach": "Premium Garden Comfort Bowl",
		"Asparagus|Carrot|Potato|Salmon|Steak": "Garden Surf Comfort Bowl",
		"Asparagus|Carrot|Potato|Salmon|Tofu": "Garden Omega Comfort Bowl",
		"Asparagus|Carrot|Potato|Spinach|Steak": "Power Garden Hearty Meat",
		"Asparagus|Carrot|Potato|Spinach|Tofu": "Power Garden Hearty Vegan",
		"Asparagus|Carrot|Potato|Steak|Tofu": "Garden Comfort Protein Bowl",
		"Asparagus|Carrot|Rice|Salmon|Spinach": "Premium Garden Grain Bowl",
		"Asparagus|Carrot|Rice|Salmon|Steak": "Garden Surf Grain Bowl",
		"Asparagus|Carrot|Rice|Salmon|Tofu": "Garden Omega Grain Bowl",
		"Asparagus|Carrot|Rice|Spinach|Steak": "Power Garden Grain Meat",
		"Asparagus|Carrot|Rice|Spinach|Tofu": "Power Garden Grain Vegan",
		"Asparagus|Carrot|Rice|Steak|Tofu": "Garden Grain Protein Bowl",
		"Asparagus|Carrot|Salmon|Spinach|Steak": "Ultimate Garden Protein Mix",
		"Asparagus|Carrot|Salmon|Spinach|Tofu": "Premium Garden Omega Bowl",
		"Asparagus|Carrot|Salmon|Steak|Tofu": "Garden Triple Protein Mix",
		"Asparagus|Carrot|Spinach|Steak|Tofu": "Ultimate Garden Power Bowl",
		"Asparagus|Chicken Breast|Lettuce|Peas|Potato": "Fresh Spring Protein Bowl",
		"Asparagus|Chicken Breast|Lettuce|Peas|Rice": "Light Spring Protein Grain",
		"Asparagus|Chicken Breast|Lettuce|Peas|Salmon": "Spring Surf Fresh Protein",
		"Asparagus|Chicken Breast|Lettuce|Peas|Spinach": "Ultra Fresh Spring Protein",
		"Asparagus|Chicken Breast|Lettuce|Peas|Steak": "Spring Meat Fresh Bowl",
		"Asparagus|Chicken Breast|Lettuce|Peas|Tofu": "Spring Vegan Fresh Protein",
		"Asparagus|Chicken Breast|Lettuce|Potato|Rice": "Classic Spring Protein Bowl",
		"Asparagus|Chicken Breast|Lettuce|Potato|Salmon": "Hearty Spring Surf Bowl",
		"Asparagus|Chicken Breast|Lettuce|Potato|Spinach": "Power Spring Fresh Protein",
		"Asparagus|Chicken Breast|Lettuce|Potato|Steak": "Hearty Spring Meat Bowl",
		"Asparagus|Chicken Breast|Lettuce|Potato|Tofu": "Hearty Spring Protein Bowl",
		"Asparagus|Chicken Breast|Lettuce|Rice|Salmon": "Light Spring Surf Bowl",
		"Asparagus|Chicken Breast|Lettuce|Rice|Spinach": "Power Spring Light Protein",
		"Asparagus|Chicken Breast|Lettuce|Rice|Steak": "Light Spring Meat Bowl",
		"Asparagus|Chicken Breast|Lettuce|Rice|Tofu": "Light Spring Protein Bowl",
		"Asparagus|Chicken Breast|Lettuce|Salmon|Spinach": "Premium Spring Surf Mix",
		"Asparagus|Chicken Breast|Lettuce|Salmon|Steak": "Ultimate Spring Meat Bowl",
		"Asparagus|Chicken Breast|Lettuce|Salmon|Tofu": "Spring Omega Fresh Protein",
		"Asparagus|Chicken Breast|Lettuce|Spinach|Steak": "Power Spring Fresh Meat",
		"Asparagus|Chicken Breast|Lettuce|Spinach|Tofu": "Power Spring Fresh Protein",
		"Asparagus|Chicken Breast|Lettuce|Steak|Tofu": "Spring Fresh Triple Protein",
		"Asparagus|Chicken Breast|Peas|Potato|Rice": "Hearty Spring Green Protein",
		"Asparagus|Chicken Breast|Peas|Potato|Salmon": "Spring Surf Green Comfort",
		"Asparagus|Chicken Breast|Peas|Potato|Spinach": "Power Spring Green Hearty",
		"Asparagus|Chicken Breast|Peas|Potato|Steak": "Spring Meat Green Comfort",
		"Asparagus|Chicken Breast|Peas|Potato|Tofu": "Spring Protein Green Comfort",
		"Asparagus|Chicken Breast|Peas|Rice|Salmon": "Spring Surf Green Rice",
		"Asparagus|Chicken Breast|Peas|Rice|Spinach": "Power Spring Green Protein",
		"Asparagus|Chicken Breast|Peas|Rice|Steak": "Spring Meat Green Rice",
		"Asparagus|Chicken Breast|Peas|Rice|Tofu": "Spring Protein Green Rice",
		"Asparagus|Chicken Breast|Peas|Salmon|Spinach": "Premium Spring Green Surf",
		"Asparagus|Chicken Breast|Peas|Salmon|Steak": "Ultimate Spring Green Meat",
		"Asparagus|Chicken Breast|Peas|Salmon|Tofu": "Spring Omega Green Protein",
		"Asparagus|Chicken Breast|Peas|Spinach|Steak": "Power Spring Green Meat Mix",
		"Asparagus|Chicken Breast|Peas|Spinach|Tofu": "Power Spring Green Protein Mix",
		"Asparagus|Chicken Breast|Peas|Steak|Tofu": "Spring Green Triple Protein",
		"Asparagus|Chicken Breast|Potato|Rice|Salmon": "Hearty Spring Surf Grain",
		"Asparagus|Chicken Breast|Potato|Rice|Spinach": "Power Spring Comfort Protein",
		"Asparagus|Chicken Breast|Potato|Rice|Steak": "Hearty Spring Meat Grain",
		"Asparagus|Chicken Breast|Potato|Rice|Tofu": "Hearty Spring Protein Grain",
		"Asparagus|Chicken Breast|Potato|Salmon|Spinach": "Premium Spring Surf Comfort",
		"Asparagus|Chicken Breast|Potato|Salmon|Steak": "Ultimate Spring Comfort Meat",
		"Asparagus|Chicken Breast|Potato|Salmon|Tofu": "Spring Omega Comfort Protein",
		"Asparagus|Chicken Breast|Potato|Spinach|Steak": "Power Spring Hearty Meat Mix",
		"Asparagus|Chicken Breast|Potato|Spinach|Tofu": "Power Spring Hearty Protein",
		"Asparagus|Chicken Breast|Potato|Steak|Tofu": "Spring Comfort Triple Protein",
		"Asparagus|Chicken Breast|Rice|Salmon|Spinach": "Premium Spring Surf Grain",
		"Asparagus|Chicken Breast|Rice|Salmon|Steak": "Ultimate Spring Grain Meat",
		"Asparagus|Chicken Breast|Rice|Salmon|Tofu": "Spring Omega Grain Protein",
		"Asparagus|Chicken Breast|Rice|Spinach|Steak": "Power Spring Grain Meat Mix",
		"Asparagus|Chicken Breast|Rice|Spinach|Tofu": "Power Spring Grain Protein",
		"Asparagus|Chicken Breast|Rice|Steak|Tofu": "Spring Grain Triple Protein",
		"Asparagus|Chicken Breast|Salmon|Spinach|Steak": "Ultimate Spring Protein Feast",
		"Asparagus|Chicken Breast|Salmon|Spinach|Tofu": "Premium Spring Omega Protein",
		"Asparagus|Chicken Breast|Salmon|Steak|Tofu": "Spring Quad Protein Bowl",
		"Asparagus|Chicken Breast|Spinach|Steak|Tofu": "Ultimate Spring Power Protein",
		"Asparagus|Lettuce|Peas|Potato|Rice": "Fresh Spring Veggie Bowl",
		"Asparagus|Lettuce|Peas|Potato|Salmon": "Spring Salmon Fresh Comfort",
		"Asparagus|Lettuce|Peas|Potato|Spinach": "Power Spring Fresh Hearty",
		"Asparagus|Lettuce|Peas|Potato|Steak": "Spring Steak Fresh Comfort",
		"Asparagus|Lettuce|Peas|Potato|Tofu": "Spring Vegan Fresh Comfort",
		"Asparagus|Lettuce|Peas|Rice|Salmon": "Spring Salmon Light Green",
		"Asparagus|Lettuce|Peas|Rice|Spinach": "Power Spring Light Green",
		"Asparagus|Lettuce|Peas|Rice|Steak": "Spring Steak Light Green",
		"Asparagus|Lettuce|Peas|Rice|Tofu": "Spring Vegan Light Green",
		"Asparagus|Lettuce|Peas|Salmon|Spinach": "Premium Spring Fresh Green",
		
		# ===== 6 INGREDIENTS =====
		# (Massive number of combinations - providing key examples)
		
		# 6 Ingredients - Key examples  
		"Broccoli|Carrot|Chicken Breast|Peas|Potato|Rice": "Chef's Special Bowl",
		"Asparagus|Broccoli|Carrot|Chicken Breast|Peas|Rice": "Premium Chicken Feast",
		"Broccoli|Carrot|Peas|Potato|Spinach|Tofu": "Vegan Delight",
		"Chicken Breast|Lettuce|Peas|Rice|Salmon|Spinach": "Ocean Garden Bowl",
		"Bread|Broccoli|Chicken Breast|Salmon|Steak|Tofu": "Protein Paradise Sandwich",
		"Carrot|Lettuce|Potato|Rice|Salmon|Steak": "Deluxe Meat & Veggie Bowl",
		
		# ===== 7 INGREDIENTS =====
		# (Near-ultimate recipes)
		
		# 7 Ingredients
		"Asparagus|Broccoli|Carrot|Chicken Breast|Peas|Potato|Rice": "Kitchen Sink Bowl",
		"Broccoli|Carrot|Chicken Breast|Lettuce|Peas|Spinach|Tofu": "Everything Protein Bowl",
		"Bread|Carrot|Chicken Breast|Potato|Salmon|Spinach|Steak": "Grand Feast Sandwich",
		"Broccoli|Lettuce|Peas|Rice|Salmon|Steak|Tofu": "Ultimate Power Bowl",
		
		# ===== 8 INGREDIENTS =====
		# (The absolute maximum - ultimate recipes)
		
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
## Recipes are classified by INGREDIENT COUNT, not tier
## Tiers control PROGRESSION (when you can access certain ingredient counts)
## Water = sum, Heat Resistance = average
## Volatility = average for 2 ingredients, SUM for 3+ (more ingredients = more chaos!)
## Returns null if the combination is not allowed based on current tier progression
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
	
	# PROGRESSION GATES: Check if this ingredient count is allowed based on current progression tier
	# (Tiers control WHEN you can create recipes of certain ingredient counts)
	if current_tier < 2 and total_base_ingredients > TIER_1_MAX_INGREDIENTS:
		print("[RecipesData] ❌ BLOCKED: %d-ingredient recipe requires Tier 2 progression! (Current: Tier %d)" % [total_base_ingredients, current_tier])
		print("[RecipesData] ❌ Need Tier 2 to create 3-4 ingredient recipes!")
		return null
	
	if current_tier < 3 and total_base_ingredients > TIER_2_MAX_INGREDIENTS:
		print("[RecipesData] ❌ BLOCKED: %d-ingredient recipe requires Tier 3 progression! (Current: Tier %d)" % [total_base_ingredients, current_tier])
		print("[RecipesData] ❌ Need Tier 3 to create 5-6 ingredient recipes!")
		return null
	
	if current_tier < 4 and total_base_ingredients > TIER_3_MAX_INGREDIENTS:
		print("[RecipesData] ❌ BLOCKED: %d-ingredient recipe requires Tier 4 progression! (Current: Tier %d)" % [total_base_ingredients, current_tier])
		print("[RecipesData] ❌ Need Tier 4 to create 7-8 ingredient recipes!")
		return null
	
	if current_tier < 5 and total_base_ingredients > TIER_4_MAX_INGREDIENTS:
		print("[RecipesData] ❌ BLOCKED: %d-ingredient recipe requires Tier 5 progression! (Current: Tier %d)" % [total_base_ingredients, current_tier])
		print("[RecipesData] ❌ Need Tier 5 to create 9-ingredient recipes!")
		return null
	
	if current_tier < 6 and total_base_ingredients > TIER_5_MAX_INGREDIENTS:
		print("[RecipesData] ❌ BLOCKED: %d-ingredient recipe requires Tier 6 progression! (Current: Tier %d)" % [total_base_ingredients, current_tier])
		print("[RecipesData] ❌ Need Tier 6 to create 10-ingredient recipes!")
		return null
	
	if current_tier < 7 and total_base_ingredients > TIER_6_MAX_INGREDIENTS:
		print("[RecipesData] ❌ BLOCKED: %d-ingredient recipe requires Tier 7 progression! (Current: Tier %d)" % [total_base_ingredients, current_tier])
		print("[RecipesData] ❌ Need Tier 7 to create 11-ingredient recipes!")
		return null
	
	if current_tier < 8 and total_base_ingredients > TIER_7_MAX_INGREDIENTS:
		print("[RecipesData] ❌ BLOCKED: %d-ingredient recipe requires Tier 8 progression! (Current: Tier %d)" % [total_base_ingredients, current_tier])
		print("[RecipesData] ❌ Need Tier 8 to create 12-13 ingredient recipes!")
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
	if total_recipes >= TIER_8_UNLOCK_THRESHOLD:
		return 8
	elif total_recipes >= TIER_7_UNLOCK_THRESHOLD:
		return 7
	elif total_recipes >= TIER_6_UNLOCK_THRESHOLD:
		return 6
	elif total_recipes >= TIER_5_UNLOCK_THRESHOLD:
		return 5
	elif total_recipes >= TIER_4_UNLOCK_THRESHOLD:
		return 4
	elif total_recipes >= TIER_3_UNLOCK_THRESHOLD:
		return 3
	elif total_recipes >= TIER_2_UNLOCK_THRESHOLD:
		return 2
	elif total_recipes >= TIER_1_UNLOCK_THRESHOLD:
		return 1
	else:
		return 0
