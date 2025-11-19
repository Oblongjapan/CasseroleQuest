extends Panel

## Recipe notification popup - shows when a new recipe is discovered

signal notification_closed

@onready var recipe_name_label: Label = $VBoxContainer/RecipeNameLabel
@onready var ok_button: Button = $VBoxContainer/OKButton

func _ready():
	ok_button.pressed.connect(_on_ok_pressed)
	
	# Add golden theme
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(1.0, 0.84, 0.0)  # Golden color
	style_box.border_color = Color(0.8, 0.6, 0.0)  # Darker golden border
	style_box.set_border_width_all(2)
	add_theme_stylebox_override("panel", style_box)

func show_notification(recipe_name: String) -> void:
	recipe_name_label.text = recipe_name
	show()

func _on_ok_pressed() -> void:
	hide()
	notification_closed.emit()
