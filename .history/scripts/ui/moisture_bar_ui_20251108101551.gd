extends ProgressBar

## UI controller for the moisture bar display

@onready var label: Label = $MoistureLabel

func _ready():
	EventBus.moisture_changed.connect(_on_moisture_changed)
	max_value = 100.0
	value = 100.0

## Update bar and label when moisture changes
func _on_moisture_changed(new_moisture: float) -> void:
	value = new_moisture
	
	# Update label text
	if label:
		label.text = "%d/100" % int(new_moisture)
	
	# Color change based on moisture level
	# Green → Yellow → Red
	if new_moisture > 60:
		modulate = Color.GREEN
	elif new_moisture > 30:
		modulate = Color.YELLOW
	else:
		modulate = Color.RED
