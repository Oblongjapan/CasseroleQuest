extends Label

## UI controller for the timer display

func _ready():
	EventBus.timer_updated.connect(_on_timer_updated)

## Update display when timer changes
func _on_timer_updated(time_remaining: float) -> void:
	# Get formatted time from TimerManager (MM:SS format)
	var total_seconds = int(time_remaining)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	text = "%02d:%02d" % [minutes, seconds]
	
	# Red flash when less than 5 seconds remain
	if time_remaining < 5.0:
		add_theme_color_override("font_color", Color.RED)
	else:
		remove_theme_color_override("font_color")
