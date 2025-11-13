extends Button

# Small helper to wire a Button on the microwave to the IngredientSelector
# Usage:
# - Add a Button node to your microwave scene
# - Attach this script
# - Point `ingredient_selector_path` at the IngredientSelector node in the scene tree

@export var ingredient_selector_path: NodePath

onready var ingredient_selector = null

func _ready():
	pressed.connect(_on_pressed)
	if ingredient_selector_path != null and ingredient_selector_path != "":
		if has_node(ingredient_selector_path):
			ingredient_selector = get_node(ingredient_selector_path)
		else:
			# If a relative path was given, try absolute
			var root_path = get_tree().get_root().get_path()
			# leave as null if not found; user can assign in the editor
			ingredient_selector = null

func _on_pressed() -> void:
	if ingredient_selector and ingredient_selector.has_method("external_start"):
		ingredient_selector.external_start()
	else:
		print("microwave_start_button: ingredient_selector not assigned or missing external_start()")
