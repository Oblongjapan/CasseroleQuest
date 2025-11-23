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
			free_sample_slots[i].set_item(sample_item, shop_manager, currency_manager, fridge_manager, progression_manager)
			# Connect free sample signal
			free_sample_slots[i].free_sample_taken.connect(_on_free_sample_taken)
	
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

## Handle free sample taken
func _on_free_sample_taken(item: Dictionary, slot: ShopSlot):
	# Check if can take this sample based on the rule:
	# - Can take up to 2 UNSEEN (mystery box) samples
	# - OR can take 1 SEEN (revealed) sample
	# - Once you reveal and take a sample, you can't take any more
	
	var can_take = false
	var reason = ""
	
	if not slot.is_sample_seen:
		# This is an UNSEEN mystery box sample
		if samples_taken < max_unseen_samples:
			can_take = true
			samples_taken += 1
			reason = "Unseen sample taken (%d/%d)" % [samples_taken, max_unseen_samples]
		else:
			reason = "You've already taken %d unseen samples! (Max: %d)" % [samples_taken, max_unseen_samples]
	else:
		# This is a SEEN (revealed) sample
		# Can only take a seen sample if NO samples have been taken yet
		if samples_taken == 0:
			can_take = true
			# Taking a seen sample counts as using ALL your samples
			samples_taken = max_unseen_samples
			reason = "Seen sample taken (counts as all samples)"
		else:
			reason = "You can only take 2 unseen samples OR 1 seen sample!\nYou already took unseen samples."
	
	if can_take:
		# Add ingredient to deck
		if fridge_manager and item.has("ingredient"):
			fridge_manager.add_ingredient_to_deck(item.ingredient)
			print("[VisualShopGrid] %s: %s" % [reason, item.get("name", "")])
			_show_message("Added %s to deck!\n%s" % [item.get("name", ""), reason])
			
			# Update the free samples label to show remaining
			_update_free_samples_label()
	else:
		print("[VisualShopGrid] Cannot take sample: %s" % reason)
		_show_message(reason)

## Update free samples label to show how many are left
func _update_free_samples_label():
	var label = get_node_or_null("FreeSamplesLabel")
	if label:
		var remaining = max_unseen_samples - samples_taken
		if samples_taken >= max_unseen_samples:
			label.text = "FREE SAMPLES (All taken!)"
		else:
			label.text = "FREE SAMPLES (%d unseen left OR 1 seen)" % remaining

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

## Update currency display (to be overridden or connected to UI label)
func _update_currency_display():
	# Emit signal or update label if you have one
	pass
