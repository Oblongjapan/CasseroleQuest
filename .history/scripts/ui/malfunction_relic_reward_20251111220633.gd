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
	
	# Get all available relics
	var all_relics = RelicsData.get_all_relics()
	
	# Generate 3 random relics
	for i in range(3):
		if all_relics.size() > 0:
			var random_relic = all_relics[randi() % all_relics.size()]
			offered_relics.append(random_relic)
			
			# Create button for relic
			var button = Button.new()
			button.custom_minimum_size = Vector2(200, 300)
			button.text = "%s\n\n%s\n\n%s" % [
				random_relic.name,
				random_relic.description,
				random_relic.get_effect_description()
			]
			button.pressed.connect(_on_relic_selected.bind(random_relic))
			relic_container.add_child(button)
	
	show()

func _on_relic_selected(relic: RelicModel):
	print("[MalfunctionRelicReward] Relic selected: %s" % relic.name)
	relic_selected.emit(relic)
	hide()
