extends Node
class_name MapManager

## Manages the progression map generation and traversal (Slay the Spire style)
## Supports both procedural generation and manual scene-based design

var map_nodes: Array[Array] = []  # Array of tiers, each tier is an array of nodes
var current_tier: int = 0
var current_node: MapNodeModel = null
var current_path: Array[MapNodeModel] = []  # Track path taken
var ui_nodes_map: Dictionary = {}  # Maps MapNodeModel -> MapNodeUI

@export var use_custom_map: bool = false  # If true, load from scene instead of generating

const TIERS_PER_ACT: int = 15
const MIN_NODES_PER_TIER: int = 2
const MAX_NODES_PER_TIER: int = 4

signal node_selected(node: MapNodeModel)
signal map_generated()

## Generate or load the map
func initialize_map(round_modifier_manager: RoundModifierManager, custom_nodes: Array[MapNodeUI] = []) -> void:
	if use_custom_map and not custom_nodes.is_empty():
		load_from_custom_nodes(custom_nodes, round_modifier_manager)
	else:
		generate_map(round_modifier_manager)

## Generate a new map for the run with branching paths
func generate_map(round_modifier_manager: RoundModifierManager) -> void:
	map_nodes.clear()
	current_tier = 0
	current_node = null
	current_path.clear()
	
	# Generate 15 tiers for the act
	for tier in range(TIERS_PER_ACT):
		var tier_nodes: Array[MapNodeModel] = []
		
		# Determine node types and count for this tier
		if tier == 0:
			# First tier: Single starting node (always cooking)
			var start_node = MapNodeModel.new(MapNodeModel.NodeType.COOKING, tier)
			tier_nodes.append(start_node)
		elif tier == TIERS_PER_ACT - 1:
			# Last tier: Single boss node
			var boss_node = MapNodeModel.new(MapNodeModel.NodeType.BOSS, tier)
			tier_nodes.append(boss_node)
		elif tier % 5 == 4:
			# Every 5th tier (before boss): Treasure/Rest options (2-3 nodes)
			var node_count = randi_range(2, 3)
			for i in range(node_count):
				var node_type = MapNodeModel.NodeType.SHOP if i == 0 else (MapNodeModel.NodeType.SUPER_SHOP if randf() > 0.5 else MapNodeModel.NodeType.REST)
				tier_nodes.append(MapNodeModel.new(node_type, tier))
		else:
			# Normal tiers: Mix of cooking and modifiers (2-4 nodes for branching)
			var node_count = randi_range(MIN_NODES_PER_TIER, MAX_NODES_PER_TIER)
			for i in range(node_count):
				var node_type: MapNodeModel.NodeType
				var rand = randf()
				if rand < 0.5:
					node_type = MapNodeModel.NodeType.COOKING
				elif rand < 0.8:
					node_type = MapNodeModel.NodeType.MODIFIER
				else:
					node_type = MapNodeModel.NodeType.SHOP if randf() > 0.5 else MapNodeModel.NodeType.REST
				
				var node = MapNodeModel.new(node_type, tier)
				
				# If it's a modifier node, assign a random modifier
				if node_type == MapNodeModel.NodeType.MODIFIER:
					node.modifier = round_modifier_manager.get_random_modifier()
				
				tier_nodes.append(node)
		
		map_nodes.append(tier_nodes)
	
	# Connect nodes to create branching paths
	_connect_branching_paths()
	
	# Make first tier available
	for node in map_nodes[0]:
		node.is_available = true
	
	map_generated.emit()
	print("[MapManager] Generated branching map with %d tiers" % TIERS_PER_ACT)

## Connect nodes with branching paths (Slay the Spire style)
func _connect_branching_paths() -> void:
	for tier in range(map_nodes.size() - 1):
		var current_tier_nodes = map_nodes[tier]
		var next_tier_nodes = map_nodes[tier + 1]
		
		if next_tier_nodes.is_empty():
			continue
		
		# Each node connects to 1-3 nodes in the next tier (creating branches)
		for node in current_tier_nodes:
			var max_connections = min(3, next_tier_nodes.size())
			var connections_count = 1 if next_tier_nodes.size() == 1 else randi_range(1, max_connections)
			
			# Pick random targets ensuring good spread
			var available_targets = next_tier_nodes.duplicate()
			available_targets.shuffle()
			
			for i in range(connections_count):
				if i < available_targets.size():
					node.connections.append(available_targets[i])

## Load map from manually-designed MapNodeUI nodes in the scene
func load_from_custom_nodes(custom_nodes: Array[MapNodeUI], round_modifier_manager: RoundModifierManager) -> void:
	map_nodes.clear()
	current_tier = 0
	current_node = null
	current_path.clear()
	ui_nodes_map.clear()
	
	# Create models from UI nodes
	var all_models: Array[MapNodeModel] = []
	for ui_node in custom_nodes:
		var model = ui_node.create_model(round_modifier_manager)
		all_models.append(model)
		ui_nodes_map[model] = ui_node
	
	# Build connections between models based on UI node references
	for ui_node in custom_nodes:
		var model = null
		for m in all_models:
			if ui_nodes_map[m] == ui_node:
				model = m
				break
		
		if not model:
			continue
		
		# Connect to the corresponding models
		for connected_ui in ui_node.connected_node_refs:
			for m in all_models:
				if ui_nodes_map[m] == connected_ui:
					model.connections.append(m)
					break
	
	# Organize into tiers
	var max_tier = 0
	for model in all_models:
		max_tier = max(max_tier, model.tier)
	
	# Initialize tier arrays
	for i in range(max_tier + 1):
		map_nodes.append([])
	
	# Sort models into tiers
	for model in all_models:
		map_nodes[model.tier].append(model)
	
	map_generated.emit()
	print("[MapManager] Loaded custom map with %d tiers and %d nodes" % [max_tier + 1, all_models.size()])

## Generate a new map for the run with branching paths
func generate_map(round_modifier_manager: RoundModifierManager) -> void:
func select_node(node: MapNodeModel) -> void:
	if not node.is_available:
		print("[MapManager] Cannot select unavailable node")
		return
	
	current_node = node
	node.is_completed = true
	
	# Make connected nodes available
	for connected in node.connections:
		connected.is_available = true
	
	# Move to next tier if all nodes in current tier are completed
	var all_completed = true
	for n in map_nodes[current_tier]:
		if not n.is_completed:
			all_completed = false
			break
	
	if all_completed and current_tier < map_nodes.size() - 1:
		current_tier += 1
		print("[MapManager] Advanced to tier %d" % current_tier)
	
	node_selected.emit(node)
	print("[MapManager] Selected node: %s (tier %d)" % [node.get_display_name(), node.tier])

## Get all available nodes
func get_available_nodes() -> Array[MapNodeModel]:
	var available: Array[MapNodeModel] = []
	for tier in map_nodes:
		for node in tier:
			if node.is_available and not node.is_completed:
				available.append(node)
	return available

## Get nodes for a specific tier
func get_tier_nodes(tier: int) -> Array[MapNodeModel]:
	if tier >= 0 and tier < map_nodes.size():
		return map_nodes[tier]
	return []

## Check if map is complete
func is_map_complete() -> bool:
	return current_tier >= map_nodes.size() - 1 and (map_nodes[current_tier].is_empty() or map_nodes[current_tier][0].is_completed)
