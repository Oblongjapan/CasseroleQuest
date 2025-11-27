extends ProgressBar

## UI controller for the moisture bar display

@onready var label: Label = $MoistureLabel

func _ready():
	EventBus.moisture_changed.connect(_on_moisture_changed)
	max_value = 100.0
	value = 100.0
	print("[MoistureBarUI] Ready and connected to moisture_changed signal")

## Update bar and label when moisture changes
func _on_moisture_changed(current_moisture: float, max_m: float, bonus_m: float) -> void:
	# Debug every 60 frames
	if Engine.get_process_frames() % 60 == 0:
		print("[MoistureBarUI] Received moisture_changed: current=%.1f, max=%.1f, bonus=%.1f" % [current_moisture, max_m, bonus_m])
	
	# Update progress bar bounds and value
	max_value = max_m if max_m > 0 else 1.0
	value = current_moisture

	# Build label text: "current / max (+bonus)"
	if label:
		var bonus_text = ""
		if bonus_m > 0:
			bonus_text = " (+%d)" % int(bonus_m)
		label.text = "%d/%d%s" % [int(current_moisture), int(max_m), bonus_text]

	# Color change based on percentage of max (Green → Yellow → Red)
	var pct = 0.0
	if max_value > 0:
		pct = (current_moisture / max_value) * 100.0

	if pct > 60:
		modulate = Color.GREEN
	elif pct > 30:
		modulate = Color.YELLOW
	else:
		modulate = Color.RED
