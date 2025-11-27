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
	
	samples_taken = 0  # Reset counter
	_update_free_samples_label()  # Update label at start
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
			"ingredient": random_ingredient.duplicate()
		}
		
		samples.append(sample_item)
		
		# Place in free sample slot
		if i < free_sample_slots.size():
			# First slot (index 0) is REVEALED, rest are MYSTERY BOXES
			if i == 0:
				# Revealed sample - mark as seen from the start
				free_sample_slots[i].is_sample_seen = true
			
			free_sample_slots[i].set_item(sample_item, shop_manager, currency_manager, fridge_manager, progression_manager)
			# Connect free sample signal
			free_sample_slots[i].free_sample_taken.connect(_on_free_sample_taken)
	
	print("[VisualShopGrid] Generated %d free samples (1 revealed, %d mystery)" % [samples.size(), samples.size() - 1])
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

## Handle free sample taken
func _on_free_sample_taken(item: Dictionary, slot: ShopSlot):
	# Check if can take this sample based on the NEW rule:
	# - Can take the 1 REVEALED sample + 1 MYSTERY sample
	# - OR can take 2 MYSTERY samples
	# - Once you take the revealed sample, you can only take 1 mystery
	
	var can_take = false
	var reason = ""
	
	# Count how many mystery boxes have been taken
	var mystery_taken = 0
	var revealed_taken = false
	
	for s in free_sample_slots:
		if s.current_item.has("is_free") and s.current_item.is_free:
			# Check if this slot was taken (button says TAKEN)
			var content = s.content_container
			if content:
				for child in content.get_children():
					if _has_taken_button(child):
						if s.is_sample_seen:
							revealed_taken = true
						else:
							mystery_taken += 1
						break
	
	print("[VisualShopGrid] Current state: revealed_taken=%s, mystery_taken=%d" % [revealed_taken, mystery_taken])
	
	if slot.is_sample_seen:
		# Trying to take the REVEALED sample
		if not revealed_taken:
			can_take = true
			reason = "Revealed sample taken (can take 1 more mystery)"
		else:
			reason = "You already took the revealed sample!"
	else:
		# Trying to take a MYSTERY sample
		if revealed_taken:
			# Already took revealed, can only take 1 mystery
			if mystery_taken < 1:
				can_take = true
				reason = "Mystery sample taken (with revealed)"
			else:
				reason = "You already took revealed + 1 mystery!\nRule: (Revealed + 1 Mystery) OR (2 Mystery)"
		else:
			# Haven't taken revealed, can take up to 2 mystery
			if mystery_taken < 2:
				can_take = true
				reason = "Mystery sample taken (%d/2)" % (mystery_taken + 1)
			else:
				reason = "You already took 2 mystery samples!\nRule: (Revealed + 1 Mystery) OR (2 Mystery)"
	
	if can_take:
		# Add ingredient to deck
		if fridge_manager and item.has("ingredient"):
			fridge_manager.add_ingredient_to_deck(item.ingredient)
			print("[VisualShopGrid] %s: %s" % [reason, item.get("name", "")])
			_show_message("Added %s to deck!\n%s" % [item.get("name", ""), reason])
			
			# Update the free samples label to show remaining
			_update_free_samples_label_dynamic()
	else:
		print("[VisualShopGrid] Cannot take sample: %s" % reason)
		_show_message(reason)

## Helper to check if a node tree has a TAKEN button
func _has_taken_button(node: Node) -> bool:
	if node is Button and node.text == "TAKEN":
		return true
	for child in node.get_children():
		if _has_taken_button(child):
			return true
	return false

## Update free samples label dynamically based on what's taken
func _update_free_samples_label_dynamic():
	var label = get_node_or_null("FreeSamplesLabel")
	if not label:
		return
	
	# Count what's been taken
	var mystery_taken = 0
	var revealed_taken = false
	
	for s in free_sample_slots:
		if s.current_item.has("is_free") and s.current_item.is_free:
			var content = s.content_container
			if content:
				for child in content.get_children():
					if _has_taken_button(child):
						if s.is_sample_seen:
							revealed_taken = true
						else:
							mystery_taken += 1
						break
	
	if revealed_taken and mystery_taken >= 1:
		label.text = "FREE SAMPLES (All taken!)"
	elif mystery_taken >= 2:
		label.text = "FREE SAMPLES (All taken!)"
	elif revealed_taken:
		label.text = "FREE SAMPLES (Can take 1 mystery)"
	elif mystery_taken == 1:
		label.text = "FREE SAMPLES (Can take 1 more mystery OR the revealed)"
	else:
		label.text = "FREE SAMPLES (Revealed + 1 Mystery) OR (2 Mystery)"

## Handle paid item clicked (show purchase confirmation)
func _on_slot_item_clicked(item: Dictionary, slot: ShopSlot):
	_show_purchase_prompt(item, slot)

## Show purchase confirmation prompt
func _show_purchase_prompt(item: Dictionary, slot: ShopSlot):
	var popup = AcceptDialog.new()
	popup.title = "Purchase Item"
	
	var current_currency = currency_manager.get_currency()
	var item_cost = item.get("cost", 0)
	var can_afford = current_currency >= item_cost
	
	if can_afford:
		popup.dialog_text = "Purchase %s for %d currency?\n\nYour currency: %d\nAfter purchase: %d" % [
			item.get("name", "Item"),
			item_cost,
			current_currency,
			current_currency - item_cost
		]
		popup.ok_button_text = "BUY"
		popup.add_cancel_button("Cancel")
	else:
		popup.dialog_text = "Cannot afford %s!\n\nCost: %d\nYour currency: %d\nNeed: %d more" % [
			item.get("name", "Item"),
			item_cost,
			current_currency,
			item_cost - current_currency
		]
		popup.ok_button_text = "OK"
		can_afford = false
	
	add_child(popup)
	popup.popup_centered()
	
	# Handle purchase
	if can_afford:
		popup.confirmed.connect(func():
			_purchase_item(item, slot)
			popup.queue_free()
		)
		popup.canceled.connect(func(): popup.queue_free())
	else:
		popup.confirmed.connect(func(): popup.queue_free())
	
	popup.close_requested.connect(func(): popup.queue_free())

## Purchase an item from a slot
func _purchase_item(item: Dictionary, slot: ShopSlot):
	if shop_manager.purchase_item(item):
		print("[VisualShopGrid] Purchased: %s" % item.get("name", ""))
		slot._mark_as_sold()
		# Currency display will be updated via EventBus.currency_changed signal
	else:
		_show_message("Purchase failed!")

## Handle upgrade needs target (open card selector)
func _on_upgrade_needs_target(upgrade_data: Dictionary):
	if card_selector:
		print("[VisualShopGrid] Opening card selector for upgrade")
		card_selector.open_with_upgrade(upgrade_data, fridge_manager)

## Show a temporary message
func _show_message(message: String):
	var popup = AcceptDialog.new()
	popup.dialog_text = message
	popup.title = ""
	popup.ok_button_text = "OK"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())
	popup.close_requested.connect(func(): popup.queue_free())
