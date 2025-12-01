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

# For layered ingredient display on recipes
var ingredient_layer_sprites: Array[Sprite2D] = []
var plate_texture: Texture2D = null

# Food sprite hover variables
var hover_timer: Timer = null
var is_hovering_sprite: bool = false
var sprite_expanded: bool = false
var original_sprite_scale: Vector2 = Vector2.ONE
var sprite_area: Control = null

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
	
	print("[IngredientCard] Root Control mouse_filter: %s" % mouse_filter)
	
	# CRITICAL FIX: Make VBoxContainer pass through mouse events so dragging works
	if card_panel:
		print("[IngredientCard] CardPanel mouse_filter: %s" % card_panel.mouse_filter)
		var vbox = card_panel.get_node_or_null("VBoxContainer")
		if vbox:
			print("[IngredientCard] VBoxContainer mouse_filter BEFORE: %s" % vbox.mouse_filter)
			# Don't change it - let it stay as PASS (2) from scene
			print("[IngredientCard] VBoxContainer mouse_filter AFTER: %s (not changed)" % vbox.mouse_filter)
			
			# Check StatsContainer
			var stats_container = vbox.get_node_or_null("StatsContainer")
			if stats_container:
				print("[IngredientCard] StatsContainer mouse_filter: %s" % stats_container.mouse_filter)
			
			# Check all children
			print("[IngredientCard] VBoxContainer children:")
			for child in vbox.get_children():
				print("  - %s: mouse_filter=%s" % [child.name, child.mouse_filter if "mouse_filter" in child else "N/A"])
	
	# CRITICAL: Make sprite ignore mouse input so clicks pass through to card
	if food_sprite:
		food_sprite.set_meta("_edit_lock_", false)  # Ensure it's not locked
		print("[IngredientCard] Food sprite configured - Sprite2D nodes don't block input by default")
	
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
	
	print("[IngredientCard] === MOUSE EVENT CONNECTIONS SET UP ===")
	print("[IngredientCard] Connected to mouse_entered, mouse_exited, gui_input signals")
	
	# Setup hover timer for food sprite
	hover_timer = Timer.new()
	hover_timer.wait_time = 3.0
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_on_hover_timeout)
	add_child(hover_timer)
	
	# Setup hover detection area for food sprite
	_setup_sprite_hover_detection()

## Override _gui_input to catch all input directly
func _gui_input(event: InputEvent) -> void:
	print("[IngredientCard] _gui_input() OVERRIDE called!")
	print("[IngredientCard] Event: %s" % event)
	if event is InputEventMouseButton:
		print("[IngredientCard] MouseButton - button: %s, pressed: %s, position: %s" % [event.button_index, event.pressed, event.position])
	_on_gui_input(event)

## Setup card with ingredient data
func setup(ing: IngredientModel, upgrade_desc: String = "") -> void:
	ingredient = ing
	
	print("[IngredientCard] setup() called for: %s" % (ingredient.name if ingredient else "NULL"))
	print("[IngredientCard] name_label: %s" % name_label)
	print("[IngredientCard] water_label: %s" % water_label)
	
	# Check if ingredient is upgraded
	var is_upgraded = ingredient.get_meta("is_upgraded", false)
	var upgraded_stats: Array = []
	if is_upgraded:
		upgraded_stats = ingredient.get_meta("upgraded_stats", [])
	
	# Apply blue outline for upgraded ingredients
	if is_upgraded and card_style:
		card_style.border_color = Color(0.3, 0.5, 1.0, 1.0)  # Blue
		card_style.border_width_left = 4
		card_style.border_width_right = 4
		card_style.border_width_top = 4
		card_style.border_width_bottom = 4
		print("[IngredientCard] Applied blue outline for upgraded ingredient")
		
		# Start sparkle animation
		_play_sparkle_animation()
	
	# Set name
	if name_label:
		# Check if there's a display name (for recipes with friendly names)
		var display_name = ingredient.get_meta("display_name", "")
		print("[IngredientCard] Ingredient internal name: '%s'" % ingredient.name)
		print("[IngredientCard] Display name from metadata: '%s'" % display_name)
		if display_name.is_empty():
			name_label.text = ingredient.name
			print("[IngredientCard] Using internal name")
		else:
			name_label.text = display_name
			print("[IngredientCard] Using display name")
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
	
	# Set individual stat labels with stars for upgraded stats
	if water_label:
		var star = " ⭐" if "water" in upgraded_stats else ""
		# Add star for organic upgrade
		var organic_star = " ⭐" if ingredient.get_meta("upgraded_stat", "") == "water" else ""
		water_label.text = "WATER: %d%s%s" % [ingredient.water_content, star, organic_star]
		print("[IngredientCard] Set water_label.text to: %s" % water_label.text)
	else:
		print("[IngredientCard] ERROR: water_label is null!")
	
	if resist_label:
		var star = " ⭐" if "heat_resistance" in upgraded_stats else ""
		# Add star for organic upgrade
		var organic_star = " ⭐" if ingredient.get_meta("upgraded_stat", "") == "heat_resistance" else ""
		var buff_indicator = ""
		
		# Check if this ingredient has heat buff from relic (like Plastic Wrap)
		if ingredient.get_meta("has_heat_buff", false):
			var buff_amount = ingredient.get_meta("heat_buff_amount", 0)
			buff_indicator = " 🔥(+%d)" % buff_amount
		
		resist_label.text = "RST: %d%s%s%s" % [ingredient.heat_resistance, star, organic_star, buff_indicator]
		print("[IngredientCard] Set resist_label.text to: %s" % resist_label.text)
	else:
		print("[IngredientCard] ERROR: resist_label is null!")
	
	if volatility_label:
		var star = " ⭐" if "volatility" in upgraded_stats else ""
		# Add star for organic upgrade
		var organic_star = " ⭐" if ingredient.get_meta("upgraded_stat", "") == "volatility" else ""
		volatility_label.text = "VOL: %d%s%s" % [ingredient.volatility, star, organic_star]
		print("[IngredientCard] Set volatility_label.text to: %s" % volatility_label.text)
	else:
		print("[IngredientCard] ERROR: volatility_label is null!")
	
	# Set food sprite based on ingredient name
	if food_sprite:
		# Always load plate texture if not already loaded
		if not plate_texture:
			plate_texture = load("res://Assets/Food/Plate.png")
		
		# Check if this is a combo recipe (contains "+")
		if "+" in ingredient.name:
			# This is a dynamic recipe - show plate with layered ingredients
			_setup_layered_food_display(ingredient.name)
		else:
			# Single ingredient - show plate with food on top
			_setup_single_food_with_plate(ingredient.name)
	else:
		print("[IngredientCard] WARNING: food_sprite is null!")

	# Set tooltip for recipes to show ingredients
	if "+" in ingredient.name:
		var ingredients_list = ingredient.name.split("+")
		var tooltip = "Ingredients:\n"
		for ing_name in ingredients_list:
			tooltip += "• " + ing_name.strip_edges() + "\n"
		tooltip_text = tooltip.strip_edges()
		print("[IngredientCard] Set tooltip for recipe: %s" % tooltip_text)
	else:
		tooltip_text = "" # No tooltip for single ingredients

## Setup single ingredient with plate
func _setup_single_food_with_plate(ingredient_name: String) -> void:
	print("[IngredientCard] Setting up single ingredient with plate: %s" % ingredient_name)
	
	# Set plate as base layer
	if plate_texture:
		food_sprite.texture = plate_texture
		food_sprite.z_index = 0
		# Scale down plate by 10px (assuming plate is approximately 100px, scale to 0.9)
		var plate_size = plate_texture.get_size()
		var scale_factor = (plate_size.x - 20.0) / plate_size.x
		food_sprite.scale = Vector2(scale_factor, scale_factor)
		print("[IngredientCard] Set plate as base texture with scale: %s" % food_sprite.scale)
	
	# Clear any existing ingredient layers
	for layer in ingredient_layer_sprites:
		if is_instance_valid(layer):
			layer.queue_free()
	ingredient_layer_sprites.clear()
	
	# Strip "Organic " prefix to get base ingredient name for texture
	var base_name = ingredient_name.replace("Organic ", "")
	
	# Map recipe names to actual PNG filenames
	var recipe_name_map = {
		"Chicken+Rice": "Chicken and RIce",
		"Steak+Potato": "Steak and Potato"
	}
	
	if recipe_name_map.has(base_name):
		base_name = recipe_name_map[base_name]
	
	var texture_path = "res://Assets/Food/%s.png" % base_name
	var texture = load(texture_path)
	if texture:
		var food_layer = Sprite2D.new()
		food_layer.texture = texture
		food_layer.position = Vector2.ZERO  # Centered on plate
		food_layer.z_index = 1  # On top of plate
		food_sprite.add_child(food_layer)
		ingredient_layer_sprites.append(food_layer)
		print("[IngredientCard] Added food on plate: %s" % texture_path)
	else:
		print("[IngredientCard] WARNING: Could not load texture at: %s" % texture_path)

## Setup layered food display for combo recipes
func _setup_layered_food_display(recipe_name: String) -> void:
	print("[IngredientCard] Setting up layered display for: %s" % recipe_name)
	
	# Set plate as base layer
	if plate_texture:
		food_sprite.texture = plate_texture
		food_sprite.z_index = 0
		# Scale down plate by 10px (assuming plate is approximately 100px, scale to 0.9)
		var plate_size = plate_texture.get_size()
		var scale_factor = (plate_size.x - 20.0) / plate_size.x
		food_sprite.scale = Vector2(scale_factor, scale_factor)
		print("[IngredientCard] Set plate as base texture with scale: %s" % food_sprite.scale)
	
	# Clear any existing ingredient layers
	for layer in ingredient_layer_sprites:
		if is_instance_valid(layer):
			layer.queue_free()
	ingredient_layer_sprites.clear()
	
	# Parse ingredient names from recipe (e.g., "Rice+Bread" -> ["Rice", "Bread"])
	var ingredient_names = recipe_name.split("+")
	print("[IngredientCard] Combo has %d ingredients: %s" % [ingredient_names.size(), ingredient_names])
	
	# Calculate offset for multiple ingredients
	var num_ingredients = min(ingredient_names.size(), 3)  # Support up to 3 ingredients
	var offset_amount = 15.0  # Pixels to offset each ingredient
	
	# Create a sprite for each ingredient and layer them on the plate with offset
	for i in range(num_ingredients):
		var ing_name = ingredient_names[i].strip_edges()
		
		# Load the ingredient texture
		var texture_path = "res://Assets/Food/%s.png" % ing_name
		var texture = load(texture_path)
		
		if texture:
			var layer_sprite = Sprite2D.new()
			layer_sprite.texture = texture
			
			# Offset ingredients to the side so they don't all stack in center
			if num_ingredients == 1:
				layer_sprite.position = Vector2.ZERO  # Single ingredient stays centered
			elif num_ingredients == 2:
				# Two ingredients: offset left and right
				var x_offset = (i - 0.5) * offset_amount
				layer_sprite.position = Vector2(x_offset, 0)
			else:
				# Three+ ingredients: spread them out
				var x_offset = (i - 1.0) * offset_amount
				layer_sprite.position = Vector2(x_offset, 0)
			
			layer_sprite.z_index = i + 1  # Layer on top of plate
			layer_sprite.scale = Vector2(0.9, 0.9)  # Slightly smaller for multi-ingredient
			food_sprite.add_child(layer_sprite)
			ingredient_layer_sprites.append(layer_sprite)
			print("[IngredientCard] Added layer %d: %s at offset %s" % [i, ing_name, layer_sprite.position])
		else:
			print("[IngredientCard] WARNING: Could not load ingredient texture: %s" % texture_path)

## Play sparkle animation for upgraded ingredients
func _play_sparkle_animation() -> void:
	if not card_panel:
		return
	
	# Create a pulsing glow effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(card_panel, "modulate", Color(1.2, 1.2, 1.4, 1.0), 0.8)
	tween.tween_property(card_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8)
	print("[IngredientCard] Started sparkle animation")

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
	print("[IngredientCard] Mouse entered: %s" % (ingredient.name if ingredient else "no ingredient"))
	card_hovered.emit(self)

func _on_mouse_exited() -> void:
	print("[IngredientCard] Mouse exited: %s" % (ingredient.name if ingredient else "no ingredient"))
	card_unhovered.emit(self)

func _on_gui_input(event: InputEvent) -> void:
	print("[IngredientCard] ===== GUI INPUT RECEIVED =====")
	print("[IngredientCard] Event type: %s" % event.get_class())
	print("[IngredientCard] Ingredient: %s" % (ingredient.name if ingredient else "no ingredient"))
	if event is InputEventMouseButton:
		print("[IngredientCard] Mouse button: %s, pressed: %s" % [event.button_index, event.pressed])
	card_input_event.emit(event, self)

## Setup hover detection for the food sprite
func _setup_sprite_hover_detection() -> void:
	if not food_sprite:
		return
	
	# Store original scale
	original_sprite_scale = food_sprite.scale
	
	# Don't create sprite_area Control - it interferes with drag detection
	# Instead, we'll detect sprite hover in _process by checking mouse position
	# This allows clicks to properly pass through to the parent card

## Called when mouse enters the food sprite area
func _on_sprite_mouse_entered() -> void:
	is_hovering_sprite = true
	hover_timer.start()
	print("[IngredientCard] Mouse entered sprite, starting 3s timer")

## Called when mouse exits the food sprite area
func _on_sprite_mouse_exited() -> void:
	is_hovering_sprite = false
	hover_timer.stop()
	
	# Shrink sprite back if expanded
	if sprite_expanded:
		_shrink_sprite()
	print("[IngredientCard] Mouse exited sprite")

## Called when hover timer times out (3 seconds elapsed)
func _on_hover_timeout() -> void:
	if is_hovering_sprite and not sprite_expanded:
		_expand_sprite()

## Expand the sprite to 6x size
func _expand_sprite() -> void:
	if not food_sprite:
		return
	
	sprite_expanded = true
	var target_scale = original_sprite_scale * 6.0
	
	# Animate the expansion
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(food_sprite, "scale", target_scale, 0.3)
	
	# Bring to front
	food_sprite.z_index = 100
	print("[IngredientCard] Sprite expanded to 6x")

## Shrink the sprite back to original size
func _shrink_sprite() -> void:
	if not food_sprite:
		return
	
	sprite_expanded = false
	
	# Animate the shrink
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(food_sprite, "scale", original_sprite_scale, 0.3)
	
	# Reset z-index
	food_sprite.z_index = 0
	print("[IngredientCard] Sprite shrunk back to normal")
