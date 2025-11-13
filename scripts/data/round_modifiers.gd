extends Node

## Static data for round modifiers

static func get_all_modifiers() -> Array[RoundModifierModel]:
	var modifiers: Array[RoundModifierModel] = []
	
	# Positive modifiers (helpful)
	modifiers.append(RoundModifierModel.new(
		"Lucky Day",
		"Shop items cost 20% less",
		RoundModifierModel.ModifierType.SHOP_DISCOUNT,
		0.2
	))
	
	modifiers.append(RoundModifierModel.new(
		"Humidity Boost",
		"Start with +20 moisture but +2 drain rate",
		RoundModifierModel.ModifierType.MOISTURE_BONUS,
		20.0
	))
	
	modifiers.append(RoundModifierModel.new(
		"Extended Time",
		"Cook for 5 extra seconds",
		RoundModifierModel.ModifierType.TIMER_BONUS,
		5.0
	))
	
	modifiers.append(RoundModifierModel.new(
		"Bonus Payday",
		"Earn 50% more currency this round",
		RoundModifierModel.ModifierType.CURRENCY_BONUS,
		1.5
	))
	
	modifiers.append(RoundModifierModel.new(
		"Gentle Heat",
		"Drain rate reduced by 30%",
		RoundModifierModel.ModifierType.DRAIN_MULTIPLIER,
		0.7
	))
	
	# Negative modifiers (challenging)
	modifiers.append(RoundModifierModel.new(
		"Power Surge",
		"Drain rate increased by 40%",
		RoundModifierModel.ModifierType.DRAIN_MULTIPLIER,
		1.4
	))
	
	modifiers.append(RoundModifierModel.new(
		"Rusty Microwave",
		"Start with -15 moisture",
		RoundModifierModel.ModifierType.MOISTURE_BONUS,
		-15.0
	))
	
	modifiers.append(RoundModifierModel.new(
		"Time Crunch",
		"Timer reduced by 3 seconds",
		RoundModifierModel.ModifierType.TIMER_BONUS,
		-3.0
	))
	
	modifiers.append(RoundModifierModel.new(
		"Volatile Mix",
		"All ingredients are +5 more volatile",
		RoundModifierModel.ModifierType.VOLATILITY_CHANGE,
		5.0
	))
	
	modifiers.append(RoundModifierModel.new(
		"Weak Rotation",
		"Drain rate increased by 25%",
		RoundModifierModel.ModifierType.DRAIN_MULTIPLIER,
		1.25
	))
	
	# Neutral/mixed modifiers
	modifiers.append(RoundModifierModel.new(
		"Normal Day",
		"No special effects this round",
		RoundModifierModel.ModifierType.DRAIN_MULTIPLIER,
		1.0
	))
	
	return modifiers

## Get a random modifier
static func get_random_modifier() -> RoundModifierModel:
	var all_modifiers = get_all_modifiers()
	return all_modifiers[randi() % all_modifiers.size()]

## Get a modifier by name (useful for testing)
static func get_modifier_by_name(modifier_name: String) -> RoundModifierModel:
	var all_modifiers = get_all_modifiers()
	for modifier in all_modifiers:
		if modifier.name == modifier_name:
			return modifier
	return null
