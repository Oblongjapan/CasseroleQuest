extends Control

## Pause menu overlay

signal resume_requested
signal restart_requested
signal exit_to_menu_requested

@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var options_button: Button = $Panel/VBoxContainer/OptionsButton
@onready var exit_button: Button = $Panel/VBoxContainer/ExitButton
@onready var options_panel: Panel = $OptionsPanel
@onready var music_slider: HSlider = $OptionsPanel/VBoxContainer/MusicVolume/HSlider
@onready var sfx_slider: HSlider = $OptionsPanel/VBoxContainer/SFXVolume/HSlider
@onready var options_back_button: Button = $OptionsPanel/VBoxContainer/BackButton

func _ready():
	# Connect buttons
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
	if options_back_button:
		options_back_button.pressed.connect(_on_options_back_pressed)
	
	# Connect sliders
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
		# Load saved volume or use default
		var music_volume = _load_setting("music_volume", 0.5)
		music_slider.value = music_volume
		_apply_music_volume(music_volume)
	
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
		# Load saved volume or use default
		var sfx_volume = _load_setting("sfx_volume", 0.7)
		sfx_slider.value = sfx_volume
		_apply_sfx_volume(sfx_volume)
	
	# Hide options panel by default
	if options_panel:
		options_panel.hide()
	
	# Start hidden
	hide()

func show_pause_menu():
	show()
	get_tree().paused = true
	if resume_button:
		resume_button.grab_focus()

func hide_pause_menu():
	hide()
	get_tree().paused = false

func _on_resume_pressed():
	print("[PauseMenu] Resume pressed")
	hide_pause_menu()
	resume_requested.emit()

func _on_restart_pressed():
	print("[PauseMenu] Restart pressed")
	hide_pause_menu()
	restart_requested.emit()

func _on_options_pressed():
	print("[PauseMenu] Options pressed")
	if options_panel:
		options_panel.show()

func _on_exit_pressed():
	print("[PauseMenu] Exit to menu pressed")
	hide_pause_menu()
	exit_to_menu_requested.emit()

func _on_options_back_pressed():
	if options_panel:
		options_panel.hide()

func _on_music_volume_changed(value: float):
	_apply_music_volume(value)
	_save_setting("music_volume", value)

func _on_sfx_volume_changed(value: float):
	_apply_sfx_volume(value)
	_save_setting("sfx_volume", value)

func _apply_music_volume(value: float):
	# Convert 0-1 slider to dB (-80 to 0)
	var db = linear_to_db(value) if value > 0 else -80
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
	print("[PauseMenu] Music volume set to: %.2f (%.1f dB)" % [value, db])

func _apply_sfx_volume(value: float):
	# Convert 0-1 slider to dB (-80 to 0)
	var db = linear_to_db(value) if value > 0 else -80
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	print("[PauseMenu] SFX volume set to: %.2f (%.1f dB)" % [value, db])

func _save_setting(key: String, value: float):
	var config = ConfigFile.new()
	var path = "user://settings.cfg"
	
	# Load existing config
	var err = config.load(path)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		print("[PauseMenu] Error loading config: ", err)
	
	# Set value
	config.set_value("audio", key, value)
	
	# Save
	err = config.save(path)
	if err != OK:
		print("[PauseMenu] Error saving config: ", err)

func _load_setting(key: String, default_value: float) -> float:
	var config = ConfigFile.new()
	var path = "user://settings.cfg"
	
	var err = config.load(path)
	if err == OK:
		return config.get_value("audio", key, default_value)
	return default_value
