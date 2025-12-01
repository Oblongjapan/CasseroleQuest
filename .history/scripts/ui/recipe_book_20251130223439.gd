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
## Only shows DISCOVERED recipes (not all 8000+ combinations)
func _build_recipe_list():
	all_recipes.clear()
	
	# Get discovered recipe identities from manager
	var discovered_identities = recipe_book_manager.get_discovered_recipes()
	print("[RecipeBook] Building list from %d discovered recipes" % discovered_identities.size())
	
	# Convert each discovered recipe identity into display data
	for identity in discovered_identities:
		var ingredient_names = identity.split("+")
		var display_name = RecipesData.get_recipe_name_for_ingredients(ingredient_names)
		var tier = _get_tier_for_ingredient_count(ingredient_names.size())
		
		all_recipes.append({
			"identity": identity,
			"display_name": display_name,
			"ingredient_names": ingredient_names,
			"tier": tier
		})
	
	# Sort by tier, then by name
	all_recipes.sort_custom(func(a, b): 
		if a["tier"] != b["tier"]:
			return a["tier"] < b["tier"]
		return a["display_name"] < b["display_name"]
	)
	
	print("[RecipeBook] Recipe list built: %d discovered recipes" % all_recipes.size())

## Helper function to determine tier from ingredient count
func _get_tier_for_ingredient_count(count: int) -> int:
	if count <= 2:
		return 1
	elif count <= 4:
		return 2
	elif count <= 6:
		return 3
	elif count <= 8:
		return 4
	elif count == 9:
		return 5
	elif count == 10:
		return 6
	elif count == 11:
		return 7
	else:
		return 8

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
