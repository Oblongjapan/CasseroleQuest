extends Node

## Central data repository for relics (passive items with special effects)

const RELICS = [
	{
		"name": "Cooling Pad",
		"description": "A heat-resistant mat that slows moisture loss",
		"effect_type": RelicModel.EffectType.REDUCE_DRAIN,
		"effect_value": 0.15  # 15% drain reduction
	},
	{
		"name": "Speed Gloves",
		"description": "Allows faster item usage",
		"effect_type": RelicModel.EffectType.REDUCE_COOLDOWN,
		"effect_value": 0.25  # 25% cooldown reduction
	},
	{
		"name": "Water Reservoir",
		"description": "Start each round with extra moisture",
		"effect_type": RelicModel.EffectType.BONUS_MOISTURE,
		"effect_value": 20.0  # +20 starting moisture
	},
	{
		"name": "Training Manual",
		"description": "Slows the rate difficulty increases",
		"effect_type": RelicModel.EffectType.SLOWER_DIFFICULTY,
		"effect_value": 0.3  # 30% slower difficulty scaling
	},
	{
		"name": "Insulated Bowl",
		"description": "Superior heat retention",
		"effect_type": RelicModel.EffectType.REDUCE_DRAIN,
		"effect_value": 0.2  # 20% drain reduction
	},
	{
		"name": "Quick Hands",
		"description": "Massively reduced cooldowns",
		"effect_type": RelicModel.EffectType.REDUCE_COOLDOWN,
		"effect_value": 0.4  # 40% cooldown reduction
	},
	{
		"name": "Moisture Lock",
		"description": "Significant reduction in moisture loss",
		"effect_type": RelicModel.EffectType.REDUCE_DRAIN,
		"effect_value": 0.25  # 25% drain reduction
	},
	{
		"name": "Chef's Guide",
		"description": "You learn faster, difficulty scales slower",
		"effect_type": RelicModel.EffectType.SLOWER_DIFFICULTY,
		"effect_value": 0.5  # 50% slower difficulty scaling
	}
]

## Get all relics as RelicModel instances
func get_all_relics() -> Array[RelicModel]:
	var relics: Array[RelicModel] = []
	for relic_data in RELICS:
		var relic = RelicModel.new(
			relic_data.name,
			relic_data.description,
			relic_data.effect_type,
			relic_data.effect_value
		)
		relics.append(relic)
	return relics

## Get a random pool of relics
func get_random_relics(count: int) -> Array[RelicModel]:
	var all_relics = get_all_relics()
	all_relics.shuffle()
	
	var result: Array[RelicModel] = []
	for i in range(min(count, all_relics.size())):
		result.append(all_relics[i])
	return result
