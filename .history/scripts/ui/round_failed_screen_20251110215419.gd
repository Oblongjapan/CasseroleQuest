extends Panel

## UI screen shown when a round fails (moisture reaches 0)

@onready var moisture_label: Label = $VBoxContainer/MoistureLabel
@onready var time_label: Label = $VBoxContainer/TimeLabel
@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var retry_button: Button = $VBoxContainer/ButtonsContainer/RetryButton
@onready var menu_button: Button = $VBoxContainer/ButtonsContainer/MenuButton
@onready var title_label: Label = $VBoxContainer/TitleLabel

var failed_time: float = 0
var starting_moisture: float = 0

signal retry_requested()
signal return_to_menu_requested()

func _ready():
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	hide()

## Show the round failed screen
func show_failed(final_moisture: float, time_remaining: float, max_moisture: float) -> void:
	failed_time = 15.0 - time_remaining
	starting_moisture = max_moisture
	
	# Update labels
	title_label.text = "❌ ROUND FAILED ❌"
	moisture_label.text = "Moisture Reached: %d / %d" % [int(final_moisture), int(starting_moisture)]
	time_label.text = "Failed at: %.1f seconds\nTime Remaining: %.1f seconds" % [failed_time, time_remaining]
	message_label.text = "You didn't manage the drain in time!\nTry again or visit the shop for help."
	
	show()

## Handle retry button press
func _on_retry_pressed() -> void:
	hide()
	retry_requested.emit()

## Handle return to menu button press
func _on_menu_pressed() -> void:
	hide()
	return_to_menu_requested.emit()
