extends PanelContainer

## Individual recipe entry in the recipe book
## Single-line format showing discovery status and tier

@onready var recipe_name_label: Label = $VBox/RecipeNameLabel
@onready var ingredients_label: Label = $VBox/IngredientsLabel
@onready var stats_label: Label = $VBox/StatsLabel
@onready var lock_icon: Label = $VBox/LockIcon

var recipe_identity: String = ""
var display_name: String = ""
var ingredient_list: Array[String] = []
var is_discovered: bool = false

func _ready():
	setup_style()

func setup_style():
	# Minimal style for single-line entries
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.08, 0.15, 0.5)
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	style_box.border_width_top = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color(0.3, 0.25, 0.4, 0.8)
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

## Setup as empty placeholder (no recipe data)
func setup_placeholder(tier: int):
	recipe_identity = ""
	display_name = "???"
	ingredient_list = []
	is_discovered = false
	
	# Wait for node to be ready before updating display
	if is_node_ready():
		_update_placeholder_display(tier)
	else:
		await ready
		_update_placeholder_display(tier)

## Display empty placeholder slot
func _update_placeholder_display(tier: int):
	stats_label.hide()
	lock_icon.hide()
	ingredients_label.hide()
	
	recipe_name_label.text = "🔒 ??? (T%d)" % tier
	recipe_name_label.modulate = Color(0.25, 0.25, 0.25, 0.6)
	recipe_name_label.tooltip_text = "Recipe not yet discovered"

## Update the visual display based on discovery status
## Shows only recipe name, ingredients appear as tooltip on hover
func update_display():
	var tier = _get_tier_for_ingredient_count(ingredient_list.size())
	
	# Hide unused labels
	stats_label.hide()
	lock_icon.hide()
	ingredients_label.hide()
	
	if is_discovered:
		# Discovered - show name only, ingredients as tooltip
		recipe_name_label.text = "%s (T%d)" % [display_name, tier]
		recipe_name_label.modulate = Color(0.85, 0.75, 0.95, 1.0)
		
		# Set tooltip with ingredients
		var ingredients_text = ", ".join(ingredient_list)
		recipe_name_label.tooltip_text = "Ingredients: %s" % ingredients_text
	else:
		# Undiscovered - show as locked
		recipe_name_label.text = "🔒 ??? (T%d)" % tier
		recipe_name_label.modulate = Color(0.35, 0.35, 0.35, 0.8)
		recipe_name_label.tooltip_text = "Not yet discovered"

## Get tier based on ingredient count
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

## Mark as discovered and update display
func mark_discovered():
	if not is_discovered:
		is_discovered = true
		update_display()
