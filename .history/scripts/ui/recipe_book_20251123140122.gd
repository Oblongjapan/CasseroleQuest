extends Panel

## Recipe Book UI - Shows all possible recipes organized by tier with paging

@onready var page_label: Label = $VBox/BottomBar/PageLabel
@onready var prev_button: Button = $VBox/BottomBar/PrevButton
@onready var next_button: Button = $VBox/BottomBar/NextButton
@onready var close_button: Button = $VBox/TopBar/CloseButton
@onready var recipe_grid: GridContainer = $VBox/ScrollContainer/RecipeGrid
@onready var tier_label: Label = $VBox/TierLabel

const RecipeBookEntryScene = preload("res://scenes/recipe_book_entry.tscn")
const RECIPES_PER_PAGE = 8

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
	print("[RecipeBook] setup() called")
	recipe_book_manager = manager
	print("[RecipeBook] Manager assigned: ", manager != null)
	_build_recipe_list()
	_calculate_pages()
	current_page = 0
	_display_current_page()
	print("[RecipeBook] setup() complete")

## Build the complete list of all possible recipes from RecipesData
func _build_recipe_list():
	print("[RecipeBook] _build_recipe_list() called")
	all_recipes.clear()
	
	# Get all possible 2-ingredient combinations (Tier 1)
	var tier_1_recipes: Array[Dictionary] = []
	var base_ingredients = RecipesData.TIER_0_INGREDIENTS
	print("[RecipeBook] Base ingredients count: ", base_ingredients.size())
	print("[RecipeBook] Base ingredients: ", base_ingredients)
	
	for i in range(base_ingredients.size()):
		for j in range(i + 1, base_ingredients.size()):
			var ing1 = base_ingredients[i]
			var ing2 = base_ingredients[j]
			var identity = ing1 + "+" + ing2
			var ingredients_array: Array[String] = [ing1, ing2]
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
	
	print("[RecipeBook] Generated %d tier 1 recipes" % tier_1_recipes.size())
	
	# Add other tiers - for now just include discovered dynamic recipes
	# In future, could generate common 3+ingredient combinations
	
	print("[RecipeBook] Built recipe list with %d total recipes" % all_recipes.size())

## Calculate total pages needed
func _calculate_pages():
	total_pages = ceili(float(all_recipes.size()) / float(RECIPES_PER_PAGE))
	if total_pages == 0:
		total_pages = 1
	print("[RecipeBook] Total pages: %d" % total_pages)

## Display the current page of recipes
func _display_current_page():
	print("[RecipeBook] _display_current_page() called")
	print("[RecipeBook] Current page: %d / %d" % [current_page, total_pages])
	print("[RecipeBook] Total recipes: %d" % all_recipes.size())
	
	# Clear existing entries
	for child in recipe_grid.get_children():
		child.queue_free()
	
	print("[RecipeBook] Cleared %d existing children from grid" % recipe_grid.get_child_count())
	
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
		
		print("[RecipeBook] Adding recipe %d: %s (discovered: %s)" % [i, recipe_data["display_name"], is_discovered])
		
		var entry = RecipeBookEntryScene.instantiate()
		recipe_grid.add_child(entry)
		entry.setup(
			recipe_data["identity"],
			recipe_data["display_name"],
			recipe_data["ingredients"],
			is_discovered
		)
	
	print("[RecipeBook] Added %d recipe entries to grid" % (end_idx - start_idx))
	
	# Update navigation
	page_label.text = "Page %d / %d" % [current_page + 1, total_pages]
	prev_button.disabled = (current_page == 0)
	next_button.disabled = (current_page >= total_pages - 1)
	
	print("[RecipeBook] Displaying page %d (%d-%d)" % [current_page + 1, start_idx, end_idx])

## Open the recipe book
func open_book():
	print("[RecipeBook] open_book() called")
	print("[RecipeBook] recipe_book_manager exists: ", recipe_book_manager != null)
	if recipe_book_manager:
		_build_recipe_list()  # Rebuild to catch any new discoveries
		_calculate_pages()
		_display_current_page()
	else:
		print("[RecipeBook] ERROR: No recipe_book_manager!")
	show()
	print("[RecipeBook] Book is now visible")

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
