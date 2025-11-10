extends HBoxContainer

## Displays owned relics as icons with tooltips

var inventory_manager: InventoryManager

func setup(p_inventory: InventoryManager) -> void:
	inventory_manager = p_inventory
	inventory_manager.inventory_updated.connect(_update_relic_display)
	_update_relic_display()

## Update the display of relics
func _update_relic_display() -> void:
	# Clear existing icons
	for child in get_children():
		child.queue_free()
	
	# Create icon for each relic
	var relics = inventory_manager.get_relics()
	for relic in relics:
		var icon = _create_relic_icon(relic)
		add_child(icon)

## Create a single relic icon button
func _create_relic_icon(relic: RelicModel) -> Label:
	var icon = Label.new()
	icon.text = relic.get_symbol()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Set tooltip with relic info
	icon.tooltip_text = "%s\n%s\n%s" % [relic.name, relic.description, relic.get_effect_description()]
	
	# Add background panel for visibility
	icon.add_theme_stylebox_override("normal", _create_icon_style())
	
	# Make larger font
	icon.add_theme_font_size_override("font_size", 24)
	
	return icon

## Create a background style for relic icons
func _create_icon_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	style.border_color = Color(0.8, 0.7, 0.4)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style
