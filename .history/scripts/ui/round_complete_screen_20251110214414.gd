extends Panel

## UI screen shown when a round is completed successfully

@onready var moisture_label: Label = $VBoxContainer/MoistureLabel
@onready var currency_earned_label: Label = $VBoxContainer/CurrencyEarnedLabel
@onready var total_currency_label: Label = $VBoxContainer/TotalCurrencyLabel
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var title_label: Label = $VBoxContainer/TitleLabel

var final_moisture: float = 0
var currency_manager: CurrencyManager

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)
	hide()

## Show the round complete screen
func show_complete(moisture_remaining: float, currency_mgr: CurrencyManager) -> void:
	currency_manager = currency_mgr
	final_moisture = int(moisture_remaining)
	
	# Calculate currency earned (remaining moisture)
	var earned = final_moisture
	
	# Update labels
	title_label.text = "✅ ROUND COMPLETE! ✅"
	moisture_label.text = "Moisture Remaining: %d" % final_moisture
	currency_earned_label.text = "Currency Earned: +%d" % earned
	total_currency_label.text = "Total Currency: %d" % currency_manager.get_currency()
	
	show()

## Handle continue button press
func _on_continue_pressed() -> void:
	hide()
	EventBus.shop_opened.emit()
