extends Panel

## Game Over screen shown when player loses (moisture reaches 0)

@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var message_label: Label = $VBoxContainer/MessageLabel

signal restart_requested
signal quit_requested

func _ready():
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	hide()

func show_game_over(round_number: int) -> void:
	if title_label:
		title_label.text = "GAME OVER"
	
	if message_label:
		message_label.text = "You ran out of moisture on Round %d!\n\nBetter luck next time!" % round_number
	
	show()

func _on_restart_pressed() -> void:
	restart_requested.emit()
	hide()

func _on_quit_pressed() -> void:
	quit_requested.emit()
	hide()
