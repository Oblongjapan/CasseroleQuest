extends Button
class_name MapNodeUI

## Individual map node that can be placed and connected in the Godot editor

signal node_selected(node: MapNodeUI)

@export_group("Node Configuration")
@export var node_type: MapNodeModel.NodeType = MapNodeModel.NodeType.COOKING
@export var tier_number: int = 0
@export var is_starting_node: bool = false
@export_multiline var custom_description: String = ""

@export_group("Connections")
@export var connected_nodes: Array[NodePath] = []

@export_group("Modifier Settings (for MODIFIER type)")
@export var modifier_name: String = ""
@export var modifier_description: String = ""
@export var modifier_type: RoundModifierModel.ModifierType = RoundModifierModel.ModifierType.DRAIN_MULTIPLIER
@export var modifier_value: float = 1.0

@onready var icon_label: Label = $VBoxContainer/IconLabel
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var vbox: VBoxContainer = $VBoxContainer

var model: MapNodeModel = null
var connected_node_refs: Array[MapNodeUI] = []

# Node type colors
const COLOR_COOKING: Color = Color(0.85, 0.25, 0.25)
const COLOR_MODIFIER: Color = Color(0.95, 0.75, 0.15)
const COLOR_SHOP: Color = Color(0.25, 0.55, 0.95)
const COLOR_SUPER_SHOP: Color = Color(0.55, 0.25, 0.95)
const COLOR_REST: Color = Color(0.25, 0.85, 0.35)
const COLOR_BOSS: Color = Color(0.95, 0.15, 0.85)
const COLOR_MALFUNCTION: Color = Color(0.95, 0.55, 0.15)  # Orange

func _ready() -> void:
	_setup_visual_style()
	_resolve_connections()
	pressed.connect(_on_pressed)

## Setup the visual appearance based on node type
func _setup_visual_style() -> void:
	if not icon_label or not name_label:
		return
	
	# Set icon and name
	icon_label.text = _get_node_icon()
	name_label.text = _get_node_name()
	
	# Apply color styling
	var color = _get_node_color()
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
	style.border_color = Color.WHITE
	
	add_theme_stylebox_override("normal", style)
	
	# Hover style
	var hover_style = style.duplicate()
	hover_style.bg_color = color.lightened(0.3)
	hover_style.border_color = Color.YELLOW
	add_theme_stylebox_override("hover", hover_style)
	
	# Pressed style
	var pressed_style = style.duplicate()
	pressed_style.bg_color = color.darkened(0.2)
	add_theme_stylebox_override("pressed", pressed_style)
	
	# Disabled style
	var disabled_style = style.duplicate()
	disabled_style.bg_color = Color(0.25, 0.25, 0.25)
	disabled_style.border_color = Color(0.4, 0.4, 0.4)
	add_theme_stylebox_override("disabled", disabled_style)

## Resolve NodePath connections to actual node references
func _resolve_connections() -> void:
	connected_node_refs.clear()
	for node_path in connected_nodes:
		var node = get_node_or_null(node_path)
		if node and node is MapNodeUI:
			connected_node_refs.append(node)

## Create the model representation for this node
func create_model(round_modifier_manager: RoundModifierManager = null) -> MapNodeModel:
	model = MapNodeModel.new(node_type, tier_number)
	
	# If this is a modifier node, create the modifier
	if node_type == MapNodeModel.NodeType.MODIFIER:
		if modifier_name != "":
			var mod = RoundModifierModel.new()
			mod.name = modifier_name
			mod.description = modifier_description
			mod.modifier_type = modifier_type
			mod.value = modifier_value
			model.modifier = mod
		elif round_modifier_manager:
			# Use random modifier if no custom one specified
			model.modifier = round_modifier_manager.get_random_modifier()
	
	# Mark starting nodes as available
	if is_starting_node:
		model.is_available = true
	
	return model

## Update visual state based on model
func update_from_model() -> void:
	if not model:
		return
	
	disabled = not model.is_available or model.is_completed
	
	if model.is_completed:
		modulate = Color(0.6, 0.6, 0.6)
	else:
		modulate = Color.WHITE
	
	# Update border color
	var style = get_theme_stylebox("normal")
	if style is StyleBoxFlat:
		style.border_color = Color.WHITE if model.is_available else Color(0.4, 0.4, 0.4)

func _get_node_color() -> Color:
	match node_type:
		MapNodeModel.NodeType.COOKING: return COLOR_COOKING
		MapNodeModel.NodeType.MODIFIER: return COLOR_MODIFIER
		MapNodeModel.NodeType.SHOP: return COLOR_SHOP
		MapNodeModel.NodeType.SUPER_SHOP: return COLOR_SUPER_SHOP
		MapNodeModel.NodeType.REST: return COLOR_REST
		MapNodeModel.NodeType.BOSS: return COLOR_BOSS
		MapNodeModel.NodeType.MALFUNCTION: return COLOR_MALFUNCTION
	return Color.WHITE

func _get_node_icon() -> String:
	match node_type:
		MapNodeModel.NodeType.COOKING: return "🍳"
		MapNodeModel.NodeType.MODIFIER: return "⚡"
		MapNodeModel.NodeType.SHOP: return "🛒"
		MapNodeModel.NodeType.SUPER_SHOP: return "💎"
		MapNodeModel.NodeType.REST: return "🛏"
		MapNodeModel.NodeType.BOSS: return "👹"
		MapNodeModel.NodeType.MALFUNCTION: return "⚠️"
	return "?"

func _get_node_name() -> String:
	if custom_description != "":
		return custom_description
	
	match node_type:
		MapNodeModel.NodeType.COOKING: return "Cook"
		MapNodeModel.NodeType.MODIFIER: 
			return modifier_name if modifier_name != "" else "Modifier"
		MapNodeModel.NodeType.SHOP: return "Shop"
		MapNodeModel.NodeType.SUPER_SHOP: return "Super Shop"
		MapNodeModel.NodeType.REST: return "Rest"
		MapNodeModel.NodeType.BOSS: return "BOSS"
		MapNodeModel.NodeType.MALFUNCTION: return "Malfunction"
	return "Unknown"

func _on_pressed() -> void:
	if model and model.is_available and not model.is_completed:
		node_selected.emit(self)
