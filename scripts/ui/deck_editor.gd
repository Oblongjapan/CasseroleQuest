extends Panel

## Deck Editor UI - allows building and saving custom starting decks

@onready var ingredient_list_container: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/LeftPanel/IngredientList/VBoxContainer
@onready var deck_list_container: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/RightPanel/DeckList/VBoxContainer
@onready var deck_count_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/RightPanel/DeckCountLabel
@onready var deck_name_input: LineEdit = $MarginContainer/VBoxContainer/BottomPanel/DeckNameInput
@onready var save_button: Button = $MarginContainer/VBoxContainer/BottomPanel/SaveButton
@onready var load_button: Button = $MarginContainer/VBoxContainer/BottomPanel/LoadButton
@onready var close_button: Button = $MarginContainer/VBoxContainer/BottomPanel/CloseButton

var current_deck: Dictionary = {}  # ingredient_name -> count
var available_ingredients: Array[IngredientModel] = []

signal deck_saved(deck_name: String, deck_composition: Dictionary)
signal deck_loaded(deck_name: String, deck_composition: Dictionary)
signal editor_closed()

func _ready():
	# Connect button signals
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Load available ingredients
	_load_available_ingredients()
	
	# Populate ingredient list
	_populate_ingredient_list()
	
	# Update deck display
	_update_deck_display()
	
	hide()

func _load_available_ingredients():
	# Get all ingredients from IngredientsData
	var all_ingredients = IngredientsData.get_all_ingredients()
	
	# Sort by name for easier browsing
	all_ingredients.sort_custom(func(a, b): return a.name < b.name)
	
	available_ingredients = all_ingredients
	print("[DeckEditor] Loaded %d available ingredients" % available_ingredients.size())

func _populate_ingredient_list():
	# Clear existing
	for child in ingredient_list_container.get_children():
		child.queue_free()
	
	# Create a button for each ingredient
	for ingredient in available_ingredients:
		var hbox = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = ingredient.name
		name_label.custom_minimum_size = Vector2(200, 0)
		hbox.add_child(name_label)
		
		var add_button = Button.new()
		add_button.text = "+"
		add_button.custom_minimum_size = Vector2(40, 40)
		add_button.pressed.connect(_on_add_ingredient.bind(ingredient.name))
		hbox.add_child(add_button)
		
		ingredient_list_container.add_child(hbox)

func _update_deck_display():
	# Clear existing
	for child in deck_list_container.get_children():
		child.queue_free()
	
	# Calculate total cards
	var total_cards = 0
	
	# Sort deck ingredients alphabetically
	var sorted_names = current_deck.keys()
	sorted_names.sort()
	
	# Create display for each ingredient in deck
	for ingredient_name in sorted_names:
		var count = current_deck[ingredient_name]
		total_cards += count
		
		var hbox = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = "%s x%d" % [ingredient_name, count]
		name_label.custom_minimum_size = Vector2(250, 0)
		hbox.add_child(name_label)
		
		var remove_button = Button.new()
		remove_button.text = "-"
		remove_button.custom_minimum_size = Vector2(40, 40)
		remove_button.pressed.connect(_on_remove_ingredient.bind(ingredient_name))
		hbox.add_child(remove_button)
		
		deck_list_container.add_child(hbox)
	
	# Update count label
	deck_count_label.text = "Total Cards: %d" % total_cards

func _on_add_ingredient(ingredient_name: String):
	if current_deck.has(ingredient_name):
		current_deck[ingredient_name] += 1
	else:
		current_deck[ingredient_name] = 1
	
	print("[DeckEditor] Added %s to deck" % ingredient_name)
	_update_deck_display()

func _on_remove_ingredient(ingredient_name: String):
	if current_deck.has(ingredient_name):
		current_deck[ingredient_name] -= 1
		if current_deck[ingredient_name] <= 0:
			current_deck.erase(ingredient_name)
	
	print("[DeckEditor] Removed %s from deck" % ingredient_name)
	_update_deck_display()

func _on_save_pressed():
	var deck_name = deck_name_input.text.strip_edges()
	
	if deck_name.is_empty():
		print("[DeckEditor] ERROR: Deck name is empty!")
		return
	
	if current_deck.is_empty():
		print("[DeckEditor] ERROR: Cannot save empty deck!")
		return
	
	# Save to data script
	var success = IngredientsData.save_custom_deck(deck_name, current_deck)
	
	if success:
		print("[DeckEditor] Deck '%s' saved successfully" % deck_name)
		deck_saved.emit(deck_name, current_deck)
	else:
		print("[DeckEditor] ERROR: Failed to save deck '%s'" % deck_name)

func _on_load_pressed():
	var deck_name = deck_name_input.text.strip_edges()
	
	if deck_name.is_empty():
		print("[DeckEditor] ERROR: Deck name is empty!")
		return
	
	# Load from data script
	var loaded_deck = IngredientsData.load_custom_deck(deck_name)
	
	if loaded_deck != null:
		current_deck = loaded_deck.duplicate()
		print("[DeckEditor] Deck '%s' loaded successfully" % deck_name)
		_update_deck_display()
		deck_loaded.emit(deck_name, current_deck)
	else:
		print("[DeckEditor] ERROR: Failed to load deck '%s'" % deck_name)

func _on_close_pressed():
	hide()
	editor_closed.emit()

func show_editor():
	show()

func load_deck_from_composition(composition: Dictionary):
	current_deck = composition.duplicate()
	_update_deck_display()
