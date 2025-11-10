class_name ActiveItem
extends RefCounted

## Model representing an active item (tool) that can be used during cooking

enum Type { COVER, STIR, BLOW }

var type: Type
var name: String
var description: String
var cooldown_duration: float  # Seconds until item can be used again

func _init(
	p_type: Type = Type.COVER,
	p_name: String = "",
	p_description: String = "",
	p_cooldown_duration: float = 5.0
):
	type = p_type
	name = p_name
	description = p_description
	cooldown_duration = p_cooldown_duration

## Apply this item's effect to the moisture manager
## Each item has a unique effect:
## - COVER: Reduce drain by 40% for 5 seconds
## - STIR: Restore 20 moisture instantly
## - BLOW: Reduce drain by 60% for 3 seconds
func apply_effect(moisture_manager) -> void:
	match type:
		Type.COVER:
			moisture_manager.apply_drain_modifier(-0.4, 5.0)
		Type.STIR:
			moisture_manager.restore_moisture(20.0)
		Type.BLOW:
			moisture_manager.apply_drain_modifier(-0.6, 3.0)
