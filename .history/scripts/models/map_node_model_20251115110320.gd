extends Resource
class_name MapNodeModel

## Represents a node on the progression map

enum NodeType {
	COOKING,      # Normal cooking round
	MODIFIER,     # Choose a round modifier
	SHOP,         # Regular shop
	SUPER_SHOP,   # Super shop (malfunction reward)
	REST,         # Restore some resources
	BOSS,         # Boss round with special challenge
	MALFUNCTION   # Malfunction event (can reward or challenge)
}

var type: NodeType
var tier: int  # Which tier/row this node is on
var connections: Array[MapNodeModel] = []  # Nodes this connects to
var is_completed: bool = false
var is_available: bool = false

# Node-specific data
var modifier: RoundModifierModel = null  # For MODIFIER nodes
var shop_quality: int = 1  # For SHOP nodes (1 = normal, 2 = super)

func _init(p_type: NodeType, p_tier: int):
	type = p_type
	tier = p_tier
	is_available = (tier == 0)  # First tier is always available

func get_display_name() -> String:
	match type:
		NodeType.COOKING:
			return "Cook"
		NodeType.MODIFIER:
			return "Modifier"
		NodeType.SHOP:
			return "Shop"
		NodeType.SUPER_SHOP:
			return "Super Shop"
		NodeType.REST:
			return "Rest"
		NodeType.BOSS:
			return "Boss"
	return "Unknown"

func get_description() -> String:
	match type:
		NodeType.COOKING:
			return "Cook ingredients for currency"
		NodeType.MODIFIER:
			if modifier:
				return modifier.description
			return "Choose a round modifier"
		NodeType.SHOP:
			return "Buy items and upgrades"
		NodeType.SUPER_SHOP:
			return "Premium shop with rare items"
		NodeType.REST:
			return "Upgrade a card permanently"
		NodeType.BOSS:
			return "Challenging round with big rewards"
	return ""
