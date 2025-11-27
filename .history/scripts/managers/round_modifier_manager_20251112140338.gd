extends Node
class_name RoundModifierManager

## Manages round modifiers - selects and applies them each round

signal modifier_changed(new_modifier: RoundModifierModel)

var current_modifier: RoundModifierModel = null
var shop_discount: float = 0.0  # Current shop discount (if any)

## Select a new random modifier for the upcoming round
func select_new_modifier() -> RoundModifierModel:
	current_modifier = RoundModifiersData.get_random_modifier()
	
	# Update shop discount if applicable
	if current_modifier.modifier_type == RoundModifierModel.ModifierType.SHOP_DISCOUNT:
		shop_discount = current_modifier.value
	else:
		shop_discount = 0.0
	
	modifier_changed.emit(current_modifier)
	print("[RoundModifierManager] New modifier selected: %s" % current_modifier.name)
	return current_modifier

## Get the current modifier
func get_current_modifier() -> RoundModifierModel:
	return current_modifier

## Get current shop discount percentage (0.0 to 1.0)
func get_shop_discount() -> float:
	return shop_discount

## Apply moisture bonus/penalty to a base value
func apply_moisture_modifier(base_moisture: float) -> float:
	if current_modifier and current_modifier.modifier_type == RoundModifierModel.ModifierType.MOISTURE_BONUS:
		return base_moisture + current_modifier.value
	return base_moisture

## Apply drain rate multiplier
func apply_drain_multiplier(base_drain: float) -> float:
	if current_modifier and current_modifier.modifier_type == RoundModifierModel.ModifierType.DRAIN_MULTIPLIER:
		return base_drain * current_modifier.value
	return base_drain

## Apply timer bonus/penalty
func apply_timer_modifier(base_time: float) -> float:
	if current_modifier and current_modifier.modifier_type == RoundModifierModel.ModifierType.TIMER_BONUS:
		return base_time + current_modifier.value
	return base_time

## Apply volatility change to ingredient
func apply_volatility_modifier(base_volatility: float) -> float:
	if current_modifier and current_modifier.modifier_type == RoundModifierModel.ModifierType.VOLATILITY_CHANGE:
		return base_volatility + current_modifier.value
	return base_volatility

## Apply currency multiplier to earned currency
func apply_currency_modifier(base_currency: float) -> float:
	if current_modifier and current_modifier.modifier_type == RoundModifierModel.ModifierType.CURRENCY_BONUS:
		return base_currency * current_modifier.value
	return base_currency

## Reset modifier (for new game)
func reset() -> void:
	current_modifier = null
	shop_discount = 0.0
	print("[RoundModifierManager] Reset")
