extends Sprite2D

## Draggable ingredient overlay in the microwave
## Can be dragged out to deselect

signal drag_out_requested(overlay_index: int)

var overlay_index: int = 0  # 0 or 1
var is_dragging: bool = false
var drag_start_pos: Vector2
var original_position: Vector2

func _ready():
	original_position = position

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
						print("[IngredientOverlay] Dragged out overlay %d, requesting deselection" % overlay_index)
						drag_out_requested.emit(overlay_index)
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
