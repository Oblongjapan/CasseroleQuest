extends Panel

## Tutorial screen with multiple pages

signal tutorial_closed

@onready var page_content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/PageContainer/PageContent
@onready var page_indicator: Label = $MarginContainer/VBoxContainer/NavigationContainer/PageIndicator
@onready var prev_button: Button = $MarginContainer/VBoxContainer/NavigationContainer/PrevButton
@onready var next_button: Button = $MarginContainer/VBoxContainer/NavigationContainer/NextButton
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

var current_page: int = 0
var total_pages: int = 0
var pages: Array = []

func _ready():
	# Get all page children
	for child in page_content.get_children():
		if child is Control:
			pages.append(child)
			child.hide()
	
	total_pages = pages.size()
	
	# Connect signals
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Show first page
	if total_pages > 0:
		_update_page()
	print("[Tutorial] Ready - Total pages: %d" % total_pages)

func _update_page():
	# Hide all pages
	for page in pages:
		page.hide()
	
	# Show current page
	if current_page < pages.size():
		pages[current_page].show()
	
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
