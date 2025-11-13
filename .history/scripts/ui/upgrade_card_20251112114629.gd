extends PanelContainer
class_name UpgradeCard

## UI component for displaying and purchasing upgrades in the shop

signal upgrade_purchased(upgrade_data: Dictionary)

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var rarity_label: Label = $VBoxContainer/RarityLabel
@onready var cost_label: Label = $VBoxContainer/CostLabel
@onready var purchase_button: Button = $VBoxContainer/PurchaseButton

var upgrade_data: Dictionary = {}
var is_purchased: bool = false

func _ready():
	if purchase_button:
		purchase_button.pressed.connect(_on_purchase_pressed)

## Setup the upgrade card with data
func setup(data: Dictionary) -> void:
	upgrade_data = data
	
	if name_label:
		name_label.text = data.get("name", "Unknown")
	
	if description_label:
		description_label.text = data.get("description", "")
	
	if rarity_label:
		var rarity = data.get("rarity", "common")
		rarity_label.text = rarity.capitalize()
		
		# Color code by rarity
		match rarity:
			"common":
				rarity_label.modulate = Color.WHITE
			"rare":
				rarity_label.modulate = Color(0.3, 0.5, 1.0)  # Blue
			"epic":
				rarity_label.modulate = Color(0.7, 0.2, 1.0)  # Purple
	
	if cost_label:
		cost_label.text = "Cost: %d" % data.get("cost", 0)
	
	# Reset purchased state
	is_purchased = false
	_update_button_state()

## Handle purchase button press
func _on_purchase_pressed() -> void:
	if not is_purchased:
		upgrade_purchased.emit(upgrade_data)

## Mark this upgrade as purchased (called from shop)
func mark_as_purchased() -> void:
	is_purchased = true
	_update_button_state()

## Update button appearance based on purchase state
func _update_button_state() -> void:
	if purchase_button:
		if is_purchased:
			purchase_button.text = "SOLD"
			purchase_button.disabled = true
			modulate = Color(0.6, 0.6, 0.6)  # Gray out the whole card
		else:
			purchase_button.text = "Purchase"
			purchase_button.disabled = false
			modulate = Color.WHITE

## Check if can afford (called from shop to enable/disable)
func set_affordable(can_afford: bool) -> void:
	if purchase_button and not is_purchased:
		purchase_button.disabled = not can_afford
		if not can_afford:
			cost_label.modulate = Color.RED
		else:
			cost_label.modulate = Color(0.513726, 0.980392, 0.552941, 1)
