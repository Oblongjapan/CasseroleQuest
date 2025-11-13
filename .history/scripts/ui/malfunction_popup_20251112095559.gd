extends Control

## Malfunction popup that fades in, displays, then shrinks to top-left corner

signal popup_completed

@onready var label: Label = $Panel/VBoxContainer/MalfunctionLabel
@onready var description_label: Label = $Panel/VBoxContainer/DescriptionLabel
@onready var panel: Panel = $Panel

const FADE_DURATION: float = 0.5
const DISPLAY_DURATION: float = 2.0
const SHRINK_DURATION: float = 0.5

var original_position: Vector2
var original_scale: Vector2

func _ready():
	hide()
	modulate.a = 0.0
	original_scale = scale

## Show the malfunction popup with animation
func show_malfunction(malfunction: MalfunctionModel):
	print("[MalfunctionPopup] Showing malfunction: %s" % malfunction.name)
	
	# Set text (description in all caps)
	label.text = "MALFUNCTION:\n%s" % malfunction.name.to_upper()
	description_label.text = malfunction.description.to_upper()
	
	# Reset to center position and full scale
	position = Vector2.ZERO
	scale = original_scale
	
	# Store original position
	original_position = position
	
	# Show and start animation
	show()
	modulate.a = 0.0
	get_tree().paused = true  # Pause the game during popup
	
	# Fade in
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished
	
	# Hold
	await get_tree().create_timer(DISPLAY_DURATION, true, false, true).timeout
	
	# Shrink and move to top-left instead of fading out
	tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(0.6, 0.6), SHRINK_DURATION)
	tween.tween_property(panel, "position", Vector2(335, 72), SHRINK_DURATION)
	await tween.finished
	
	# Unpause game but keep popup visible
	get_tree().paused = false
	
	print("[MalfunctionPopup] Popup moved to corner - will stay until round end")
	popup_completed.emit()

## Reset popup to original state (call at round end)
func reset_popup():
	hide()
	modulate.a = 0.0
	if panel:
		panel.scale = Vector2.ONE
		panel.position = Vector2.ZERO
