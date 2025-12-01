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
		"Asparagus|Chicken Breast|Lettuce|Salmon": "Spring Surf & Turf Salad",
		"Asparagus|Chicken Breast|Lettuce|Steak": "Spring Double Meat Salad",
		"Asparagus|Chicken Breast|Lettuce|Tofu": "Spring Protein Salad",
		"Asparagus|Chicken Breast|Peas|Salmon": "Spring Omega Chicken",
		"Asparagus|Chicken Breast|Peas|Steak": "Spring Power Chicken",
		"Asparagus|Chicken Breast|Peas|Tofu": "Spring Lean Protein",
		"Asparagus|Chicken Breast|Potato|Salmon": "Hearty Spring Protein",
		"Asparagus|Chicken Breast|Potato|Steak": "Hearty Spring Power",
		"Asparagus|Chicken Breast|Potato|Tofu": "Hearty Spring Balance",
		"Asparagus|Chicken Breast|Rice|Salmon": "Spring Omega Rice Bowl",
		"Asparagus|Chicken Breast|Rice|Steak": "Spring Power Rice Bowl",
		"Asparagus|Chicken Breast|Rice|Tofu": "Spring Protein Rice",
		"Asparagus|Chicken Breast|Salmon|Steak": "Spring Triple Meat",
		"Asparagus|Chicken Breast|Salmon|Tofu": "Spring Omega Fusion",
		"Asparagus|Chicken Breast|Steak|Tofu": "Spring Power Fusion",
		"Asparagus|Lettuce|Peas|Salmon": "Light Spring Omega",
		"Asparagus|Lettuce|Peas|Steak": "Light Spring Power",
		"Asparagus|Lettuce|Peas|Tofu": "Light Spring Vegan",
		"Asparagus|Lettuce|Potato|Salmon": "Fresh Spring Omega",
		"Asparagus|Lettuce|Potato|Steak": "Fresh Spring Steak",
		"Asparagus|Lettuce|Potato|Tofu": "Fresh Spring Vegan",
		"Asparagus|Lettuce|Rice|Salmon": "Spring Salmon Grain",
		"Asparagus|Lettuce|Rice|Steak": "Spring Steak Grain",
		"Asparagus|Lettuce|Rice|Tofu": "Spring Vegan Grain",
		"Asparagus|Lettuce|Salmon|Steak": "Spring Protein Salad",
		"Asparagus|Lettuce|Salmon|Tofu": "Spring Omega Salad",
		"Asparagus|Lettuce|Steak|Tofu": "Spring Power Salad",
		"Asparagus|Peas|Potato|Salmon": "Hearty Green Omega",
		"Asparagus|Peas|Potato|Steak": "Hearty Green Steak",
		"Asparagus|Peas|Potato|Tofu": "Hearty Green Vegan",
		"Asparagus|Peas|Rice|Salmon": "Spring Green Omega",
		"Asparagus|Peas|Rice|Steak": "Spring Green Steak",
		"Asparagus|Peas|Rice|Tofu": "Spring Green Vegan",
		"Asparagus|Peas|Salmon|Steak": "Green Spring Protein",
		"Asparagus|Peas|Salmon|Tofu": "Green Spring Omega",
		"Asparagus|Peas|Steak|Tofu": "Green Spring Power",
		"Asparagus|Potato|Rice|Salmon": "Spring Comfort Omega",
		"Asparagus|Potato|Rice|Steak": "Spring Comfort Steak",
		"Asparagus|Potato|Rice|Tofu": "Spring Comfort Vegan",
		"Asparagus|Potato|Salmon|Steak": "Hearty Spring Protein",
		"Asparagus|Potato|Salmon|Tofu": "Hearty Spring Omega",
		"Asparagus|Potato|Steak|Tofu": "Hearty Spring Power",
		"Asparagus|Rice|Salmon|Steak": "Spring Protein Grain",
		"Asparagus|Rice|Salmon|Tofu": "Spring Omega Fusion",
		"Asparagus|Rice|Steak|Tofu": "Spring Power Fusion",
		"Asparagus|Salmon|Spinach|Steak": "Premium Spring Protein",
		"Asparagus|Salmon|Spinach|Tofu": "Premium Spring Omega",
		"Asparagus|Steak|Spinach|Tofu": "Premium Spring Power",
		"Bread|Broccoli|Carrot|Chicken Breast": "Garden Chicken Club",
		"Bread|Broccoli|Carrot|Lettuce": "Ultimate Veggie Sandwich",
		"Bread|Broccoli|Carrot|Peas": "Green Garden Sub",
		"Bread|Broccoli|Carrot|Potato": "Roasted Garden Sandwich",
		"Bread|Broccoli|Carrot|Rice": "Veggie Grain Sub",
		"Bread|Broccoli|Carrot|Salmon": "Salmon Garden Sandwich",
		"Bread|Broccoli|Carrot|Steak": "Steak Garden Sub",
		"Bread|Broccoli|Carrot|Tofu": "Tofu Garden Sandwich",
		"Bread|Broccoli|Chicken Breast|Lettuce": "Fresh Chicken Green Sub",
		"Bread|Broccoli|Chicken Breast|Peas": "Green Protein Sandwich",
		"Bread|Broccoli|Chicken Breast|Potato": "Hearty Green Chicken Sub",
		"Bread|Broccoli|Chicken Breast|Rice": "Chicken Green Rice Wrap",
		"Bread|Broccoli|Chicken Breast|Salmon": "Surf & Turf Green Sub",
		"Bread|Broccoli|Chicken Breast|Steak": "Power Meat Green Sub",
		"Bread|Broccoli|Chicken Breast|Tofu": "Protein Green Sandwich",
		"Bread|Broccoli|Lettuce|Peas": "Triple Green Sandwich",
		"Bread|Broccoli|Lettuce|Potato": "Fresh Green Sub",
		"Bread|Broccoli|Lettuce|Rice": "Green Grain Sandwich",
		"Bread|Broccoli|Lettuce|Salmon": "Salmon Green Sandwich",
		"Bread|Broccoli|Lettuce|Steak": "Steak Green Sub",
		"Bread|Broccoli|Lettuce|Tofu": "Vegan Green Sandwich",
		"Bread|Broccoli|Peas|Potato": "Double Green Sub",
		"Bread|Broccoli|Peas|Rice": "Green Rice Sub",
		"Bread|Broccoli|Peas|Salmon": "Salmon Green Veggie Sub",
		"Bread|Broccoli|Peas|Steak": "Steak Green Veggie Sub",
		"Bread|Broccoli|Peas|Tofu": "Vegan Green Sub",
		"Bread|Broccoli|Potato|Rice": "Green Carb Sandwich",
		"Bread|Broccoli|Potato|Salmon": "Salmon Green Comfort Sub",
		"Bread|Broccoli|Potato|Steak": "Steak Green Comfort Sub",
		"Bread|Broccoli|Potato|Tofu": "Vegan Green Comfort Sub",
		"Bread|Broccoli|Rice|Salmon": "Salmon Green Grain Sub",
		"Bread|Broccoli|Rice|Steak": "Steak Green Grain Sub",
		"Bread|Broccoli|Rice|Tofu": "Vegan Green Grain Sub",
		"Bread|Broccoli|Salmon|Steak": "Double Protein Green Sub",
		"Bread|Broccoli|Salmon|Tofu": "Omega Green Wrap",
		"Bread|Broccoli|Steak|Tofu": "Power Green Wrap",
		"Bread|Carrot|Chicken Breast|Lettuce": "Garden Fresh Chicken Sub",
		"Bread|Carrot|Chicken Breast|Peas": "Chicken Veggie Sandwich",
		"Bread|Carrot|Chicken Breast|Potato": "Hearty Chicken Garden Sub",
		"Bread|Carrot|Chicken Breast|Rice": "Chicken Carrot Rice Sub",
		"Bread|Carrot|Chicken Breast|Salmon": "Surf & Garden Chicken Sub",
		"Bread|Carrot|Chicken Breast|Steak": "Double Meat Garden Sub",
		"Bread|Carrot|Chicken Breast|Tofu": "Protein Garden Sub",
		"Bread|Carrot|Lettuce|Peas": "Garden Fresh Wrap",
		"Bread|Carrot|Lettuce|Potato": "Root Salad Sandwich",
		"Bread|Carrot|Lettuce|Rice": "Fresh Carrot Grain Sub",
		
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
