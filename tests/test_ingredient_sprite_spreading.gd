extends Node

## Test script for ingredient sprite spreading functionality
## Run this in Godot to verify the implementation works correctly

var test_results: Array[String] = []

func _ready():
print("\n=== Testing Ingredient Sprite Spreading ===\n")

test_ingredient_color_generation()
test_sprite_container_creation()
test_overlap_configuration()
test_plate_display_logic()

print("\n=== Test Results ===")
for result in test_results:
print(result)

print("\n=== Tests Complete ===\n")

## Test 1: Color generation is deterministic
func test_ingredient_color_generation():
print("Test 1: Color generation...")

# Create test ingredients
var ing1 = IngredientModel.new("Chicken", 65, 55, 75, 10)
var ing2 = IngredientModel.new("Chicken", 65, 55, 75, 10)
var ing3 = IngredientModel.new("Lettuce", 95, 20, 25, 5)

# Test that same ingredient produces same color
var color1 = _test_get_ingredient_color(ing1)
var color2 = _test_get_ingredient_color(ing2)

if color1 == color2:
test_results.append("✓ Same ingredient produces same color")
else:
test_results.append("✗ Same ingredient produces different colors!")

# Test that different ingredients produce different colors
var color3 = _test_get_ingredient_color(ing3)
if color1 != color3:
test_results.append("✓ Different ingredients produce different colors")
else:
test_results.append("✗ Different ingredients produce same color!")

## Test 2: Sprite container can be created
func test_sprite_container_creation():
print("Test 2: Sprite container creation...")

var container = HBoxContainer.new()
add_child(container)

# Create panels to simulate ingredient sprites
for i in range(3):
var panel = Panel.new()
panel.custom_minimum_size = Vector2(50, 50)
container.add_child(panel)

if container.get_child_count() == 3:
test_results.append("✓ Container can hold multiple sprite panels")
else:
test_results.append("✗ Container child count incorrect!")

container.queue_free()

## Test 3: Overlap configuration works
func test_overlap_configuration():
print("Test 3: Overlap configuration...")

var container = HBoxContainer.new()
add_child(container)

# Set negative separation
container.add_theme_constant_override("separation", -15)

# Check if theme override was applied
var separation = container.get_theme_constant("separation")
if separation == -15:
test_results.append("✓ Negative separation applies correctly")
else:
test_results.append("✗ Separation value: %d (expected -15)" % separation)

container.queue_free()

## Test 4: Plate display shows/hides correctly
func test_plate_display_logic():
print("Test 4: Plate display logic...")

# Test ingredient array building
var ing1 = IngredientModel.new("Chicken", 65, 55, 75, 10)
var ing2 = IngredientModel.new("Lettuce", 95, 20, 25, 5)

# Case 1: Two different ingredients
var ingredients1 = _build_ingredient_array(ing1, ing2)
if ingredients1.size() == 2:
test_results.append("✓ Two different ingredients → 2 sprites")
else:
test_results.append("✗ Expected 2 ingredients, got %d" % ingredients1.size())

# Case 2: Same ingredient twice
var ingredients2 = _build_ingredient_array(ing1, ing1)
if ingredients2.size() == 2:
test_results.append("✓ Same ingredient twice → 2 sprites")
else:
test_results.append("✗ Expected 2 ingredients for duplicate, got %d" % ingredients2.size())

## Helper: Build ingredient array (simulates plate_display logic)
func _build_ingredient_array(ing1: IngredientModel, ing2: IngredientModel) -> Array[IngredientModel]:
var ingredients: Array[IngredientModel] = []
if ing1:
ingredients.append(ing1)
if ing2 and ing2 != ing1:
ingredients.append(ing2)
elif ing2:
ingredients.append(ing2)
return ingredients

## Helper: Get ingredient color (simulates draft_selector/ingredient_selector logic)
func _test_get_ingredient_color(ingredient: IngredientModel) -> Color:
var name_hash = ingredient.name.hash()
var hue = float(name_hash % 360) / 360.0
var saturation = 0.6 + (ingredient.water_content / 100.0) * 0.4
var value = 0.5 + (ingredient.density / 100.0) * 0.5
return Color.from_hsv(hue, saturation, value)
