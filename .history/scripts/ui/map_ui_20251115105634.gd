extends Panelextends Panel



## Visual representation of the progression map with branching paths (Slay the Spire style)## Visual representation of the progression map with branching paths (Slay the Spire style)

## Supports both procedurally generated maps and manually-designed maps from the scene

signal node_clicked(node: MapNodeModel)

signal node_clicked(node: MapNodeModel)

var map_manager: MapManager = null

var map_manager: MapManager = nullvar node_buttons: Dictionary = {}  # MapNodeModel -> Button mapping

var node_buttons: Dictionary = {}  # MapNodeModel -> Button mapping

@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer

@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainervar map_canvas: Control = null  # Dynamic canvas for positioning nodes

var map_canvas: Control = null  # Dynamic canvas for positioning nodesvar line_renderer: Control = null  # Control node to draw connection lines

var line_renderer: Control = null  # Control node to draw connection lines

var connection_drawer: MapConnectionDrawer = null  # For custom mapsconst NODE_SIZE: Vector2 = Vector2(100, 100)

const TIER_SPACING: float = 180.0

@export var use_custom_layout: bool = false  # If true, use manually-placed MapNodeUI nodesconst NODE_SPACING: float = 140.0

const LINE_WIDTH: float = 4.0

const NODE_SIZE: Vector2 = Vector2(100, 100)const LINE_COLOR: Color = Color(0.5, 0.5, 0.5, 0.5)

const TIER_SPACING: float = 180.0const LINE_COLOR_ACTIVE: Color = Color(0.3, 0.9, 0.3, 0.9)

const NODE_SPACING: float = 140.0

const LINE_WIDTH: float = 4.0# Node type colors (matching Slay the Spire aesthetic)

const LINE_COLOR: Color = Color(0.5, 0.5, 0.5, 0.5)const COLOR_COOKING: Color = Color(0.85, 0.25, 0.25)  # Red

const LINE_COLOR_ACTIVE: Color = Color(0.3, 0.9, 0.3, 0.9)const COLOR_MODIFIER: Color = Color(0.95, 0.75, 0.15)  # Gold

const COLOR_SHOP: Color = Color(0.25, 0.55, 0.95)  # Blue

# Node type colors (matching Slay the Spire aesthetic)const COLOR_SUPER_SHOP: Color = Color(0.55, 0.25, 0.95)  # Purple

const COLOR_COOKING: Color = Color(0.85, 0.25, 0.25)const COLOR_REST: Color = Color(0.25, 0.85, 0.35)  # Green

const COLOR_MODIFIER: Color = Color(0.95, 0.75, 0.15)const COLOR_BOSS: Color = Color(0.95, 0.15, 0.85)  # Magenta

const COLOR_SHOP: Color = Color(0.25, 0.55, 0.95)

const COLOR_SUPER_SHOP: Color = Color(0.55, 0.25, 0.95)func _ready() -> void:

const COLOR_REST: Color = Color(0.25, 0.85, 0.35)	# Create dynamic canvas for node positioning

const COLOR_BOSS: Color = Color(0.95, 0.15, 0.85)	if scroll_container:

const COLOR_MALFUNCTION: Color = Color(0.95, 0.55, 0.15)		map_canvas = Control.new()

		map_canvas.custom_minimum_size = Vector2(1000, 2800)

func _ready() -> void:		scroll_container.add_child(map_canvas)

	if not use_custom_layout:		

		# Create dynamic canvas for procedural node positioning		# Create line renderer (draws behind buttons)

		if scroll_container:		line_renderer = Control.new()

			map_canvas = Control.new()		line_renderer.set_anchors_preset(Control.PRESET_FULL_RECT)

			map_canvas.custom_minimum_size = Vector2(1000, 2800)		line_renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE

			scroll_container.add_child(map_canvas)		line_renderer.draw.connect(_draw_connection_lines)

					map_canvas.add_child(line_renderer)

			# Create line renderer (draws behind buttons)	

			line_renderer = Control.new()	hide()

			line_renderer.set_anchors_preset(Control.PRESET_FULL_RECT)

			line_renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE## Setup and display the map

			line_renderer.draw.connect(_draw_connection_lines)func show_map(p_map_manager: MapManager) -> void:

			map_canvas.add_child(line_renderer)	map_manager = p_map_manager

	else:	_build_map_ui()

		# Look for MapConnectionDrawer in the scene for custom layouts	show()

		connection_drawer = get_node_or_null("VBoxContainer/ScrollContainer/MapConnectionDrawer")

	## Build the visual map with branching paths

	hide()func _build_map_ui() -> void:

	if not map_manager or not map_canvas:

## Setup and display the map		return

func show_map(p_map_manager: MapManager) -> void:	

	map_manager = p_map_manager	# Clear existing nodes

		for button in node_buttons.values():

	if use_custom_layout:		button.queue_free()

		_setup_custom_map()	node_buttons.clear()

	else:	

		_build_map_ui()	# Calculate canvas size based on max tier width

		var max_nodes_in_tier = 0

	show()	for tier_nodes in map_manager.map_nodes:

		max_nodes_in_tier = max(max_nodes_in_tier, tier_nodes.size())

## Setup custom map from manually-placed MapNodeUI nodes	

func _setup_custom_map() -> void:	var canvas_width = max(1000, max_nodes_in_tier * NODE_SPACING + 300)

	if not map_manager:	var canvas_height = map_manager.map_nodes.size() * TIER_SPACING + 300

		return	map_canvas.custom_minimum_size = Vector2(canvas_width, canvas_height)

		

	# Collect all MapNodeUI nodes in the scene	# Create buttons for each node with calculated positions (bottom to top)

	var custom_nodes: Array[MapNodeUI] = []	for tier in range(map_manager.map_nodes.size() - 1, -1, -1):

	_collect_map_nodes(self, custom_nodes)		var tier_nodes = map_manager.map_nodes[tier]

			var tier_width = tier_nodes.size() * NODE_SPACING

	# Create models from UI nodes and update their visuals		var start_x = (canvas_width - tier_width) / 2.0

	for ui_node in custom_nodes:		

		# Get or create model from map_manager's ui_nodes_map		# Calculate y position (inverted so tier 0 is at bottom)

		var model: MapNodeModel = null		var visual_tier = map_manager.map_nodes.size() - 1 - tier

		for m in map_manager.ui_nodes_map:		var pos_y = 150 + visual_tier * TIER_SPACING

			if map_manager.ui_nodes_map[m] == ui_node:		

				model = m		for i in range(tier_nodes.size()):

				break			var node = tier_nodes[i]

					var button = _create_node_button(node)

		if model:			

			ui_node.model = model			# Position: centered horizontally, vertical by tier (inverted)

			ui_node.update_from_model()			var pos_x = start_x + i * NODE_SPACING

			ui_node.node_selected.connect(_on_custom_node_selected)			button.position = Vector2(pos_x, pos_y)

				button.size = NODE_SIZE

	# Refresh connection drawer if it exists			

	if connection_drawer:			map_canvas.add_child(button)

		connection_drawer.refresh()			node_buttons[node] = button

		

	print("[MapUI] Setup custom map with %d nodes" % custom_nodes.size())	# Update line renderer

	if line_renderer:

func _collect_map_nodes(node: Node, result: Array[MapNodeUI]) -> void:		line_renderer.queue_redraw()

	if node is MapNodeUI:	

		result.append(node)	print("[MapUI] Built map UI with %d tiers" % map_manager.map_nodes.size())

	for child in node.get_children():

		_collect_map_nodes(child, result)## Create a styled button for a map node

func _create_node_button(node: MapNodeModel) -> Button:

func _on_custom_node_selected(ui_node: MapNodeUI) -> void:	var button = Button.new()

	if ui_node.model:	button.custom_minimum_size = NODE_SIZE

		node_clicked.emit(ui_node.model)	

	# Create a VBoxContainer for icon and label

## Build the visual map with branching paths (procedural mode)	var vbox = VBoxContainer.new()

func _build_map_ui() -> void:	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	if not map_manager or not map_canvas:	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

		return	

		var icon_label = Label.new()

	# Clear existing nodes	icon_label.text = _get_node_icon(node.type)

	for button in node_buttons.values():	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		button.queue_free()	icon_label.add_theme_font_size_override("font_size", 32)

	node_buttons.clear()	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		vbox.add_child(icon_label)

	# Calculate canvas size based on max tier width	

	var max_nodes_in_tier = 0	var name_label = Label.new()

	for tier_nodes in map_manager.map_nodes:	name_label.text = _get_node_name(node)

		max_nodes_in_tier = max(max_nodes_in_tier, tier_nodes.size())	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		name_label.add_theme_font_size_override("font_size", 10)

	var canvas_width = max(1000, max_nodes_in_tier * NODE_SPACING + 300)	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var canvas_height = map_manager.map_nodes.size() * TIER_SPACING + 300	vbox.add_child(name_label)

	map_canvas.custom_minimum_size = Vector2(canvas_width, canvas_height)	

		button.add_child(vbox)

	# Create buttons for each node with calculated positions (bottom to top)	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)

	for tier in range(map_manager.map_nodes.size() - 1, -1, -1):	

		var tier_nodes = map_manager.map_nodes[tier]	# Style based on node type

		var tier_width = tier_nodes.size() * NODE_SPACING	var color = _get_node_color(node.type)

		var start_x = (canvas_width - tier_width) / 2.0	var style = StyleBoxFlat.new()

			style.bg_color = color

		# Calculate y position (inverted so tier 0 is at bottom)	style.corner_radius_top_left = 15

		var visual_tier = map_manager.map_nodes.size() - 1 - tier	style.corner_radius_top_right = 15

		var pos_y = 150 + visual_tier * TIER_SPACING	style.corner_radius_bottom_left = 15

			style.corner_radius_bottom_right = 15

		for i in range(tier_nodes.size()):	style.border_width_left = 4

			var node = tier_nodes[i]	style.border_width_right = 4

			var button = _create_node_button(node)	style.border_width_top = 4

				style.border_width_bottom = 4

			# Position: centered horizontally, vertical by tier (inverted)	style.border_color = Color.WHITE if node.is_available else Color(0.4, 0.4, 0.4)

			var pos_x = start_x + i * NODE_SPACING	

			button.position = Vector2(pos_x, pos_y)	button.add_theme_stylebox_override("normal", style)

			button.size = NODE_SIZE	

				# Hover style

			map_canvas.add_child(button)	var hover_style = style.duplicate()

			node_buttons[node] = button	hover_style.bg_color = color.lightened(0.3)

		hover_style.border_color = Color.YELLOW

	# Update line renderer	button.add_theme_stylebox_override("hover", hover_style)

	if line_renderer:	

		line_renderer.queue_redraw()	# Pressed style

		var pressed_style = style.duplicate()

	print("[MapUI] Built map UI with %d tiers" % map_manager.map_nodes.size())	pressed_style.bg_color = color.darkened(0.2)

	button.add_theme_stylebox_override("pressed", pressed_style)

## Create a styled button for a map node	

func _create_node_button(node: MapNodeModel) -> Button:	# Disabled style (for unavailable nodes)

	var button = Button.new()	var disabled_style = style.duplicate()

	button.custom_minimum_size = NODE_SIZE	disabled_style.bg_color = Color(0.25, 0.25, 0.25)

		disabled_style.border_color = Color(0.4, 0.4, 0.4)

	# Create a VBoxContainer for icon and label	button.add_theme_stylebox_override("disabled", disabled_style)

	var vbox = VBoxContainer.new()	

	vbox.alignment = BoxContainer.ALIGNMENT_CENTER	# Completed nodes are grayed out

	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE	if node.is_completed:

			button.modulate = Color(0.6, 0.6, 0.6)

	var icon_label = Label.new()	

	icon_label.text = _get_node_icon(node.type)	button.disabled = not node.is_available or node.is_completed

	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER	button.pressed.connect(_on_node_button_pressed.bind(node))

	icon_label.add_theme_font_size_override("font_size", 32)	

	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE	return button

	vbox.add_child(icon_label)

	## Get color for node type

	var name_label = Label.new()func _get_node_color(type: MapNodeModel.NodeType) -> Color:

	name_label.text = _get_node_name(node)	match type:

	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER		MapNodeModel.NodeType.COOKING: return COLOR_COOKING

	name_label.add_theme_font_size_override("font_size", 10)		MapNodeModel.NodeType.MODIFIER: return COLOR_MODIFIER

	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE		MapNodeModel.NodeType.SHOP: return COLOR_SHOP

	vbox.add_child(name_label)		MapNodeModel.NodeType.SUPER_SHOP: return COLOR_SUPER_SHOP

			MapNodeModel.NodeType.REST: return COLOR_REST

	button.add_child(vbox)		MapNodeModel.NodeType.BOSS: return COLOR_BOSS

	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)	return Color.WHITE

	

	# Style based on node type## Get icon/symbol for node type

	var color = _get_node_color(node.type)func _get_node_icon(type: MapNodeModel.NodeType) -> String:

	var style = StyleBoxFlat.new()	match type:

	style.bg_color = color		MapNodeModel.NodeType.COOKING: return "🍳"

	style.corner_radius_top_left = 15		MapNodeModel.NodeType.MODIFIER: return "⚡"

	style.corner_radius_top_right = 15		MapNodeModel.NodeType.SHOP: return "🛒"

	style.corner_radius_bottom_left = 15		MapNodeModel.NodeType.SUPER_SHOP: return "💎"

	style.corner_radius_bottom_right = 15		MapNodeModel.NodeType.REST: return "🛏"

	style.border_width_left = 4		MapNodeModel.NodeType.BOSS: return "👹"

	style.border_width_right = 4	return "?"

	style.border_width_top = 4

	style.border_width_bottom = 4## Get display name for node

	style.border_color = Color.WHITE if node.is_available else Color(0.4, 0.4, 0.4)func _get_node_name(node: MapNodeModel) -> String:

		match node.type:

	button.add_theme_stylebox_override("normal", style)		MapNodeModel.NodeType.COOKING: return "Cook"

			MapNodeModel.NodeType.MODIFIER: 

	# Hover style			return node.modifier.name if node.modifier else "Modifier"

	var hover_style = style.duplicate()		MapNodeModel.NodeType.SHOP: return "Shop"

	hover_style.bg_color = color.lightened(0.3)		MapNodeModel.NodeType.SUPER_SHOP: return "Super Shop"

	hover_style.border_color = Color.YELLOW		MapNodeModel.NodeType.REST: return "Rest"

	button.add_theme_stylebox_override("hover", hover_style)		MapNodeModel.NodeType.BOSS: return "BOSS"

		return "Unknown"

	# Pressed style

	var pressed_style = style.duplicate()## Draw connection lines between nodes

	pressed_style.bg_color = color.darkened(0.2)func _draw_connection_lines() -> void:

	button.add_theme_stylebox_override("pressed", pressed_style)	if not map_manager or not line_renderer:

			return

	# Disabled style (for unavailable nodes)	

	var disabled_style = style.duplicate()	for tier_nodes in map_manager.map_nodes:

	disabled_style.bg_color = Color(0.25, 0.25, 0.25)		for node in tier_nodes:

	disabled_style.border_color = Color(0.4, 0.4, 0.4)			if node not in node_buttons:

	button.add_theme_stylebox_override("disabled", disabled_style)				continue

				

	# Completed nodes are grayed out			var from_button = node_buttons[node]

	if node.is_completed:			var from_pos = from_button.position + NODE_SIZE / 2.0

		button.modulate = Color(0.6, 0.6, 0.6)			

				for connected_node in node.connections:

	button.disabled = not node.is_available or node.is_completed				if connected_node not in node_buttons:

	button.pressed.connect(_on_node_button_pressed.bind(node))					continue

					

	return button				var to_button = node_buttons[connected_node]

				var to_pos = to_button.position + NODE_SIZE / 2.0

## Get color for node type				

func _get_node_color(type: MapNodeModel.NodeType) -> Color:				# Use different color for paths on the current route

	match type:				var is_active_path = node.is_completed and map_manager.current_path.has(node)

		MapNodeModel.NodeType.COOKING: return COLOR_COOKING				var color = LINE_COLOR_ACTIVE if is_active_path else LINE_COLOR

		MapNodeModel.NodeType.MODIFIER: return COLOR_MODIFIER				line_renderer.draw_line(from_pos, to_pos, color, LINE_WIDTH)

		MapNodeModel.NodeType.SHOP: return COLOR_SHOP

		MapNodeModel.NodeType.SUPER_SHOP: return COLOR_SUPER_SHOP## Handle node button press

		MapNodeModel.NodeType.REST: return COLOR_RESTfunc _on_node_button_pressed(node: MapNodeModel) -> void:

		MapNodeModel.NodeType.BOSS: return COLOR_BOSS	if node.is_available and not node.is_completed:

		MapNodeModel.NodeType.MALFUNCTION: return COLOR_MALFUNCTION		node_clicked.emit(node)

	return Color.WHITE

## Refresh UI after node selection

## Get icon/symbol for node typefunc refresh_ui() -> void:

func _get_node_icon(type: MapNodeModel.NodeType) -> String:	# Update button states

	match type:	for map_node in node_buttons:

		MapNodeModel.NodeType.COOKING: return "🍳"		var button = node_buttons[map_node]

		MapNodeModel.NodeType.MODIFIER: return "⚡"		button.disabled = not map_node.is_available or map_node.is_completed

		MapNodeModel.NodeType.SHOP: return "🛒"		

		MapNodeModel.NodeType.SUPER_SHOP: return "💎"		# Visual feedback for completed nodes

		MapNodeModel.NodeType.REST: return "🛏"		if map_node.is_completed:

		MapNodeModel.NodeType.BOSS: return "👹"			button.modulate = Color(0.6, 0.6, 0.6)

		MapNodeModel.NodeType.MALFUNCTION: return "⚠️"		else:

	return "?"			button.modulate = Color.WHITE

		

## Get display name for node		# Update border color

func _get_node_name(node: MapNodeModel) -> String:		var style = button.get_theme_stylebox("normal")

	match node.type:		if style is StyleBoxFlat:

		MapNodeModel.NodeType.COOKING: return "Cook"			style.border_color = Color.WHITE if map_node.is_available else Color(0.4, 0.4, 0.4)

		MapNodeModel.NodeType.MODIFIER: 	

			return node.modifier.name if node.modifier else "Modifier"	# Redraw lines to show active path

		MapNodeModel.NodeType.SHOP: return "Shop"	if line_renderer:

		MapNodeModel.NodeType.SUPER_SHOP: return "Super Shop"		line_renderer.queue_redraw()

		MapNodeModel.NodeType.REST: return "Rest"
		MapNodeModel.NodeType.BOSS: return "BOSS"
		MapNodeModel.NodeType.MALFUNCTION: return "Malfunction"
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
	if use_custom_layout:
		_refresh_custom_ui()
	else:
		_refresh_procedural_ui()

func _refresh_custom_ui() -> void:
	# Update all MapNodeUI nodes
	var custom_nodes: Array[MapNodeUI] = []
	_collect_map_nodes(self, custom_nodes)
	
	for ui_node in custom_nodes:
		if ui_node.model:
			ui_node.update_from_model()
	
	# Redraw connections
	if connection_drawer:
		connection_drawer.refresh()

func _refresh_procedural_ui() -> void:
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
