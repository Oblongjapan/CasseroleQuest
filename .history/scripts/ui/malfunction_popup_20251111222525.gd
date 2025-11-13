extends Control

## Malfunction popup that fades in, displays, and fades out

signal popup_completed

@onready var label: Label = $Panel/VBoxContainer/MalfunctionLabel
@onready var description_label: Label = $Panel/VBoxContainer/DescriptionLabel
@onready var panel: Panel = $Panel

const FADE_DURATION: float = 0.5
const DISPLAY_DURATION: float = 2.0

func _ready():
	hide()
	modulate.a = 0.0

## Show the malfunction popup with animation
func show_malfunction(malfunction: MalfunctionModel):
	print("[MalfunctionPopup] Showing malfunction: %s" % malfunction.name)
	
	# Set text
	label.text = "MALFUNCTION:\n%s" % malfunction.name.to_upper()
	description_label.text = malfunction.description
	
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
	
	# Fade out
	tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	await tween.finished
	
	# Hide and unpause
	hide()
	get_tree().paused = false
	
	print("[MalfunctionPopup] Popup animation complete")
	popup_completed.emit()
