extends Button

# Small helper to wire a Button on the microwave to the IngredientSelector
# Usage:
# - Add a Button node to your microwave scene
# - Attach this script
# - Point `ingredient_selector_path` at the IngredientSelector node in the scene tree

@export var ingredient_selector_path: NodePath

@onready var ingredient_selector = null

func _ready():
	pressed.connect(_on_pressed)
	# Only try to resolve if a non-empty NodePath was provided
	if ingredient_selector_path != NodePath(""):
		# First try node lookup relative to this node
		if has_node(ingredient_selector_path):
			ingredient_selector = get_node(ingredient_selector_path)
		else:
			# If not found, try resolving from the scene root using the string form
			var root = get_tree().get_root()
			var path_str = str(ingredient_selector_path)
			if root and root.has_node(path_str):
				ingredient_selector = root.get_node(path_str)
			else:
				# leave as null if not found; user can assign in the editor
				ingredient_selector = null

func _on_pressed() -> void:
	if ingredient_selector and ingredient_selector.has_method("external_start"):
		ingredient_selector.external_start()
	else:
		print("microwave_start_button: ingredient_selector not assigned or missing external_start()")
