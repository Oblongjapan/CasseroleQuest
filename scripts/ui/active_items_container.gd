extends VBoxContainer

## Dynamic container that creates/updates active item buttons based on inventory

var button_scene = preload("res://scripts/ui/active_item_button_ui.gd")
var item_buttons: Array[Button] = []

func _ready():
	EventBus.round_started.connect(_on_round_started)

## Update buttons when items change
func update_buttons(items: Array[ActiveItem]) -> void:
	# Clear existing buttons
	for button in item_buttons:
		button.queue_free()
	item_buttons.clear()
	
	# Create new buttons for each item
	for i in range(items.size()):
		var button = Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = items[i].name
		button.tooltip_text = items[i].description
		button.set_script(button_scene)
		button.item_index = i
		button.item = items[i]
		
		add_child(button)
		item_buttons.append(button)
		
		# Connect button pressed signal
		button.pressed.connect(_on_item_button_pressed.bind(i))

func _on_item_button_pressed(index: int) -> void:
	var main = get_tree().root.get_node_or_null("Main")
	if main and main.has_method("try_use_item"):
		main.try_use_item(index)

func _on_round_started(_ing1, _ing2) -> void:
	# Refresh button states at round start
	for button in item_buttons:
		if button.has_method("_ready"):
			button._ready()
