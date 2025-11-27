extends Panel

## Main menu screen

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var tagline_label: Label = $VBoxContainer/TaglineLabel

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	title_label.text = "MICROWAVE WAVE"
	tagline_label.text = "A Microwave's Thirst"

## Handle start game button
func _on_start_pressed() -> void:
	print("[MainMenu] Starting game...")
	hide()
	EventBus.game_started.emit()

## Handle quit button
func _on_quit_pressed() -> void:
	print("[MainMenu] Quitting game...")
	get_tree().quit()
