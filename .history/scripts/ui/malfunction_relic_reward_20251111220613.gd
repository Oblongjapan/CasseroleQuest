extends Panel

## Malfunction reward screen - Relic Selection (Overheat reward)

signal relic_selected(relic: RelicModel)

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var relic_container: HBoxContainer = $VBoxContainer/RelicContainer

var offered_relics: Array[RelicModel] = []

func _ready():
	hide()

## Show the relic selection screen with 3 random relics
func show_relic_selection():
	print("[MalfunctionRelicReward] Showing relic selection")
	
	# Clear previous relics
	for child in relic_container.get_children():
		child.queue_free()
	
	offered_relics.clear()
	
	# Generate 3 random relics with rarity logic
	for i in range(3):
		var relic = _get_random_relic_with_rarity()
		offered_relics.append(relic)
		
		# Create button for relic
		var button = Button.new()
		button.custom_minimum_size = Vector2(200, 300)
		button.text = "%s\n\n%s\n\nRarity: %s" % [
			relic.name,
			relic.description,
			_get_rarity_name(relic.rarity)
		]
		button.pressed.connect(_on_relic_selected.bind(relic))
		relic_container.add_child(button)
	
	show()

func _get_random_relic_with_rarity() -> RelicModel:
	# Rarity weights: Common 60%, Uncommon 30%, Rare 8%, Epic 2%
	var roll = randf()
	var rarity: RelicModel.Rarity
	
	if roll < 0.60:
		rarity = RelicModel.Rarity.COMMON
	elif roll < 0.90:
		rarity = RelicModel.Rarity.UNCOMMON
	elif roll < 0.98:
		rarity = RelicModel.Rarity.RARE
	else:
		rarity = RelicModel.Rarity.EPIC
	
	# Get all relics of this rarity
	var all_relics = RelicsData.get_all_relics()
	var matching_relics: Array[RelicModel] = []
	
	for relic in all_relics:
		if relic.rarity == rarity:
			matching_relics.append(relic)
	
	# If no relics of this rarity, fall back to common
	if matching_relics.is_empty():
		for relic in all_relics:
			if relic.rarity == RelicModel.Rarity.COMMON:
				matching_relics.append(relic)
	
	# Return random relic from matching ones
	if matching_relics.is_empty():
		return all_relics[0]  # Fallback to first relic
	
	return matching_relics[randi() % matching_relics.size()]

func _get_rarity_name(rarity: RelicModel.Rarity) -> String:
	match rarity:
		RelicModel.Rarity.COMMON:
			return "Common"
		RelicModel.Rarity.UNCOMMON:
			return "Uncommon"
		RelicModel.Rarity.RARE:
			return "Rare"
		RelicModel.Rarity.EPIC:
			return "Epic"
		_:
			return "Unknown"

func _on_relic_selected(relic: RelicModel):
	print("[MalfunctionRelicReward] Relic selected: %s" % relic.name)
	relic_selected.emit(relic)
	hide()
