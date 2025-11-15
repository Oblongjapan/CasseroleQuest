extends Node
class_name CurrencyManager

## Manages moisture currency earned from successful rounds

var total_currency: int = 0

signal currency_changed(new_amount: int)

## Initialize currency with starting amount at game start
func reset() -> void:
	total_currency = 20  # Give starting currency to help with first shop
	currency_changed.emit(total_currency)
	EventBus.currency_changed.emit(total_currency)

## Add currency (usually from completing a round with remaining moisture)
func add_currency(amount: int) -> void:
	total_currency += amount
	print("[CurrencyManager] Added %d currency, total: %d" % [amount, total_currency])
	currency_changed.emit(total_currency)
	EventBus.currency_changed.emit(total_currency)

## Spend currency (returns true if successful)
func spend_currency(amount: int) -> bool:
	if total_currency >= amount:
		total_currency -= amount
		print("[CurrencyManager] Spent %d currency, remaining: %d" % [amount, total_currency])
		currency_changed.emit(total_currency)
		EventBus.currency_changed.emit(total_currency)
		return true
	else:
		print("[CurrencyManager] Not enough currency! Need %d, have %d" % [amount, total_currency])
		return false

## Check if player can afford an item
func can_afford(amount: int) -> bool:
	return total_currency >= amount

## Get current currency
func get_currency() -> int:
	return total_currency
