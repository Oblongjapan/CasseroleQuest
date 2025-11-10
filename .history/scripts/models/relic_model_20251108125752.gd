class_name RelicModel
extends RefCounted

## Model representing a passive relic with special effects

enum EffectType {
	REDUCE_DRAIN,        # Reduces moisture drain by percentage
	REDUCE_COOLDOWN,     # Reduces item cooldown by percentage
	BONUS_MOISTURE,      # Adds bonus starting moisture
	SLOWER_DIFFICULTY    # Slows difficulty scaling
}

var name: String
var description: String
var effect_type: EffectType
var effect_value: float  # Percentage (0.0-1.0) or absolute value depending on type

func _init(
	p_name: String = "",
	p_description: String = "",
	p_effect_type: EffectType = EffectType.REDUCE_DRAIN,
	p_effect_value: float = 0.1
):
	name = p_name
	description = p_description
	effect_type = p_effect_type
	effect_value = p_effect_value

## Get formatted description of the relic effect
func get_effect_description() -> String:
	match effect_type:
		EffectType.REDUCE_DRAIN:
			return "-%d%% moisture drain" % int(effect_value * 100)
		EffectType.REDUCE_COOLDOWN:
			return "-%d%% item cooldowns" % int(effect_value * 100)
		EffectType.BONUS_MOISTURE:
			return "+%d starting moisture" % int(effect_value)
		EffectType.SLOWER_DIFFICULTY:
			return "-%d%% difficulty scaling" % int(effect_value * 100)
		_:
			return "Unknown effect"
