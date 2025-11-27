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
func _create_relic_icon(relic: RelicModel) -> PanelContainer:
	# Use PanelContainer for better styling
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(40, 40)
	
	# Create label inside
	var icon = Label.new()
	icon.text = relic.get_symbol()
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 24)
	
	# Set tooltip with relic info
	container.tooltip_text = "%s\n%s\n%s" % [relic.name, relic.description, relic.get_effect_description()]
	
	# Add styled background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.25, 0.9)
	style.border_color = Color(0.8, 0.7, 0.3, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	container.add_theme_stylebox_override("panel", style)
	
	container.add_child(icon)
	return container