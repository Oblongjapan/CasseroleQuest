extends Label

## UI display for fridge deck count

var fridge_manager: FridgeManager

func _ready():
	# Will be set up by main.gd
	pass

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

## Call this whenever cards are drawn or discarded
func refresh() -> void:
	_update_display()
