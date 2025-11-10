class_name IngredientModel
extends RefCounted

## Model representing a food ingredient with stats that affect moisture drain

var name: String
var water_content: int  # 0-100, higher = more moisture
var heat_resistance: int  # 0-100, higher = resists drying
var density: int  # 0-100, higher = holds moisture better
var spice_level: int  # 0-100, higher = dries faster

func _init(
	p_name: String = "",
	p_water_content: int = 50,
	p_heat_resistance: int = 50,
	p_density: int = 50,
	p_spice_level: int = 50
):
	name = p_name
	water_content = p_water_content
	heat_resistance = p_heat_resistance
	density = p_density
	spice_level = p_spice_level

## Calculate drain rate per second based on ingredient stats
## Formula: (Spice × 0.5) - (Heat Resistance × 0.3) - (Density × 0.2)
## Returns: Moisture drain per second (can be negative for very resistant ingredients)
func calculate_drain_rate() -> float:
	var drain = (spice_level * 0.5) - (heat_resistance * 0.3) - (density * 0.2)
	return drain

## Get a formatted description of the ingredient stats
func get_stats_description() -> String:
	return "Water: %d | Heat Res: %d | Density: %d | Spice: %d" % [
		water_content, heat_resistance, density, spice_level
	]
