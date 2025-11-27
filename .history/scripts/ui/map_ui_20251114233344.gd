extends Panel

## UI for displaying and interacting with the progression map

signal node_clicked(node: MapNodeModel)

@onready var map_container: VBoxContainer = $ScrollContainer/MapContainer

var map_manager: MapManager = null
var node_buttons: Dictionary = {}  # MapNodeModel -> Button

func _ready():
	hide()

## Setup and display the map
func show_map(p_map_manager: MapManager) -> void:
	map_manager = p_map_manager
	_build_map_ui()
	show()

## Build the visual representation of the map
func _build_map_ui() -> void:
	# Clear existing UI
	for child in map_container.get_children():
		child.queue_free()
	node_buttons.clear()
	
	if not map_manager:
		return
	
	# Create a row for each tier (bottom to top)
	for tier in range(map_manager.map_nodes.size() - 1, -1, -1):
		var tier_nodes = map_manager.get_tier_nodes(tier)
		
		# Create tier container
		var tier_row = HBoxContainer.new()
		tier_row.alignment = BoxContainer.ALIGNMENT_CENTER
		tier_row.add_theme_constant_override("separation", 20)
		
		# Add tier label
		var tier_label = Label.new()
		tier_label.text = "Tier %d" % (tier + 1)
		tier_label.add_theme_font_size_override("font_size", 16)
		tier_label.custom_minimum_size = Vector2(60, 0)
		tier_row.add_child(tier_label)
		
		# Add nodes for this tier
		for node in tier_nodes:
			var node_button = Button.new()
			node_button.custom_minimum_size = Vector2(120, 80)
			node_button.text = _get_node_display_text(node)
			node_button.tooltip_text = node.get_description()
			
			# Style based on state
			if node.is_completed:
				node_button.modulate = Color(0.5, 0.5, 0.5)  # Gray
				node_button.disabled = true
			elif node.is_available:
				node_button.modulate = Color(0.5, 1.0, 0.5)  # Green
			else:
				node_button.modulate = Color(0.7, 0.7, 0.7)  # Darker gray
				node_button.disabled = true
			
			# Color code by type
			match node.type:
				MapNodeModel.NodeType.COOKING:
					if not node.is_completed:
						node_button.modulate = Color(1.0, 1.0, 1.0)
				MapNodeModel.NodeType.MODIFIER:
					if not node.is_completed:
						node_button.modulate = Color(1.0, 0.8, 0.5)  # Orange
				MapNodeModel.NodeType.SHOP:
					if not node.is_completed:
						node_button.modulate = Color(0.5, 0.8, 1.0)  # Blue
				MapNodeModel.NodeType.SUPER_SHOP:
					if not node.is_completed:
						node_button.modulate = Color(0.8, 0.5, 1.0)  # Purple
				MapNodeModel.NodeType.REST:
					if not node.is_completed:
						node_button.modulate = Color(0.5, 1.0, 1.0)  # Cyan
				MapNodeModel.NodeType.BOSS:
					if not node.is_completed:
						node_button.modulate = Color(1.0, 0.3, 0.3)  # Red
			
			node_button.pressed.connect(_on_node_button_pressed.bind(node))
			tier_row.add_child(node_button)
			node_buttons[node] = node_button
		
		map_container.add_child(tier_row)
	
	print("[MapUI] Built map UI with %d tiers" % map_manager.map_nodes.size())

func _get_node_display_text(node: MapNodeModel) -> String:
	var text = node.get_display_name()
	if node.type == MapNodeModel.NodeType.MODIFIER and node.modifier:
		text += "\n" + node.modifier.name
	return text

func _on_node_button_pressed(node: MapNodeModel) -> void:
	if node.is_available and not node.is_completed:
		node_clicked.emit(node)
		print("[MapUI] Node clicked: %s" % node.get_display_name())

## Refresh the map UI after a node is selected
func refresh_map() -> void:
	if map_manager:
		_build_map_ui()
