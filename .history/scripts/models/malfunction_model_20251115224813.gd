class_name MalfunctionModel
extends Resource

## Model for malfunction "boss" encounters

enum MalfunctionType {
	OVERHEAT,      ## 1.5x base drain rate
	BULB_OUT       ## 0.5x drain rate
}

## Unique identifier for this malfunction
@export var id: String = ""

## Display name
@export var name: String = ""

## Description of the malfunction effect
@export var description: String = ""

## Type of malfunction
@export var type: MalfunctionType = MalfunctionType.OVERHEAT

## Drain rate multiplier (used by Overheat and Bulb Out)
@export var drain_multiplier: float = 1.0

## Reward type description
@export var reward_description: String = ""

func _init(
	p_id: String = "",
	p_name: String = "",
	p_description: String = "",
	p_type: MalfunctionType = MalfunctionType.OVERHEAT,
	p_drain_multiplier: float = 1.0,
	p_reward_description: String = ""
):
	id = p_id
	name = p_name
	description = p_description
	type = p_type
	drain_multiplier = p_drain_multiplier
	reward_description = p_reward_description

## Get formatted display text for the malfunction
func get_display_text() -> String:
	return "[color=red][b]MALFUNCTION: %s[/b][/color]\n%s" % [name.to_upper(), description]
