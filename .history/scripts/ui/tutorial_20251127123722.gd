extends Panel

## Tutorial screen with multiple pages

signal tutorial_closed

@onready var screenshot: TextureRect = $MarginContainer/VBoxContainer/PageContainer/PageContent/Screenshot
@onready var description_label: Label = $MarginContainer/VBoxContainer/PageContainer/PageContent/DescriptionLabel
@onready var page_indicator: Label = $MarginContainer/VBoxContainer/NavigationContainer/PageIndicator
@onready var prev_button: Button = $MarginContainer/VBoxContainer/NavigationContainer/PrevButton
@onready var next_button: Button = $MarginContainer/VBoxContainer/NavigationContainer/NextButton
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

var current_page: int = 0
var total_pages: int = 5

# Tutorial pages data
var pages: Array = []

func _ready():
	# Initialize tutorial pages
	pages = [
		{
			"texture": preload("res://Assets/Tutorial pages/Main menu.png"),
			"description": "Welcome to Casserole Quest! From the main menu, you can:\n• START GAME - Begin your cooking adventure\n• Recipe Book - View discovered recipes\n• Tutorial - View this guide anytime\n• EXIT - Close the game"
		},
		{
			"texture": preload("res://Assets/Tutorial pages/Main scene.png"),
			"description": "The Main Cooking Screen shows:\n• TIMER - How long until food is done (top display)\n• MOISTURE BAR - Keep this balanced (vertical bar)\n• DECK TRACKER - Remaining ingredients (10/10)\n• START BUTTON - Begin cooking your selection\n\nBalance is key - too dry or too wet means failure!"
		},
		{
			"texture": preload("res://Assets/Tutorial pages/Fridge.png"),
			"description": "The Fridge (Ingredient Selection):\n• Select 2 ingredients to microwave together\n• Each ingredient has MOISTURE and VOLATILITY stats\n• MOISTURE: How much water it adds (higher = wetter)\n• VOLATILITY: How fast it heats/dries (higher = faster)\n• Combine wisely to balance moisture over time!"
		},
		{
			"texture": preload("res://Assets/Tutorial pages/Recipe Book.png"),
			"description": "The Recipe Book:\n• Tracks all recipes you've discovered\n• Shows ingredient combinations that worked\n• Displays recipe stats and tier level\n• Unlock higher tiers by discovering more recipes\n• Use this to plan future ingredient combinations!"
		},
		{
			"texture": preload("res://Assets/Tutorial pages/Recipe Card.png"),
			"description": "Recipe Cards show:\n• COMBO NAME - The dish you created\n• MOISTURE STAT - Water content of the recipe\n• VOLATILITY STAT - How quickly it cooks\n• TIER - Recipe difficulty/complexity level\n\nTip: Higher tier recipes give better rewards and unlock new ingredients in the shop!"
		}
	]
	
	# Connect signals
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Show first page
	_update_page()
	print("[Tutorial] Ready - Total pages: %d" % total_pages)

func _update_page():
	# Update screenshot and description
	screenshot.texture = pages[current_page]["texture"]
	description_label.text = pages[current_page]["description"]
	
	# Update page indicator
	page_indicator.text = "Page %d / %d" % [current_page + 1, total_pages]
	
	# Update button states
	prev_button.disabled = (current_page == 0)
	next_button.disabled = (current_page == total_pages - 1)
	
	print("[Tutorial] Showing page %d/%d" % [current_page + 1, total_pages])

func _on_prev_pressed():
	if current_page > 0:
		current_page -= 1
		_update_page()

func _on_next_pressed():
	if current_page < total_pages - 1:
		current_page += 1
		_update_page()

func _on_close_pressed():
	print("[Tutorial] Closing tutorial")
	tutorial_closed.emit()
	hide()

func open_tutorial():
	current_page = 0
	_update_page()
	show()
	print("[Tutorial] Tutorial opened")
