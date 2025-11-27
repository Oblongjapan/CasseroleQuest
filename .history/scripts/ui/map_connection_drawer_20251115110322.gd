@tool
extends Control
class_name MapConnectionDrawer

## Draws connection lines between MapNodeUI nodes in the editor

@export var line_width: float = 4.0
@export var line_color: Color = Color(0.5, 0.5, 0.5, 0.5)
@export var active_line_color: Color = Color(0.3, 0.9, 0.3, 0.9)
@export var draw_in_editor: bool = true:
	set(value):
		draw_in_editor = value
		queue_redraw()

var map_nodes: Array[MapNodeUI] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_collect_map_nodes()
	queue_redraw()

func _draw() -> void:
	if not draw_in_editor and Engine.is_editor_hint():
		return
	
	_draw_connections()

## Collect all MapNodeUI nodes from parent
func _collect_map_nodes() -> void:
	map_nodes.clear()
	if not get_parent():
		return
	
	_recursive_collect(get_parent())

func _recursive_collect(node: Node) -> void:
	if node is MapNodeUI:
		map_nodes.append(node)
	
	for child in node.get_children():
		_recursive_collect(child)

## Draw lines between connected nodes
func _draw_connections() -> void:
	for node in map_nodes:
		if not node or not is_instance_valid(node):
			continue
		
		var from_pos = node.global_position - global_position + node.size / 2.0
		
		# Draw connections to each connected node
		for connected_ref in node.connected_node_refs:
			if not connected_ref or not is_instance_valid(connected_ref):
				continue
			
			var to_pos = connected_ref.global_position - global_position + connected_ref.size / 2.0
			
			# Use active color if the node is completed
			var color = active_line_color if (node.model and node.model.is_completed) else line_color
			draw_line(from_pos, to_pos, color, line_width, true)

## Refresh the connections (call after nodes change)
func refresh() -> void:
	_collect_map_nodes()
	
	# Resolve connections for all nodes
	for node in map_nodes:
		if node:
			node._resolve_connections()
	
	queue_redraw()

## Editor helper: Draw connections even when not running
func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and draw_in_editor:
		queue_redraw()
