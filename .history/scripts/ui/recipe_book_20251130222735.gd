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
	
	# Configure recipe grid for 2 column layout
	if recipe_grid:
		recipe_grid.columns = 2
		# Configure parent scroll container
		var scroll_container = recipe_grid.get_parent()
		if scroll_container is ScrollContainer:
			scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
			scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
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
## Generates ALL combinations organized by tier (8000+ recipes)
func _build_recipe_list():
	all_recipes.clear()
	
	var all_ingredients = RecipesData.BASE_INGREDIENTS + RecipesData.PREMIUM_INGREDIENTS
	
	print("[RecipeBook] Generating all recipe combinations...")
	
	# TIER 1: All 2-ingredient combinations (28 recipes)
	print("[RecipeBook] Generating Tier 1 (2-ingredient)...")
	_generate_tier_recipes(RecipesData.BASE_INGREDIENTS, 2, 2, 1)
	
	# TIER 2: All 3-4 ingredient combinations
	print("[RecipeBook] Generating Tier 2 (3-4 ingredients)...")
	_generate_tier_recipes(all_ingredients, 3, 3, 2)
	_generate_tier_recipes(all_ingredients, 4, 4, 2)
	
	# TIER 3: All 5-6 ingredient combinations
	print("[RecipeBook] Generating Tier 3 (5-6 ingredients)...")
	_generate_tier_recipes(all_ingredients, 5, 5, 3)
	_generate_tier_recipes(all_ingredients, 6, 6, 3)
	
	# TIER 4: All 7-8 ingredient combinations
	print("[RecipeBook] Generating Tier 4 (7-8 ingredients)...")
	_generate_tier_recipes(all_ingredients, 7, 7, 4)
	_generate_tier_recipes(all_ingredients, 8, 8, 4)
	
	# TIER 5: All 9-ingredient combinations
	print("[RecipeBook] Generating Tier 5 (9 ingredients)...")
	_generate_tier_recipes(all_ingredients, 9, 9, 5)
	
	# TIER 6: All 10-ingredient combinations
	print("[RecipeBook] Generating Tier 6 (10 ingredients)...")
	_generate_tier_recipes(all_ingredients, 10, 10, 6)
	
	# TIER 7: All 11-ingredient combinations
	print("[RecipeBook] Generating Tier 7 (11 ingredients)...")
	_generate_tier_recipes(all_ingredients, 11, 11, 7)
	
	# TIER 8: All 12-13 ingredient combinations (ultimate recipes)
	print("[RecipeBook] Generating Tier 8 (12-13 ingredients)...")
	_generate_tier_recipes(all_ingredients, 12, 12, 8)
	_generate_tier_recipes(all_ingredients, 13, 13, 8)
	
	print("[RecipeBook] Total recipes generated: %d" % all_recipes.size())

## Generate all combinations for a specific ingredient count and tier
func _generate_tier_recipes(ingredients: Array, min_count: int, max_count: int, tier: int):
	for count in range(min_count, max_count + 1):
		_generate_combinations(ingredients, count, tier)

## Generate all combinations of N ingredients
func _generate_combinations(ingredients: Array, count: int, tier: int):
	var combinations = _get_combinations(ingredients, count)
	var tier_recipes: Array[Dictionary] = []
	
	for combo in combinations:
		var typed_combo: Array[String] = []
		typed_combo.assign(combo)
		typed_combo.sort()
		var identity = "+".join(typed_combo)
		var display_name = RecipesData.get_recipe_name_for_ingredients(typed_combo)
		
		tier_recipes.append({
			"identity": identity,
			"display_name": display_name,
			"ingredients": typed_combo,
			"tier": tier
		})
	
	# Sort by display name
	tier_recipes.sort_custom(func(a, b): return a["display_name"] < b["display_name"])
	all_recipes.append_array(tier_recipes)
	
	print("[RecipeBook] Generated %d recipes for tier %d (%d ingredients)" % [tier_recipes.size(), tier, count])

## Get all combinations of N elements from array
func _get_combinations(arr: Array, n: int) -> Array:
	var result = []
	_combinations_helper(arr, n, 0, [], result)
	return result

## Recursive helper for generating combinations
func _combinations_helper(arr: Array, n: int, start: int, current: Array, result: Array):
	if current.size() == n:
		result.append(current.duplicate())
		return
	
	for i in range(start, arr.size()):
		current.append(arr[i])
		_combinations_helper(arr, n, i + 1, current, result)
		current.pop_back()

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
	# Always enable next button if there are more recipes to show
	next_button.disabled = (current_page >= total_pages - 1) or (total_pages <= 1)

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
