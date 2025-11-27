extends Panel

## Visual representation of the progression map with branching paths (Slay the Spire style)

signal node_clicked(node: MapNodeModel)

var map_manager: MapManager = null
var node_buttons: Dictionary = {}  # MapNodeModel -> Button mapping

@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer
var map_canvas: Control = null  # Dynamic canvas for positioning nodes
var line_renderer: Control = null  # Control node to draw connection lines

const NODE_SIZE: Vector2 = Vector2(100, 100)
const TIER_SPACING: float = 180.0
const NODE_SPACING: float = 140.0
const LINE_WIDTH: float = 4.0
const LINE_COLOR: Color = Color(0.5, 0.5, 0.5, 0.5)
const LINE_COLOR_ACTIVE: Color = Color(0.3, 0.9, 0.3, 0.9)

# Node type colors (matching Slay the Spire aesthetic)
const COLOR_COOKING: Color = Color(0.85, 0.25, 0.25)  # Red
const COLOR_MODIFIER: Color = Color(0.95, 0.75, 0.15)  # Gold
const COLOR_SHOP: Color = Color(0.25, 0.55, 0.95)  # Blue
const COLOR_SUPER_SHOP: Color = Color(0.55, 0.25, 0.95)  # Purple
const COLOR_REST: Color = Color(0.25, 0.85, 0.35)  # Green
const COLOR_BOSS: Color = Color(0.95, 0.15, 0.85)  # Magenta

func _ready() -> void:
	# Create dynamic canvas for node positioning
	if scroll_container:
		map_canvas = Control.new()
		map_canvas.custom_minimum_size = Vector2(1000, 2800)
		scroll_container.add_child(map_canvas)
		
		# Create line renderer (draws behind buttons)
		line_renderer = Control.new()
		line_renderer.set_anchors_preset(Control.PRESET_FULL_RECT)
		line_renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line_renderer.draw.connect(_draw_connection_lines)
		map_canvas.add_child(line_renderer)
	
	hide()

## Setup and display the map
func show_map(p_map_manager: MapManager) -> void:
	map_manager = p_map_manager
	_build_map_ui()
	show()

## Build the visual map with branching paths
func _build_map_ui() -> void:
	if not map_manager or not map_canvas:
		return
	
	# Clear existing nodes
	for button in node_buttons.values():
		button.queue_free()
	node_buttons.clear()
	
	# Calculate canvas size based on max tier width
	var max_nodes_in_tier = 0
	for tier_nodes in map_manager.map_nodes:
		max_nodes_in_tier = max(max_nodes_in_tier, tier_nodes.size())
	
	var canvas_width = max(1000, max_nodes_in_tier * NODE_SPACING + 300)
	var canvas_height = map_manager.map_nodes.size() * TIER_SPACING + 300
	map_canvas.custom_minimum_size = Vector2(canvas_width, canvas_height)
	
	# Create buttons for each node with calculated positions (bottom to top)
	for tier in range(map_manager.map_nodes.size() - 1, -1, -1):
		var tier_nodes = map_manager.map_nodes[tier]
		var tier_width = tier_nodes.size() * NODE_SPACING
		var start_x = (canvas_width - tier_width) / 2.0
		
		# Calculate y position (inverted so tier 0 is at bottom)
		var visual_tier = map_manager.map_nodes.size() - 1 - tier
		var pos_y = 150 + visual_tier * TIER_SPACING
		
		for i in range(tier_nodes.size()):
			var node = tier_nodes[i]
			var button = _create_node_button(node)
			
			# Position: centered horizontally, vertical by tier (inverted)
			var pos_x = start_x + i * NODE_SPACING
			button.position = Vector2(pos_x, pos_y)
			button.size = NODE_SIZE
			
			map_canvas.add_child(button)
			node_buttons[node] = button
	
	# Update line renderer
	if line_renderer:
		line_renderer.queue_redraw()
	
	print("[MapUI] Built map UI with %d tiers" % map_manager.map_nodes.size())

## Create a styled button for a map node
func _create_node_button(node: MapNodeModel) -> Button:
	var button = Button.new()
	button.custom_minimum_size = NODE_SIZE
	
	# Create a VBoxContainer for icon and label
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var icon_label = Label.new()
	icon_label.text = _get_node_icon(node.type)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)
	
	var name_label = Label.new()
	name_label.text = _get_node_name(node)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)
	
	button.add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Style based on node type
	var color = _get_node_color(node.type)
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = Color.WHITE if node.is_available else Color(0.4, 0.4, 0.4)
	
	button.add_theme_stylebox_override("normal", style)
	
	# Hover style
	var hover_style = style.duplicate()
	hover_style.bg_color = color.lightened(0.3)
	hover_style.border_color = Color.YELLOW
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed style
	var pressed_style = style.duplicate()
	pressed_style.bg_color = color.darkened(0.2)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Disabled style (for unavailable nodes)
	var disabled_style = style.duplicate()
	disabled_style.bg_color = Color(0.25, 0.25, 0.25)
	disabled_style.border_color = Color(0.4, 0.4, 0.4)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	# Completed nodes are grayed out
	if node.is_completed:
		button.modulate = Color(0.6, 0.6, 0.6)
	
	button.disabled = not node.is_available or node.is_completed
	button.pressed.connect(_on_node_button_pressed.bind(node))
	
	return button

## Get color for node type
func _get_node_color(type: MapNodeModel.NodeType) -> Color:
	match type:
		MapNodeModel.NodeType.COOKING: return COLOR_COOKING
		MapNodeModel.NodeType.MODIFIER: return COLOR_MODIFIER
		MapNodeModel.NodeType.SHOP: return COLOR_SHOP
		MapNodeModel.NodeType.SUPER_SHOP: return COLOR_SUPER_SHOP
		MapNodeModel.NodeType.REST: return COLOR_REST
		MapNodeModel.NodeType.BOSS: return COLOR_BOSS
	return Color.WHITE

## Get icon/symbol for node type
func _get_node_icon(type: MapNodeModel.NodeType) -> String:
	match type:
		MapNodeModel.NodeType.COOKING: return "🍳"
		MapNodeModel.NodeType.MODIFIER: return "⚡"
		MapNodeModel.NodeType.SHOP: return "🛒"
		MapNodeModel.NodeType.SUPER_SHOP: return "💎"
		MapNodeModel.NodeType.REST: return "🛏"
		MapNodeModel.NodeType.BOSS: return "👹"
	return "?"

## Get display name for node
func _get_node_name(node: MapNodeModel) -> String:
	match node.type:
		MapNodeModel.NodeType.COOKING: return "Cook"
		MapNodeModel.NodeType.MODIFIER: 
			return node.modifier.name if node.modifier else "Modifier"
		MapNodeModel.NodeType.SHOP: return "Shop"
		MapNodeModel.NodeType.SUPER_SHOP: return "Super Shop"
		MapNodeModel.NodeType.REST: return "Rest"
		MapNodeModel.NodeType.BOSS: return "BOSS"
	return "Unknown"

## Draw connection lines between nodes
func _draw_connection_lines() -> void:
	if not map_manager or not line_renderer:
		return
	
	for tier_nodes in map_manager.map_nodes:
		for node in tier_nodes:
			if node not in node_buttons:
				continue
			
			var from_button = node_buttons[node]
			var from_pos = from_button.position + NODE_SIZE / 2.0
			
			for connected_node in node.connections:
				if connected_node not in node_buttons:
					continue
				
				var to_button = node_buttons[connected_node]
				var to_pos = to_button.position + NODE_SIZE / 2.0
				
				# Use different color for paths on the current route
				var is_active_path = node.is_completed and map_manager.current_path.has(node)
				var color = LINE_COLOR_ACTIVE if is_active_path else LINE_COLOR
				line_renderer.draw_line(from_pos, to_pos, color, LINE_WIDTH)

## Handle node button press
func _on_node_button_pressed(node: MapNodeModel) -> void:
	if node.is_available and not node.is_completed:
		node_clicked.emit(node)

## Refresh UI after node selection
func refresh_ui() -> void:
	# Update button states
	for map_node in node_buttons:
		var button = node_buttons[map_node]
		button.disabled = not map_node.is_available or map_node.is_completed
		
		# Visual feedback for completed nodes
		if map_node.is_completed:
			button.modulate = Color(0.6, 0.6, 0.6)
		else:
			button.modulate = Color.WHITE
		
		# Update border color
		var style = button.get_theme_stylebox("normal")
		if style is StyleBoxFlat:
			style.border_color = Color.WHITE if map_node.is_available else Color(0.4, 0.4, 0.4)
	
	# Redraw lines to show active path
	if line_renderer:
		line_renderer.queue_redraw()
