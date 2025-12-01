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
	
	# Recipe name mappings - organized by ingredient count
	var recipe_names = {
		# ===== TIER 1: 2 Ingredients - ONLY BASE INGREDIENTS (28 combinations from 8 base) =====
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
		"Broccoli|Potato": "Broccoli Potato",
		"Broccoli|Rice": "Broccoli Rice",
		
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
		
		# ===== TIER 2+: 3+ Ingredients - CAN INCLUDE PREMIUM INGREDIENTS =====
		# 3 Ingredients - Base only
		"Bread|Chicken Breast|Lettuce": "Chicken Lettuce Sandwich",
		"Bread|Chicken Breast|Peas": "Hot Chicken Sandwich",
		"Bread|Broccoli|Chicken Breast": "Chicken Broccoli Sub",
		"Broccoli|Chicken Breast|Rice": "Chicken Broccoli Bowl",
		"Carrot|Chicken Breast|Peas": "Chicken à la King",
		"Carrot|Peas|Potato": "Vegetable Medley",
		"Broccoli|Carrot|Peas": "Garden Vegetables",
		"Bread|Lettuce|Potato": "Veggie Sub",
		"Chicken Breast|Lettuce|Rice": "Chicken Salad Bowl",
		"Broccoli|Lettuce|Peas": "Green Salad Mix",
		
		# 3 Ingredients - With premium ingredients
		"Chicken Breast|Peas|Rice": "Chicken Fried Rice",
		"Chicken Breast|Rice|Salmon": "Surf & Turf Bowl",
		"Chicken Breast|Potato|Spinach": "Chicken Harvest Plate",
		"Chicken Breast|Rice|Spinach": "Healthy Chicken Bowl",
		"Lettuce|Steak|Tofu": "Protein Salad",
		"Carrot|Potato|Steak": "Hearty Stew Base",
		"Asparagus|Chicken Breast|Rice": "Chicken Asparagus Bowl",
		"Bread|Lettuce|Tofu": "Veggie Sandwich",
		"Chicken Breast|Salmon|Spinach": "Omega Protein Plate",
		"Broccoli|Steak|Tofu": "Power Protein Bowl",
		"Carrot|Rice|Salmon": "Salmon Veggie Bowl",
		"Asparagus|Potato|Steak": "Steakhouse Veggies",
		"Bread|Potato|Tofu": "Tofu Potato Sandwich",
		"Lettuce|Salmon|Spinach": "Ocean Greens Salad",
		"Peas|Rice|Tofu": "Tofu Rice Mix",
		
		# 4 Ingredients - Mix of base and premium
		"Broccoli|Carrot|Chicken Breast|Rice": "Chicken Stir Fry",
		"Bread|Chicken Breast|Lettuce|Peas": "Garden Chicken Sandwich",
		"Carrot|Chicken Breast|Peas|Rice": "Chicken Paella",
		"Broccoli|Carrot|Lettuce|Potato": "Vegetarian Feast",
		"Chicken Breast|Rice|Salmon|Spinach": "Omega Power Bowl",
		"Lettuce|Potato|Steak|Tofu": "Steakhouse Salad",
		"Asparagus|Carrot|Peas|Potato": "Spring Vegetable Mix",
		"Bread|Chicken Breast|Spinach|Tofu": "Protein Power Sandwich",
		"Broccoli|Chicken Breast|Salmon|Spinach": "Seafood Power Plate",
		"Bread|Lettuce|Steak|Tofu": "Protein Sandwich Deluxe",
		"Carrot|Peas|Potato|Salmon": "Salmon Veggie Medley",
		"Chicken Breast|Potato|Rice|Steak": "Meat Lovers Bowl",
		
		# 5 Ingredients - Premium heavy
		"Broccoli|Carrot|Chicken Breast|Peas|Rice": "Grand Chicken Bowl",
		"Bread|Chicken Breast|Lettuce|Peas|Spinach": "Supreme Sandwich",
		"Carrot|Chicken Breast|Peas|Potato|Salmon": "Surf & Garden Bowl",
		"Broccoli|Carrot|Peas|Potato|Spinach": "Garden Harvest",
		"Asparagus|Broccoli|Carrot|Chicken Breast|Rice": "Gourmet Chicken Plate",
		"Chicken Breast|Potato|Rice|Salmon|Spinach": "Fisherman's Bounty",
		"Bread|Lettuce|Potato|Steak|Tofu": "Ultimate Protein Sandwich",
		"Broccoli|Chicken Breast|Rice|Salmon|Tofu": "Omega Fusion Bowl",
		
		# 6 Ingredients - Premium dominant
		"Broccoli|Carrot|Chicken Breast|Peas|Potato|Rice": "Chef's Special Bowl",
		"Asparagus|Broccoli|Carrot|Chicken Breast|Peas|Rice": "Premium Chicken Feast",
		"Broccoli|Carrot|Peas|Potato|Spinach|Tofu": "Vegan Delight",
		"Chicken Breast|Lettuce|Peas|Rice|Salmon|Spinach": "Ocean Garden Bowl",
		"Bread|Broccoli|Chicken Breast|Salmon|Steak|Tofu": "Protein Paradise Sandwich",
		"Carrot|Lettuce|Potato|Rice|Salmon|Steak": "Deluxe Meat & Veggie Bowl",
		
		# 7 Ingredients - Maximum variety
		"Asparagus|Broccoli|Carrot|Chicken Breast|Peas|Potato|Rice": "Kitchen Sink Bowl",
		"Broccoli|Carrot|Chicken Breast|Lettuce|Peas|Spinach|Tofu": "Everything Protein Bowl",
		"Bread|Carrot|Chicken Breast|Potato|Salmon|Spinach|Steak": "Grand Feast Sandwich",
		"Broccoli|Lettuce|Peas|Rice|Salmon|Steak|Tofu": "Ultimate Power Bowl",
		
		# 8 Ingredients - The ultimate recipes
		"Asparagus|Bread|Broccoli|Chicken Breast|Lettuce|Salmon|Steak|Tofu": "Supreme Protein Sandwich",
		"Broccoli|Carrot|Chicken Breast|Peas|Potato|Rice|Salmon|Spinach": "Master Chef's Creation",
		"Asparagus|Broccoli|Carrot|Lettuce|Potato|Salmon|Steak|Tofu": "Legendary Feast Bowl",
		
		# 8 Ingredients (Maximum)
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
