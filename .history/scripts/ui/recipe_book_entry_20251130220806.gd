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

## Update the visual display based on discovery status
## Single-line compact format
func update_display():
	var tier = _get_tier_for_ingredient_count(ingredient_list.size())
	
	# Hide stats label and lock icon - we'll use recipe_name_label for everything
	stats_label.hide()
	lock_icon.hide()
	ingredients_label.hide()
	
	if is_discovered:
		# Discovered - show full details in single line
		# Format: "Display Name (T1, 2 ing) - Ingredient1, Ingredient2"
		var ingredients_text = ", ".join(ingredient_list)
		recipe_name_label.text = "%s (T%d, %d ing) - %s" % [display_name, tier, ingredient_list.size(), ingredients_text]
		recipe_name_label.modulate = Color(0.85, 0.75, 0.95, 1.0)
	else:
		# Undiscovered - show as locked with tier info only
		recipe_name_label.text = "🔒 ??? (T%d, %d ing)" % [tier, ingredient_list.size()]
		recipe_name_label.modulate = Color(0.35, 0.35, 0.35, 0.8)

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
