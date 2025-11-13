extends Panel

## Malfunction reward screen - Action Item Selection + Compost (Macrowave reward)

signal reward_completed(selected_item: ActiveItem, composted_ingredient: IngredientModel)

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var action_items_container: HBoxContainer = $VBoxContainer/ActionItemsContainer
@onready var compost_section: VBoxContainer = $VBoxContainer/CompostSection
@onready var compost_container: HBoxContainer = $VBoxContainer/CompostSection/CompostContainer
@onready var confirm_button: Button = $VBoxContainer/ConfirmButton

var offered_items: Array[ActiveItem] = []
var hand_ingredients: Array[IngredientModel] = []
var selected_item: ActiveItem = null
var selected_compost: IngredientModel = null

func _ready():
	hide()
	confirm_button.pressed.connect(_on_confirm_pressed)
	confirm_button.disabled = true

## Show the action item + compost selection screen
func show_macrowave_reward(hand: Array[IngredientModel]):
	print("[MalfunctionMacrowaveReward] Showing reward screen")
	
	hand_ingredients = hand
	selected_item = null
	selected_compost = null
	confirm_button.disabled = true
	
	# Clear previous UI
	for child in action_items_container.get_children():
		child.queue_free()
	for child in compost_container.get_children():
		child.queue_free()
	
	offered_items.clear()
	
	# Generate 3 random action items
	var all_items = ActiveItemsData.get_all_items()
	for i in range(3):
		if all_items.size() > 0:
			var random_item = all_items[randi() % all_items.size()]
			offered_items.append(random_item)
			
			# Create button for action item
			var button = Button.new()
			button.custom_minimum_size = Vector2(200, 200)
			button.text = "%s\n\n%s\n\nCooldown: %ds" % [
				random_item.name,
				random_item.description,
				random_item.cooldown_duration
			]
			button.toggle_mode = true
			button.pressed.connect(_on_item_selected.bind(random_item, button))
			action_items_container.add_child(button)
	
	# Create compost buttons for hand
	for ingredient in hand_ingredients:
		var button = Button.new()
		button.custom_minimum_size = Vector2(150, 150)
		button.text = "%s\n\nW:%d R:%d V:%d" % [
			ingredient.name,
			ingredient.water_content,
			ingredient.heat_resistance,
			ingredient.volatility
		]
		button.toggle_mode = true
		button.pressed.connect(_on_compost_selected.bind(ingredient, button))
		compost_container.add_child(button)
	
	show()

func _on_item_selected(item: ActiveItem, button: Button):
	# Deselect other action item buttons
	for child in action_items_container.get_children():
		if child != button and child is Button:
			child.button_pressed = false
	
	if button.button_pressed:
		selected_item = item
		print("[MalfunctionMacrowaveReward] Item selected: %s" % item.name)
	else:
		selected_item = null
	
	_update_confirm_button()

func _on_compost_selected(ingredient: IngredientModel, button: Button):
	# Deselect other compost buttons
	for child in compost_container.get_children():
		if child != button and child is Button:
			child.button_pressed = false
	
	if button.button_pressed:
		selected_compost = ingredient
		print("[MalfunctionMacrowaveReward] Compost selected: %s" % ingredient.name)
	else:
		selected_compost = null
	
	_update_confirm_button()

func _update_confirm_button():
	# Enable confirm only if both selections made
	confirm_button.disabled = (selected_item == null or selected_compost == null)

func _on_confirm_pressed():
	if selected_item and selected_compost:
		print("[MalfunctionMacrowaveReward] Confirmed - Item: %s, Compost: %s" % [selected_item.name, selected_compost.name])
		reward_completed.emit(selected_item, selected_compost)
		hide()
