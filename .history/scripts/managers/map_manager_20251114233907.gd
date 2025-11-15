extends Node
class_name MapManager

## Manages the progression map generation and traversal

var map_nodes: Array[Array] = []  # Array of tiers, each tier is an array of nodes
var current_tier: int = 0
var current_node: MapNodeModel = null

const TIERS_PER_RUN: int = 8
const NODES_PER_TIER: int = 3

signal node_selected(node: MapNodeModel)
signal map_generated()

## Generate a new map for the run
func generate_map(round_modifier_manager: RoundModifierManager) -> void:
	map_nodes.clear()
	current_tier = 0
	current_node = null
	
	# Generate 8 tiers
	for tier in range(TIERS_PER_RUN):
		var tier_nodes: Array[MapNodeModel] = []
		
		# Determine node types for this tier
		if tier == TIERS_PER_RUN - 1:
			# Last tier is always a boss
			var boss_node = MapNodeModel.new(MapNodeModel.NodeType.BOSS, tier)
			tier_nodes.append(boss_node)
		elif tier % 3 == 2:
			# Every 3rd tier: Shop options
			tier_nodes.append(MapNodeModel.new(MapNodeModel.NodeType.SHOP, tier))
			tier_nodes.append(MapNodeModel.new(MapNodeModel.NodeType.SUPER_SHOP, tier))
			tier_nodes.append(MapNodeModel.new(MapNodeModel.NodeType.REST, tier))
		else:
			# Normal tiers: Mix of cooking and modifiers
			for i in range(NODES_PER_TIER):
				var node_type = MapNodeModel.NodeType.COOKING if randf() > 0.4 else MapNodeModel.NodeType.MODIFIER
				var node = MapNodeModel.new(node_type, tier)
				
				# If it's a modifier node, assign a random modifier
				if node_type == MapNodeModel.NodeType.MODIFIER:
					node.modifier = round_modifier_manager.get_random_modifier()
				
				tier_nodes.append(node)
		
		map_nodes.append(tier_nodes)
	
	# Connect nodes between tiers
	_connect_tiers()
	
	# Make first tier available
	for node in map_nodes[0]:
		node.is_available = true
	
	map_generated.emit()
	print("[MapManager] Generated map with %d tiers" % TIERS_PER_RUN)

## Connect nodes between adjacent tiers
func _connect_tiers() -> void:
	for tier in range(map_nodes.size() - 1):
		var current_tier_nodes = map_nodes[tier]
		var next_tier_nodes = map_nodes[tier + 1]
		
		# Each node connects to 1-2 nodes in the next tier
		for node in current_tier_nodes:
			# Connect to at least 1 node
			var connections_count = 1 if next_tier_nodes.size() == 1 else randi_range(1, min(2, next_tier_nodes.size()))
			var available_targets = next_tier_nodes.duplicate()
			available_targets.shuffle()
			
			for i in range(connections_count):
				if i < available_targets.size():
					node.connections.append(available_targets[i])

## Select a node and make its connections available
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
