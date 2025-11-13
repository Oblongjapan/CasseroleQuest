extends Panel

## Malfunction reward screen - Relic Selection (Overheat reward)

signal relic_selected(relic: RelicModel)

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var relic_container: HBoxContainer = $VBoxContainer/RelicContainer

var offered_relics: Array[RelicModel] = []
var inventory_manager: InventoryManager = null

func _ready():
	hide()

## Show the relic selection screen with 3 random relics
func show_relic_selection(inventory_mgr: InventoryManager):
	print("[MalfunctionRelicReward] Showing relic selection")
	inventory_manager = inventory_mgr
	
	# Clear previous relics
	for child in relic_container.get_children():
		child.queue_free()
	
	offered_relics.clear()
	
	# Get all available relics
	var all_relics = RelicsData.get_all_relics()
	var owned_relics = inventory_manager.get_owned_relic_names()
	
	# Filter out already-owned relics
	var available_relics: Array[RelicModel] = []
	for relic in all_relics:
		if not inventory_manager.has_relic(relic.name):
			available_relics.append(relic)
	
	# Decide if clone relic should appear (20% chance if player has relics)
	var should_offer_clone = owned_relics.size() > 0 and randf() < 0.20
	
	# Generate 3 random relics
	var slots_filled = 0
	
	# Add clone relic first if applicable
	if should_offer_clone:
		var clone_relic = _create_clone_relic_option()
		if clone_relic:
			offered_relics.append(clone_relic)
			_create_relic_button(clone_relic, true)
			slots_filled += 1
	
	# Fill remaining slots with available relics
	available_relics.shuffle()
	var relic_index = 0
	while slots_filled < 3 and relic_index < available_relics.size():
		var relic = available_relics[relic_index]
		offered_relics.append(relic)
		_create_relic_button(relic, false)
		slots_filled += 1
		relic_index += 1
	
	# If we can't fill all 3 slots (all relics owned), add "skip" option
	if slots_filled == 0:
		var skip_label = Label.new()
		skip_label.text = "No new relics available!\n\nClose to continue"
		skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		skip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		relic_container.add_child(skip_label)
	
	show()

## Create a clone relic option
func _create_clone_relic_option() -> RelicModel:
	var owned_relics = inventory_manager.get_relics()
	if owned_relics.size() == 0:
		return null
	
	# Pick a random owned relic to clone
	var relic_to_clone = owned_relics[randi() % owned_relics.size()]
	
	# Create a clone relic
	var clone_relic = RelicModel.new(
		"Clone: %s" % relic_to_clone.name,
		"[CLONE] %s" % relic_to_clone.description,
		relic_to_clone.effect_type,
		relic_to_clone.effect_value
	)
	
	return clone_relic

## Create a button for a relic
func _create_relic_button(relic: RelicModel, is_clone: bool):
	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 300)
	
	var button_text = ""
	if is_clone:
		button_text = "[CLONE]\n%s\n\n%s\n\n%s" % [
			relic.name,
			relic.description,
			relic.get_effect_description()
		]
	else:
		button_text = "%s\n\n%s\n\n%s" % [
			relic.name,
			relic.description,
			relic.get_effect_description()
		]
	
	button.text = button_text
	button.pressed.connect(_on_relic_selected.bind(relic))
	relic_container.add_child(button)

func _on_relic_selected(relic: RelicModel):
	print("[MalfunctionRelicReward] Relic selected: %s" % relic.name)
	relic_selected.emit(relic)
	hide()
