extends Control
class_name VisualShopGrid

## Visual shop grid where you can manually place and arrange ShopSlot nodes
## This allows for custom layouts in the Godot editor

@export var auto_populate: bool = true  # Automatically fill slots when shop refreshes
@export var free_sample_count: int = 3  # How many free samples to give

var shop_manager: ShopManager
var currency_manager: CurrencyManager
var fridge_manager: FridgeManager
var progression_manager: ProgressionManager
var card_selector: CardSelector  # For upgrade target selection
var all_slots: Array[ShopSlot] = []
var free_sample_slots: Array[ShopSlot] = []
var paid_slots: Array[ShopSlot] = []
var samples_taken: int = 0
var max_unseen_samples: int = 2  # Can take 2 unseen samples OR 1 seen sample

signal all_slots_filled()
signal free_samples_ready(samples: Array[Dictionary])
signal shop_done()  # Emitted when player clicks done

func _ready():
	_collect_slots()

## Collect all ShopSlot children
func _collect_slots():
	all_slots.clear()
	free_sample_slots.clear()
	paid_slots.clear()
	
	# Find all ShopSlot nodes recursively
	_find_shop_slots(self)
	
	print("[VisualShopGrid] Found %d total slots" % all_slots.size())
	print("[VisualShopGrid] - %d free sample slots" % free_sample_slots.size())
	print("[VisualShopGrid] - %d paid slots" % paid_slots.size())

func _find_shop_slots(node: Node):
	for child in node.get_children():
		if child is ShopSlot:
			all_slots.append(child)
			if child.is_free_sample:
				free_sample_slots.append(child)
			else:
				paid_slots.append(child)
		else:
			# Recursively search children
			_find_shop_slots(child)

## Setup the shop grid with managers
func setup(shop_mgr: ShopManager, currency_mgr: CurrencyManager, fridge_mgr: FridgeManager, prog_mgr: ProgressionManager = null, card_sel: CardSelector = null):
	shop_manager = shop_mgr
	currency_manager = currency_mgr
	fridge_manager = fridge_mgr
	progression_manager = prog_mgr
	card_selector = card_sel
	
	# Connect to shop refresh signal
	if shop_manager and not shop_manager.shop_refreshed.is_connected(_on_shop_refreshed):
		shop_manager.shop_refreshed.connect(_on_shop_refreshed)
	
	# Connect to upgrade needs target signal
	if shop_manager and card_selector and not shop_manager.upgrade_needs_target.is_connected(_on_upgrade_needs_target):
		shop_manager.upgrade_needs_target.connect(_on_upgrade_needs_target)

## Refresh the shop - populate all slots
func refresh_shop(round_number: int):
	if not shop_manager:
		print("[VisualShopGrid] ERROR: shop_manager not set!")
		return
	
	# Clear all slots
	clear_all_slots()
	
	# Generate shop inventory
	shop_manager.refresh_shop(round_number)

## Called when shop manager refreshes
func _on_shop_refreshed(items: Array):
	print("[VisualShopGrid] Shop refreshed with %d items" % items.size())
	
	if auto_populate:
		_auto_populate_slots(items)
	
	# Generate free samples
	_generate_free_samples()

## Automatically populate slots with shop items
func _auto_populate_slots(items: Array):
	var ingredient_items: Array[Dictionary] = []
	var upgrade_items: Array[Dictionary] = []
	var relic_items: Array[Dictionary] = []
	
	# Sort items by type
	for item in items:
		match item.get("type"):
			ShopManager.ShopItemType.NEW_INGREDIENT:
				ingredient_items.append(item)
			ShopManager.ShopItemType.INGREDIENT_UPGRADE:
				upgrade_items.append(item)
			ShopManager.ShopItemType.RELIC:
				relic_items.append(item)
	
	# Fill slots based on their type preference
	var items_to_place = items.duplicate()
	
	# First pass: Fill type-specific slots
	for slot in paid_slots:
		if items_to_place.is_empty():
			break
		
		var placed = false
		for i in range(items_to_place.size()):
			var item = items_to_place[i]
			if slot.can_accept_item(item):
				slot.set_item(item, shop_manager, currency_manager, fridge_manager, progression_manager)
				# Connect slot signals
				slot.item_clicked.connect(_on_slot_item_clicked)
				items_to_place.remove_at(i)
				placed = true
				break
		
		if placed:
			continue
	
	# Second pass: Fill ANY slots with remaining items
	for slot in paid_slots:
		if items_to_place.is_empty():
			break
		
		if slot.slot_type == ShopSlot.SlotType.ANY and not slot.is_occupied:
			var item = items_to_place.pop_front()
			slot.set_item(item, shop_manager, currency_manager, fridge_manager, progression_manager)
			# Connect slot signals
			slot.item_clicked.connect(_on_slot_item_clicked)
	
	all_slots_filled.emit()

## Generate free sample items
func _generate_free_samples():
	if free_sample_slots.is_empty():
		print("[VisualShopGrid] No free sample slots available")
		return
	
	var samples: Array[Dictionary] = []
	
	# Get available ingredients based on progression
	var available_ingredients = IngredientsData.get_all_ingredients()
	
	# Generate random samples
	var sample_count = min(free_sample_count, free_sample_slots.size())
	for i in range(sample_count):
		if available_ingredients.is_empty():
			break
		
		var random_ingredient = available_ingredients[randi() % available_ingredients.size()]
		
		var sample_item = {
			"type": ShopManager.ShopItemType.NEW_INGREDIENT,
			"name": random_ingredient.name,
			"description": "Free Sample!",
			"cost": 0,
			"is_free": true,
			"ingredient": random_ingredient
		}
		
		samples.append(sample_item)
		
		# Place in free sample slot
		if i < free_sample_slots.size():
			free_sample_slots[i].set_item(sample_item, shop_manager, currency_manager)
	
	print("[VisualShopGrid] Generated %d free samples" % samples.size())
	free_samples_ready.emit(samples)

## Clear all slots
func clear_all_slots():
	for slot in all_slots:
		slot.clear_slot()

## Get all available free samples
func get_free_samples() -> Array[Dictionary]:
	var samples: Array[Dictionary] = []
	for slot in free_sample_slots:
		if slot.is_occupied and slot.current_item.get("is_free", false):
			samples.append(slot.current_item)
	return samples

## Mark a free sample as taken
func mark_free_sample_taken(sample_item: Dictionary):
	for slot in free_sample_slots:
		if slot.current_item == sample_item:
			slot._mark_as_taken()
			return
