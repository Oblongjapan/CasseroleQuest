extends Label

## UI display for fridge deck count

var fridge_manager: FridgeManager

func _ready():
	# Connect to deck changed signal
	EventBus.deck_changed.connect(_on_deck_changed)
	print("[DeckTracker] Connected to deck_changed signal")

func _exit_tree():
	# Disconnect from EventBus when this node is removed
	if EventBus.deck_changed.is_connected(_on_deck_changed):
		EventBus.deck_changed.disconnect(_on_deck_changed)
	print("[DeckTracker] Disconnected from deck_changed signal")

## Initialize with fridge manager reference
func setup(fridge: FridgeManager) -> void:
	fridge_manager = fridge
	_update_display()

## Update the deck count display
func _update_display() -> void:
	if not fridge_manager:
		text = "Deck: ?/?"
		return
	
	var cards_in_deck = fridge_manager.deck.size()
	var cards_in_discard = fridge_manager.discard_pile.size()
	var total_cards = cards_in_deck + cards_in_discard
	
	text = "Deck: %d/%d" % [cards_in_deck, total_cards]
	
	# Optional: Add color coding
	if cards_in_deck == 0:
		modulate = Color.RED  # No cards left to draw
	elif cards_in_deck <= 2:
		modulate = Color.YELLOW  # Low on cards
	else:
		modulate = Color.WHITE

## Handle deck changed signal
func _on_deck_changed(cards_in_deck: int, total_cards: int) -> void:
	print("[DeckTracker] Signal received - Deck: %d, Total: %d" % [cards_in_deck, total_cards])
	text = "%d/%d" % [cards_in_deck, total_cards]
	
	# Color coding
	if cards_in_deck == 0:
		modulate = Color.RED
	elif cards_in_deck <= 2:
		modulate = Color.YELLOW
	else:
		modulate = Color.WHITE

## Call this whenever cards are drawn or discarded (legacy method)
func refresh() -> void:
	_update_display()
