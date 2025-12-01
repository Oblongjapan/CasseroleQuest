extends Panel

## Recipe Book UI - Shows all possible recipes organized by tier with paging

@onready var page_label: Label = $VBox/BottomBar/PageLabel
@onready var prev_button: Button = $VBox/BottomBar/PrevButton
@onready var next_button: Button = $VBox/BottomBar/NextButton
@onready var close_button: Button = $VBox/TopBar/CloseButton
@onready var recipe_grid: GridContainer = $VBox/ScrollContainer/RecipeGrid
@onready var tier_label: Label = $VBox/TierLabel

const RecipeBookEntryScene = preload("res://scenes/recipe_book_entry.tscn")
const RECIPES_PER_PAGE = 200  # Changed to 200 per page as requested

var recipe_book_manager: RecipeBookManager
var all_recipes: Array[Dictionary] = []  # All possible recipes organized by tier
var current_page: int = 0
var total_pages: int = 0

signal book_closed

func _ready():
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Make sure recipe book appears on top
	z_index = 100
	
	hide()

## Initialize the recipe book with all possible recipes
func setup(manager: RecipeBookManager):
	recipe_book_manager = manager
	_build_recipe_list()
	_calculate_pages()
	current_page = 0
	_display_current_page()

## Build the complete list of all possible recipes from RecipesData
func _build_recipe_list():
	all_recipes.clear()
	
	# TIER 1: Get all 28 2-ingredient combinations using BASE ingredients only
	var tier_1_recipes: Array[Dictionary] = []
	var base_ingredients = RecipesData.BASE_INGREDIENTS
	
	for i in range(base_ingredients.size()):
		for j in range(i + 1, base_ingredients.size()):
			var ing1 = base_ingredients[i]
			var ing2 = base_ingredients[j]
			var ingredients_array: Array[String] = [ing1, ing2]
			ingredients_array.sort()  # Sort for consistent identity
			var identity = "+".join(ingredients_array)
			var display_name = RecipesData.get_recipe_name_for_ingredients(ingredients_array)
			
			tier_1_recipes.append({
				"identity": identity,
				"display_name": display_name,
				"ingredients": ingredients_array,
				"tier": 1
			})
	
	# Sort Tier 1 recipes by display name
	tier_1_recipes.sort_custom(func(a, b): return a["display_name"] < b["display_name"])
	all_recipes.append_array(tier_1_recipes)
	
	# TIER 2: Add 3-4 ingredient combinations (with premium ingredients)
	# This includes all base-only 3-ingredient combos plus premium ingredient combos
	var tier_2_recipes: Array[Dictionary] = []
	
	# Sample key 3-ingredient combinations
	var sample_3_combos: Array = [
		# Base-only 3-ingredient combos (examples)
		["Bread", "Chicken Breast", "Lettuce"],
		["Bread", "Chicken Breast", "Peas"],
		["Bread", "Broccoli", "Chicken Breast"],
		["Broccoli", "Chicken Breast", "Rice"],
		["Carrot", "Chicken Breast", "Peas"],
		["Carrot", "Peas", "Potato"],
		["Broccoli", "Carrot", "Peas"],
		["Bread", "Lettuce", "Potato"],
		["Chicken Breast", "Lettuce", "Rice"],
		["Broccoli", "Lettuce", "Peas"],
		["Chicken Breast", "Peas", "Rice"],
		["Bread", "Broccoli", "Carrot"],
		["Bread", "Carrot", "Chicken Breast"],
		["Bread", "Broccoli", "Lettuce"],
		["Broccoli", "Carrot", "Chicken Breast"],
		# With premium ingredients
		["Chicken Breast", "Rice", "Salmon"],
		["Chicken Breast", "Potato", "Spinach"],
		["Chicken Breast", "Rice", "Spinach"],
		["Lettuce", "Steak", "Tofu"],
		["Carrot", "Potato", "Steak"],
		["Asparagus", "Chicken Breast", "Rice"],
		["Bread", "Lettuce", "Tofu"],
		["Chicken Breast", "Salmon", "Spinach"],
		["Broccoli", "Steak", "Tofu"],
		["Carrot", "Rice", "Salmon"],
		["Peas", "Rice", "Tofu"],
		["Asparagus", "Potato", "Steak"],
		["Bread", "Potato", "Tofu"],
		["Lettuce", "Salmon", "Spinach"],
		["Broccoli", "Salmon", "Spinach"],
	]
	
	# Sample 4-ingredient combinations
	var sample_4_combos: Array = [
		["Broccoli", "Carrot", "Chicken Breast", "Rice"],
		["Bread", "Chicken Breast", "Lettuce", "Peas"],
		["Carrot", "Chicken Breast", "Peas", "Rice"],
		["Broccoli", "Carrot", "Lettuce", "Potato"],
		["Chicken Breast", "Rice", "Salmon", "Spinach"],
		["Lettuce", "Potato", "Steak", "Tofu"],
		["Asparagus", "Carrot", "Peas", "Potato"],
		["Bread", "Chicken Breast", "Spinach", "Tofu"],
		["Broccoli", "Chicken Breast", "Salmon", "Spinach"],
		["Bread", "Lettuce", "Steak", "Tofu"],
		["Carrot", "Peas", "Potato", "Salmon"],
		["Chicken Breast", "Potato", "Rice", "Steak"],
	]
	
	for combo in sample_3_combos + sample_4_combos:
		var typed_combo: Array[String] = []
		typed_combo.assign(combo)
		typed_combo.sort()
		var identity = "+".join(typed_combo)
		var display_name = RecipesData.get_recipe_name_for_ingredients(typed_combo)
		
		tier_2_recipes.append({
			"identity": identity,
			"display_name": display_name,
			"ingredients": typed_combo,
			"tier": 2
		})
	
	tier_2_recipes.sort_custom(func(a, b): return a["display_name"] < b["display_name"])
	all_recipes.append_array(tier_2_recipes)
	
	# TIER 3: Add 5-6 ingredient combinations
	var tier_3_recipes: Array[Dictionary] = []
	var sample_5_6_combos: Array = [
		# 5 ingredients
		["Broccoli", "Carrot", "Chicken Breast", "Peas", "Rice"],
		["Bread", "Chicken Breast", "Lettuce", "Peas", "Spinach"],
		["Carrot", "Chicken Breast", "Peas", "Potato", "Salmon"],
		["Broccoli", "Carrot", "Peas", "Potato", "Spinach"],
		["Asparagus", "Broccoli", "Carrot", "Chicken Breast", "Rice"],
		["Chicken Breast", "Potato", "Rice", "Salmon", "Spinach"],
		["Bread", "Lettuce", "Potato", "Steak", "Tofu"],
		["Broccoli", "Chicken Breast", "Rice", "Salmon", "Tofu"],
		# 6 ingredients
		["Broccoli", "Carrot", "Chicken Breast", "Peas", "Potato", "Rice"],
		["Asparagus", "Broccoli", "Carrot", "Chicken Breast", "Peas", "Rice"],
		["Broccoli", "Carrot", "Peas", "Potato", "Spinach", "Tofu"],
		["Chicken Breast", "Lettuce", "Peas", "Rice", "Salmon", "Spinach"],
		["Bread", "Broccoli", "Chicken Breast", "Salmon", "Steak", "Tofu"],
		["Carrot", "Lettuce", "Potato", "Rice", "Salmon", "Steak"],
	]
	
	for combo in sample_5_6_combos:
		var typed_combo: Array[String] = []
		typed_combo.assign(combo)
		typed_combo.sort()
		var identity = "+".join(typed_combo)
		var display_name = RecipesData.get_recipe_name_for_ingredients(typed_combo)
		
		tier_3_recipes.append({
			"identity": identity,
			"display_name": display_name,
			"ingredients": typed_combo,
			"tier": 3
		})
	
	tier_3_recipes.sort_custom(func(a, b): return a["display_name"] < b["display_name"])
	all_recipes.append_array(tier_3_recipes)
	
	# TIER 4: Add 7-8 ingredient combinations (legendary recipes)
	var tier_4_recipes: Array[Dictionary] = []
	var sample_7_8_combos: Array = [
		# 7 ingredients
		["Asparagus", "Broccoli", "Carrot", "Chicken Breast", "Peas", "Potato", "Rice"],
		["Broccoli", "Carrot", "Chicken Breast", "Lettuce", "Peas", "Spinach", "Tofu"],
		["Bread", "Carrot", "Chicken Breast", "Potato", "Salmon", "Spinach", "Steak"],
		["Broccoli", "Lettuce", "Peas", "Rice", "Salmon", "Steak", "Tofu"],
		# 8 ingredients (ultimate)
		["Asparagus", "Bread", "Broccoli", "Chicken Breast", "Lettuce", "Salmon", "Steak", "Tofu"],
		["Broccoli", "Carrot", "Chicken Breast", "Peas", "Potato", "Rice", "Salmon", "Spinach"],
		["Asparagus", "Broccoli", "Carrot", "Lettuce", "Potato", "Salmon", "Steak", "Tofu"],
		["Asparagus", "Broccoli", "Carrot", "Chicken Breast", "Lettuce", "Peas", "Potato", "Rice"],
		["Asparagus", "Broccoli", "Carrot", "Lettuce", "Peas", "Potato", "Spinach", "Tofu"],
	]
	
	for combo in sample_7_8_combos:
		var typed_combo: Array[String] = []
		typed_combo.assign(combo)
		typed_combo.sort()
		var identity = "+".join(typed_combo)
		var display_name = RecipesData.get_recipe_name_for_ingredients(typed_combo)
		
		tier_4_recipes.append({
			"identity": identity,
			"display_name": display_name,
			"ingredients": typed_combo,
			"tier": 4
		})
	
	tier_4_recipes.sort_custom(func(a, b): return a["display_name"] < b["display_name"])
	all_recipes.append_array(tier_4_recipes)

## Calculate total pages needed
func _calculate_pages():
	total_pages = ceili(float(all_recipes.size()) / float(RECIPES_PER_PAGE))
	if total_pages == 0:
		total_pages = 1

## Display the current page of recipes
func _display_current_page():
	# Null check for recipe_grid
	if not recipe_grid:
		return
	
	# Clear existing entries
	for child in recipe_grid.get_children():
		child.queue_free()
	
	# Calculate recipe range for this page
	var start_idx = current_page * RECIPES_PER_PAGE
	var end_idx = mini(start_idx + RECIPES_PER_PAGE, all_recipes.size())
	
	# Determine tier for this page
	var page_tier = 1
	if all_recipes.size() > 0 and start_idx < all_recipes.size():
		page_tier = all_recipes[start_idx]["tier"]
	
	# Update tier label
	tier_label.text = "TIER %d RECIPES" % page_tier
	
	# Add recipe entries
	for i in range(start_idx, end_idx):
		var recipe_data = all_recipes[i]
		var is_discovered = recipe_book_manager.is_discovered(recipe_data["identity"])
		
		var entry = RecipeBookEntryScene.instantiate()
		recipe_grid.add_child(entry)
		entry.setup(
			recipe_data["identity"],
			recipe_data["display_name"],
			recipe_data["ingredients"],
			is_discovered
		)
	
	# Update navigation
	page_label.text = "Page %d / %d" % [current_page + 1, total_pages]
	prev_button.disabled = (current_page == 0)
	next_button.disabled = (current_page >= total_pages - 1)

## Open the recipe book
func open_book():
	if recipe_book_manager:
		_build_recipe_list()  # Rebuild to catch any new discoveries
		_calculate_pages()
		_display_current_page()
	
	show()

func _on_prev_pressed():
	if current_page > 0:
		current_page -= 1
		_display_current_page()

func _on_next_pressed():
	if current_page < total_pages - 1:
		current_page += 1
		_display_current_page()

func _on_close_pressed():
	hide()
	book_closed.emit()
