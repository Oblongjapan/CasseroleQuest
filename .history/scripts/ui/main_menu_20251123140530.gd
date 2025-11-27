extends Panel

## Main menu screen

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var recipe_book_button: Button = $VBoxContainer/RecipeBookButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var tagline_label: Label = $VBoxContainer/TaglineLabel

var recipe_book_manager: RecipeBookManager
var recipe_book_ui: Panel

func _ready():
	print("[MainMenu] _ready() called")
	print("[MainMenu] start_button: ", start_button)
	print("[MainMenu] recipe_book_button: ", recipe_book_button)
	print("[MainMenu] quit_button: ", quit_button)
	
	start_button.pressed.connect(_on_start_pressed)
	if recipe_book_button:
		recipe_book_button.pressed.connect(_on_recipe_book_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Setup recipe book manager
	recipe_book_manager = RecipeBookManager.new()
	add_child(recipe_book_manager)
	
	# Setup recipe book UI - add it to the root instead of as a child of MainMenu
	var recipe_book_scene = load("res://scenes/recipe_book.tscn")
	recipe_book_ui = recipe_book_scene.instantiate()
	
	# Add to root (parent of MainMenu) so it's not hidden when MainMenu hides
	# Use call_deferred to ensure parent exists
	if get_parent():
		get_parent().call_deferred("add_child", recipe_book_ui)
	else:
		# Fallback: add as child of MainMenu if no parent exists
		add_child(recipe_book_ui)
	
	# Setup after adding to tree
	await get_tree().process_frame
	recipe_book_ui.setup(recipe_book_manager)
	recipe_book_ui.book_closed.connect(_on_recipe_book_closed)
	
	print("[MainMenu] Ready complete")

## Handle start game button
func _on_start_pressed() -> void:
	print("[MainMenu] ========================================")
	print("[MainMenu] START BUTTON PRESSED!")
	print("[MainMenu] ========================================")
	print("[MainMenu] Loading main game scene...")
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	print("[MainMenu] Scene change requested")

## Handle recipe book button
func _on_recipe_book_pressed() -> void:
	print("[MainMenu] Opening recipe book...")
	print("[MainMenu] Main menu visible before hide: ", visible)
	hide()  # Hide main menu
	print("[MainMenu] Main menu visible after hide: ", visible)
	print("[MainMenu] Recipe book UI exists: ", recipe_book_ui != null)
	print("[MainMenu] Recipe book UI visible before open: ", recipe_book_ui.visible if recipe_book_ui else "N/A")
	recipe_book_ui.open_book()
	print("[MainMenu] Recipe book UI visible after open: ", recipe_book_ui.visible if recipe_book_ui else "N/A")

## Handle recipe book closed
func _on_recipe_book_closed() -> void:
	print("[MainMenu] Recipe book closed")
	show()  # Show main menu again

## Handle quit button
func _on_quit_pressed() -> void:
	print("[MainMenu] Quitting game...")
	get_tree().quit()
