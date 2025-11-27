extends PanelContainer

## Individual recipe entry in the recipe book
## Shows as greyed out/locked if not discovered

@onready var recipe_name_label: Label = $VBox/RecipeNameLabel
@onready var ingredients_label: Label = $VBox/IngredientsLabel
@onready var stats_label: Label = $VBox/StatsLabel
@onready var lock_icon: Label = $VBox/LockIcon

var recipe_identity: String = ""
var display_name: String = ""
var ingredient_list: Array[String] = []
var is_discovered: bool = false

func _ready():
	print("[RecipeEntry] _ready() called")
	setup_style()
	print("[RecipeEntry] Style setup complete")
	print("[RecipeEntry] Visible: ", visible)
	print("[RecipeEntry] Modulate: ", modulate)
	print("[RecipeEntry] Size: ", size)
	print("[RecipeEntry] Custom minimum size: ", custom_minimum_size)

func setup_style():
	# Create a style for the panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.1, 0.25, 0.95)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.4, 0.3, 0.6, 1.0)
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	add_theme_stylebox_override("panel", style_box)

## Setup the recipe entry
func setup(p_recipe_identity: String, p_display_name: String, p_ingredients: Array[String], p_discovered: bool):
	recipe_identity = p_recipe_identity
	display_name = p_display_name
	ingredient_list = p_ingredients
	is_discovered = p_discovered
	
	# Wait for node to be ready before updating display
	if is_node_ready():
		update_display()
	else:
		await ready
		update_display()

## Update the visual display based on discovery status
func update_display():
	print("[RecipeEntry] update_display() - recipe_name_label: ", recipe_name_label != null)
	print("[RecipeEntry] update_display() - ingredients_label: ", ingredients_label != null)
	print("[RecipeEntry] update_display() - is_discovered: ", is_discovered)
	
	if is_discovered:
		# Discovered - show full details
		recipe_name_label.text = display_name
		recipe_name_label.modulate = Color(0.9, 0.8, 1.0, 1.0)
		
		var ingredients_text = ", ".join(ingredient_list)
		ingredients_label.text = ingredients_text
		ingredients_label.modulate = Color(0.7, 0.6, 0.9, 1.0)
		
		# Show tier badge
		var tier = _get_tier_for_ingredient_count(ingredient_list.size())
		stats_label.text = "Tier %d • %d ingredients" % [tier, ingredient_list.size()]
		stats_label.modulate = Color(0.6, 0.5, 0.8, 1.0)
		
		lock_icon.hide()
	else:
		# Undiscovered - show as locked
		recipe_name_label.text = "???"
		recipe_name_label.modulate = Color(0.3, 0.3, 0.3, 1.0)
		
		ingredients_label.text = "Not yet discovered"
		ingredients_label.modulate = Color(0.3, 0.3, 0.3, 1.0)
		
		var tier = _get_tier_for_ingredient_count(ingredient_list.size())
		stats_label.text = "Tier %d" % tier
		stats_label.modulate = Color(0.3, 0.3, 0.3, 1.0)
		
		lock_icon.show()
		lock_icon.text = "🔒"
		lock_icon.modulate = Color(0.4, 0.4, 0.4, 1.0)

## Get tier based on ingredient count
func _get_tier_for_ingredient_count(count: int) -> int:
	if count <= 2:
		return 1
	elif count <= 4:
		return 2
	elif count <= 6:
		return 3
	else:
		return 4

## Mark as discovered and update display
func mark_discovered():
	if not is_discovered:
		is_discovered = true
		update_display()
