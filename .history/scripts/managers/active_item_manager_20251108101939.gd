extends Node
class_name ActiveItemManager

## Manages active item cooldowns and usage during cooking

var items: Array[ActiveItem] = []
var cooldowns: Array[float] = [0.0, 0.0, 0.0]
var max_cooldowns: Array[float] = [8.0, 6.0, 10.0]

## Initialize items (should be called with the 3 active items)
func setup(active_items: Array[ActiveItem]) -> void:
	items = active_items.duplicate()
	reset_cooldowns()

## Reset all cooldowns to zero
func reset_cooldowns() -> void:
	for i in range(cooldowns.size()):
		cooldowns[i] = 0.0
		EventBus.item_cooldown_updated.emit(i, 0.0)

## Update all cooldowns each frame
func update_cooldowns(delta: float) -> void:
	for i in range(cooldowns.size()):
		if cooldowns[i] > 0:
			cooldowns[i] -= delta
			cooldowns[i] = maxf(cooldowns[i], 0.0)
			EventBus.item_cooldown_updated.emit(i, cooldowns[i])

## Attempt to use an item
## Returns true if item was used (not on cooldown), false otherwise
func use_item(item_index: int, moisture_manager: MoistureManager) -> bool:
	if item_index < 0 or item_index >= items.size():
		return false
	
	if cooldowns[item_index] > 0:
		return false  # Still on cooldown
	
	# Apply item effect
	items[item_index].apply_effect(moisture_manager)
	
	# Start cooldown
	cooldowns[item_index] = items[item_index].cooldown_duration
	EventBus.item_used.emit(item_index)
	EventBus.item_cooldown_updated.emit(item_index, cooldowns[item_index])
	
	return true

## Get cooldown progress as percentage (0.0 = ready, 1.0 = just used)
func get_cooldown_percent(item_index: int) -> float:
	if item_index < 0 or item_index >= items.size():
		return 0.0
	
	if cooldowns[item_index] <= 0:
		return 0.0
	
	return cooldowns[item_index] / items[item_index].cooldown_duration

## Check if item is ready to use
func is_item_ready(item_index: int) -> bool:
	if item_index < 0 or item_index >= cooldowns.size():
		return false
	return cooldowns[item_index] <= 0.0
