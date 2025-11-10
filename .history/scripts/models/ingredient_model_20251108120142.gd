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
## Formula: Base drain + (Spice × 0.25) - (Heat Resistance × 0.02) - (Density × 0.015)
## Returns: Moisture drain per second (positive = draining)
func calculate_drain_rate() -> float:
	# Base drain of 5.0 moisture per second (harder baseline)
	var base_drain = 5.0
	# Spice increases drain significantly, resistance/density decrease it slightly
	var drain = base_drain + (spice_level * 0.25) - (heat_resistance * 0.02) - (density * 0.015)
	# Ensure drain is always positive (minimum 3.0 per second)
	return maxf(drain, 3.0)

## Get a formatted description of the ingredient stats
func get_stats_description() -> String:
	return "Water: %d | Heat Res: %d | Density: %d | Spice: %d" % [
		water_content, heat_resistance, density, spice_level
	]
