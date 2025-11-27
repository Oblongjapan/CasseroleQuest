extends VBoxContainer

## Tutorial page component that can be edited in the editor

@export var screenshot_texture: Texture2D:
	set(value):
		screenshot_texture = value
		if screenshot:
			screenshot.texture = value

@export_multiline var description_text: String = "":
	set(value):
		description_text = value
		if description_label:
			description_label.text = value

@onready var screenshot: TextureRect = $Screenshot
@onready var description_label: Label = $DescriptionLabel

func _ready():
	if screenshot and screenshot_texture:
		screenshot.texture = screenshot_texture
	if description_label and description_text:
		description_label.text = description_text

func set_content(texture: Texture2D, text: String):
	screenshot_texture = texture
	description_text = text
	if screenshot:
		screenshot.texture = texture
	if description_label:
		description_label.text = text
