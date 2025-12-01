extends VBoxContainer

@export var screenshot_texture: Texture2D:
	set(value):
		screenshot_texture = value
		if has_node("Screenshot"):
			$Screenshot.texture = value

@export_multiline var description_text: String:
	set(value):
		description_text = value
		if has_node("DescriptionLabel"):
			$DescriptionLabel.text = value

func _ready():
	if screenshot_texture:
		$Screenshot.texture = screenshot_texture
	if description_text:
		$DescriptionLabel.text = description_text
