extends Control
class_name IngredientCard

## Individual ingredient card with drag-and-drop functionality

@onready var card_panel: PanelContainer = $CardPanel
@onready var name_label: Label = $CardPanel/VBoxContainer/NameLabel
@onready var upgrade_label: Label = $CardPanel/VBoxContainer/UpgradeLabel
@onready var water_label: Label = $CardPanel/VBoxContainer/StatsContainer/WaterLabel
@onready var resist_label: Label = $CardPanel/VBoxContainer/StatsContainer/ResistLabel
@onready var volatility_label: Label = $CardPanel/VBoxContainer/StatsContainer/VolatilityLabel
@onready var food_sprite: Sprite2D = $CardPanel/VBoxContainer/Food
@onready var status_label: Label = null  # Removed from scene

var ingredient: IngredientModel
var card_style: StyleBoxFlat
var is_selected: bool = false

const CARD_NORMAL_COLOR := Color(0.4, 0.4, 0.5, 1.0)
const CARD_NORMAL_BG := Color(0.15, 0.15, 0.2, 0.95)
const CARD_SELECTED_COLOR := Color(0.3, 1.0, 0.3, 1.0)
const CARD_SELECTED_BG := Color(0.15, 0.25, 0.15, 0.95)

signal card_hovered(card: IngredientCard)
signal card_unhovered(card: IngredientCard)
signal card_input_event(event: InputEvent, card: IngredientCard)

func _ready():
	print("[IngredientCard] _ready() called")
	print("[IngredientCard] card_panel: %s" % card_panel)
	print("[IngredientCard] name_label: %s" % name_label)
	print("[IngredientCard] water_label: %s" % water_label)
	print("[IngredientCard] resist_label: %s" % resist_label)
	print("[IngredientCard] volatility_label: %s" % volatility_label)
	
	# Enforce fixed card size
	custom_minimum_size = Vector2(180, 260)
	size = Vector2(180, 260)
	
	# Get the style from the panel
	if card_panel:
		var theme_style := card_panel.get_theme_stylebox("panel")
		if theme_style:
			# If it's a StyleBoxFlat, duplicate it so each card can have its own modifiable copy
			if theme_style is StyleBoxFlat:
				card_style = (theme_style as StyleBoxFlat).duplicate()
				card_panel.add_theme_stylebox_override("panel", card_style)
				print("[IngredientCard] Using duplicated StyleBoxFlat for card style")
			else:
				# Theme provides a non-flat style (likely a StyleBoxTexture). Preserve it so
				# the texture the designer added in the scene remains visible. In this case
				# we won't override the panel style; instead we'll tint the panel for
				# selection feedback so visuals are preserved.
				card_style = null
				card_panel.modulate = Color(1, 1, 1, 1)
				print("[IngredientCard] Using non-flat theme style; will tint panel for selection")
		
	else:
		print("[IngredientCard] ERROR: card_panel is null!")
	
	# Connect mouse events
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

## Setup card with ingredient data
func setup(ing: IngredientModel, upgrade_desc: String = "") -> void:
	ingredient = ing
	
	print("[IngredientCard] setup() called for: %s" % (ingredient.name if ingredient else "NULL"))
	print("[IngredientCard] name_label: %s" % name_label)
	print("[IngredientCard] water_label: %s" % water_label)
	
	# Set name
	if name_label:
		name_label.text = ingredient.name
		print("[IngredientCard] Set name_label.text to: %s" % name_label.text)
	else:
		print("[IngredientCard] ERROR: name_label is null!")
	
	# Set upgrade description if any
	if upgrade_label:
		if upgrade_desc.is_empty():
			upgrade_label.hide()
		else:
			upgrade_label.text = upgrade_desc
			upgrade_label.modulate = Color.GREEN
			upgrade_label.show()
	
	# Set individual stat labels
	if water_label:
		water_label.text = "Water: %d" % ingredient.water_content
		print("[IngredientCard] Set water_label.text to: %s" % water_label.text)
	else:
		print("[IngredientCard] ERROR: water_label is null!")
	
	if resist_label:
		resist_label.text = "Rst: %d" % ingredient.heat_resistance
		print("[IngredientCard] Set resist_label.text to: %s" % resist_label.text)
	else:
		print("[IngredientCard] ERROR: resist_label is null!")
	
	if volatility_label:
		volatility_label.text = "Vol: %d" % ingredient.volatility
		print("[IngredientCard] Set volatility_label.text to: %s" % volatility_label.text)
	else:
		print("[IngredientCard] ERROR: volatility_label is null!")
	
	# Set food sprite based on ingredient name
	if food_sprite:
		var texture_path = "res://Assets/Food/%s.png" % ingredient.name
		var texture = load(texture_path)
		if texture:
			food_sprite.texture = texture
			print("[IngredientCard] Loaded food texture: %s" % texture_path)
		else:
			print("[IngredientCard] WARNING: Could not load texture at: %s" % texture_path)
	else:
		print("[IngredientCard] WARNING: food_sprite is null!")

## Mark card as selected
func set_selected(selected: bool) -> void:
	is_selected = selected
	# If we have a modifiable StyleBoxFlat, update its colors
	if card_style:
		if selected:
			card_style.border_color = CARD_SELECTED_COLOR
			card_style.bg_color = CARD_SELECTED_BG
		else:
			card_style.border_color = CARD_NORMAL_COLOR
			card_style.bg_color = CARD_NORMAL_BG
	else:
		# Theme used a texture-style box (StyleBoxTexture). Preserve the texture
		# and provide selection feedback by tinting the panel. This avoids losing
		# the designer-added texture while still signaling selection.
		if selected:
			card_panel.modulate = Color(0.9, 1.0, 0.9, 1.0)
		else:
			card_panel.modulate = Color(1, 1, 1, 1)

## Get the card's style for external manipulation
func get_card_style() -> StyleBoxFlat:
	return card_style

func _on_mouse_entered() -> void:
	print("[IngredientCard] Mouse entered: %s" % ingredient.name if ingredient else "no ingredient")
	card_hovered.emit(self)

func _on_mouse_exited() -> void:
	print("[IngredientCard] Mouse exited: %s" % ingredient.name if ingredient else "no ingredient")
	card_unhovered.emit(self)

func _on_gui_input(event: InputEvent) -> void:
	print("[IngredientCard] GUI input: %s on %s" % [event, ingredient.name if ingredient else "no ingredient"])
	card_input_event.emit(event, self)
