extends Panel

## Main menu screen

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var tagline_label: Label = $VBoxContainer/TaglineLabel

func _ready():
	print("[MainMenu] _ready() called")
	print("[MainMenu] start_button: ", start_button)
	print("[MainMenu] quit_button: ", quit_button)
	
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	title_label.text = "MICRORAGE"
	tagline_label.text = "REHEATED FURY"
	
	print("[MainMenu] Ready complete")

## Handle start game button
func _on_start_pressed() -> void:
	print("[MainMenu] ========================================")
	print("[MainMenu] START BUTTON PRESSED!")
	print("[MainMenu] ========================================")
	print("[MainMenu] About to hide and emit game_started...")
	hide()
	print("[MainMenu] Hidden, now emitting signal...")
	EventBus.game_started.emit()
	print("[MainMenu] Signal emitted")

## Handle quit button
func _on_quit_pressed() -> void:
	print("[MainMenu] Quitting game...")
	get_tree().quit()
