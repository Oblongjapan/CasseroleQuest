extends HBoxContainer

## Container that displays ingredient sprites spread along x-axis with overlap
## Used for visual representation in plate, cards, and microwave displays

# Configuration for visual arrangement
@export var overlap_amount: float = 20.0  ## How much sprites overlap (in pixels)
@export var sprite_size: Vector2 = Vector2(80, 80)  ## Size of each ingredient sprite
@export var use_colored_placeholders: bool = true  ## Use colored rects as placeholders when no textures

var current_ingredients: Array[IngredientModel] = []

func _ready():
	# Configure container to allow overlap
	add_theme_constant_override("separation", -int(overlap_amount))

## Display ingredients with visual overlap
## ingredients: Array of IngredientModel to display
func display_ingredients(ingredients: Array[IngredientModel]) -> void:
	clear_ingredients()
	current_ingredients = ingredients
	
	for ingredient in ingredients:
		var sprite_panel = _create_ingredient_sprite(ingredient)
		add_child(sprite_panel)

## Clear all displayed ingredients
func clear_ingredients() -> void:
	for child in get_children():
		child.queue_free()
	current_ingredients.clear()

## Create a visual representation of an ingredient
func _create_ingredient_sprite(ingredient: IngredientModel) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = sprite_size
	
	if use_colored_placeholders:
		# Create a colored placeholder based on ingredient properties
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = sprite_size
		color_rect.color = _get_ingredient_color(ingredient)
		panel.add_child(color_rect)
		
		# Add label with ingredient name
		var label = Label.new()
		label.text = ingredient.name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = sprite_size
		label.add_theme_font_size_override("font_size", 10)
		panel.add_child(label)
	else:
		# In future, load actual texture here
		# var texture_rect = TextureRect.new()
		# texture_rect.texture = load("res://Assets/ingredients/%s.png" % ingredient.name.to_lower())
		# panel.add_child(texture_rect)
		pass
	
	return panel

## Generate a color for an ingredient based on its properties
func _get_ingredient_color(ingredient: IngredientModel) -> Color:
	# Use ingredient name hash to generate consistent colors
	var name_hash = ingredient.name.hash()
	var hue = float(name_hash % 360) / 360.0
	
	# Adjust saturation and value based on water content
	var saturation = 0.6 + (ingredient.water_content / 100.0) * 0.4
	var value = 0.5 + (ingredient.density / 100.0) * 0.5
	
	return Color.from_hsv(hue, saturation, value)

## Update overlap amount dynamically
func set_overlap(new_overlap: float) -> void:
	overlap_amount = new_overlap
	add_theme_constant_override("separation", -int(overlap_amount))

## Update sprite size dynamically
func set_sprite_size(new_size: Vector2) -> void:
	sprite_size = new_size
	# Refresh display if ingredients are already shown
	if current_ingredients.size() > 0:
		display_ingredients(current_ingredients)
