extends Control

## Tutorial screen with multiple pages

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var content_label: Label = $Panel/VBoxContainer/ContentLabel
@onready var image_rect: TextureRect = $Panel/VBoxContainer/ImageContainer/TextureRect
@onready var prev_button: Button = $Panel/VBoxContainer/Navigation/PrevButton
@onready var next_button: Button = $Panel/VBoxContainer/Navigation/NextButton
@onready var close_button: Button = $Panel/CloseButton
@onready var page_indicator: Label = $Panel/VBoxContainer/Navigation/PageIndicator

var current_page: int = 0
var pages: Array[Dictionary] = []

signal tutorial_closed

func _ready():
	# Define pages
	pages = [
		{
			"title": "Microwave Master Chef",
			"text": "Head back to the 70s in an era where the microwave has been gaining popularity. Cookbooks are being released left and right and your goal is to create a compendium of all the cookbooks combined to become the Microwave Master Chef!\n\nThe goal of this game is to combine ingredients in the microwave to create new recipes to add to your cookbook. Sounds easy, but some ingredients are harder to combine than others.",
			"image_path": "res://Assets/Tutorial pages/Main scene.png"
		},
		{
			"title": "Ingredient Cards & Stats",
			"text": "Input: Click and drag\nSpace = Pause\nHover on cards for tips and ingredient lists\n\nMICROWAVE MOISTURE DRAIN\nThe microwave has its own personal drain rate that grows as you create.\n\nIngredient cards have 3 stats that influence the total drain rate:\n• Water - Moisture content of the ingredients\n• Heat Resistance - The ingredient's resistance to the microwave's moisture drain\n• Volatility - Multiplier added to the microwave's moisture drain.",
			"image_path": "res://Assets/Tutorial pages/Recipe Card.png"
		},
		{
			"title": "Cooking & Survival",
			"text": "Your ingredients must survive 15 seconds in the microwave without losing all their combined moisture. When successful, a new recipe will be created!\n\nUse the free samples in the fridge to replenish your ingredient stock.",
			"image_path": "res://Assets/Tutorial pages/Fridge.png"
		}
	]
	
	# Connect buttons
	if prev_button:
		prev_button.pressed.connect(_on_prev_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Show first page
	_update_page()

func _update_page() -> void:
	if pages.is_empty():
		return
		
	var page_data = pages[current_page]
	
	if title_label:
		title_label.text = page_data["title"]
	
	if content_label:
		content_label.text = page_data["text"]
	
	if image_rect:
		var texture = load(page_data["image_path"])
		if texture:
			image_rect.texture = texture
		else:
			print("[Tutorial] Warning: Could not load image %s" % page_data["image_path"])
	
	if page_indicator:
		page_indicator.text = "Page %d/%d" % [current_page + 1, pages.size()]
	
	# Update button states
	if prev_button:
		prev_button.disabled = (current_page == 0)
	
	if next_button:
		if current_page == pages.size() - 1:
			next_button.text = "Finish"
		else:
			next_button.text = "Next"

func _on_prev_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		_update_page()

func _on_next_pressed() -> void:
	if current_page < pages.size() - 1:
		current_page += 1
		_update_page()
	else:
		_on_close_pressed()

func _on_close_pressed() -> void:
	hide()
	tutorial_closed.emit()
