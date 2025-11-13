extends Resource
class_name RoundModifierModel

## Model for round modifiers that affect gameplay

enum ModifierType {
	DRAIN_MULTIPLIER,  # Affects drain rate
	TIMER_BONUS,       # Adds/removes time
	MOISTURE_BONUS,    # Adds/removes starting moisture
	CURRENCY_BONUS,    # Multiplies currency earned
	VOLATILITY_CHANGE, # Changes ingredient volatility
	SHOP_DISCOUNT      # Reduces shop prices
}

var name: String = ""
var description: String = ""
var modifier_type: ModifierType
var value: float = 0.0  # Effect value (can be positive or negative)

func _init(p_name: String = "", p_description: String = "", p_type: ModifierType = ModifierType.DRAIN_MULTIPLIER, p_value: float = 0.0):
	name = p_name
	description = p_description
	modifier_type = p_type
	value = p_value
