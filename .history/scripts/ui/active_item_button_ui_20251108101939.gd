extends Button

## UI controller for individual active item buttons

@export var item_index: int = 0
var item: ActiveItem
var cooldown_remaining: float = 0.0
var is_ready: bool = true

func _ready():
	EventBus.item_used.connect(_on_item_used)
	EventBus.item_cooldown_updated.connect(_on_cooldown_updated)
	
	# Get item data from ActiveItemsData
	var all_items = ActiveItemsData.get_all_items()
	if item_index < all_items.size():
		item = all_items[item_index]
		text = item.name
		tooltip_text = item.description

## Button pressed - attempt to use item
func _pressed():
	if is_ready:
		# Main scene will handle the actual use_item call
		# This just sends the signal that button was pressed
		var main = get_tree().root.get_node_or_null("Main")
		if main and main.has_method("try_use_item"):
			main.try_use_item(item_index)
	else:
		# Visual feedback: button flash red when not ready
		_flash_red()

## Visual feedback for failed use
func _flash_red() -> void:
	modulate = Color.RED
	await get_tree().create_timer(0.2).timeout
	modulate = Color.WHITE

## When item is used, start cooldown
func _on_item_used(index: int) -> void:
	if index == item_index:
		is_ready = false
		disabled = true
		cooldown_remaining = item.cooldown_duration

## Update cooldown display
func _on_cooldown_updated(index: int, remaining: float) -> void:
	if index == item_index:
		cooldown_remaining = remaining
		
		if cooldown_remaining > 0:
			text = "%s (%.1f)" % [item.name, cooldown_remaining]
			is_ready = false
			disabled = true
		else:
			text = item.name
			is_ready = true
			disabled = false
