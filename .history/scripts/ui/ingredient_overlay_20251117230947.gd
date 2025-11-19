extends Sprite2D

## Draggable ingredient overlay in the microwave
## Shows a plate with food items layered on top

signal drag_out_requested(ingredient_name: String)

var overlay_index: int = 0  # 0 or 1 - which physical sprite this is
var current_ingredient_name: String = ""  # Which ingredient is currently displayed
var is_dragging: bool = false
var drag_start_pos: Vector2
var original_position: Vector2

# Array to hold multiple food layer sprites for combo recipes
var food_layer_sprites: Array[Sprite2D] = []

# Plate texture (loaded once)
var plate_texture: Texture2D = null

func _ready():
	original_position = position
	
	# Load the plate texture
	plate_texture = load("res://Assets/Food/Plate.png")
	if not plate_texture:
		print("[IngredientOverlay] ERROR: Could not load Plate.png!")
	
	print("[IngredientOverlay] Overlay %d initialized with plate" % overlay_index)

func _input(event: InputEvent):
	# Early exit if not visible or no texture
	if not visible or not texture:
		is_dragging = false  # Reset drag state if becoming invalid
		return
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				# Check if mouse is over this sprite
				var local_mouse_pos = get_local_mouse_position()
				var rect = Rect2(-texture.get_size() * scale / 2, texture.get_size() * scale)
				if rect.has_point(local_mouse_pos):
					is_dragging = true
					drag_start_pos = get_global_mouse_position()
					print("[IngredientOverlay] Started dragging overlay %d" % overlay_index)
			else:
				if is_dragging:
					is_dragging = false
					# Check if dragged far enough from microwave to deselect
					var drag_distance = global_position.distance_to(original_position + get_parent().global_position)
					if drag_distance > 100:  # Threshold for deselection
						print("[IngredientOverlay] Dragged out overlay %d, requesting deselection of: %s" % [overlay_index, current_ingredient_name])
						drag_out_requested.emit(current_ingredient_name)
					else:
						# Return to original position
						print("[IngredientOverlay] Drag too short, snapping back overlay %d" % overlay_index)
						var tween = create_tween()
						tween.tween_property(self, "position", original_position, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	elif event is InputEventMouseMotion and is_dragging:
		var mouse_motion = event as InputEventMouseMotion
		position += mouse_motion.relative / get_parent().scale

func reset_position():
	position = original_position

## Set which ingredient this overlay is displaying
## Can handle both single ingredients and combo recipes with multiple layers
func set_ingredient(ingredient_name: String, ingredient_textures: Array):
	print("[IngredientOverlay] set_ingredient called for overlay %d" % overlay_index)
	print("[IngredientOverlay]   ingredient_name: %s" % ingredient_name)
	print("[IngredientOverlay]   Number of textures: %d" % ingredient_textures.size())
	
	current_ingredient_name = ingredient_name
	
	# Clear any existing food layer sprites
	for layer in food_layer_sprites:
		layer.queue_free()
	food_layer_sprites.clear()
	
	# Set the plate as the base texture
	texture = plate_texture
	print("[IngredientOverlay]   Set base texture to plate")
	
	# Add all ingredient textures as layers on top of the plate
	for i in range(ingredient_textures.size()):
		var layer_texture = ingredient_textures[i]
		if layer_texture:
			var layer_sprite = Sprite2D.new()
			layer_sprite.texture = layer_texture
			layer_sprite.position = Vector2.ZERO  # Centered on the plate
			add_child(layer_sprite)
			food_layer_sprites.append(layer_sprite)
			print("[IngredientOverlay]   Added layer %d" % i)
		else:
			print("[IngredientOverlay]   WARNING: Layer %d texture is null" % i)
	
	show()
	print("[IngredientOverlay] Overlay %d now visible with %d layers" % [overlay_index, food_layer_sprites.size()])

## Clear the overlay completely - called when ingredient is deselected
func clear_overlay():
	is_dragging = false
	current_ingredient_name = ""
	texture = null
	
	# Clear all food layer sprites
	for layer in food_layer_sprites:
		layer.queue_free()
	food_layer_sprites.clear()
	
	hide()
	reset_position()
	print("[IngredientOverlay] Cleared overlay %d" % overlay_index)
