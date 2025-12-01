extends Control
class_name RecipeDiscoveryReveal

## Shows newly discovered recipes one by one after game over
## Player clicks to fade out current recipe and show next one

@onready var recipe_card_container: Control = $RecipeCardContainer
@onready var click_to_continue_label: Label = $ClickToContinueLabel
@onready var discoveries_label: Label = $DiscoveriesLabel

const RecipeCardRevealScene = preload("res://scenes/recipe_card_reveal.tscn")

var discoveries_queue: Array[Dictionary] = []
var current_card: Node = null
var on_complete_callback: Callable

signal reveal_complete

func _ready():
	hide()
	
	# Make clickable to advance
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_next_discovery()

## Setup and show the discovery reveal sequence
func show_discoveries(discoveries: Array[Dictionary], on_complete: Callable = Callable()):
	if discoveries.is_empty():
		print("[RecipeDiscoveryReveal] No discoveries to show")
		if on_complete.is_valid():
			on_complete.call()
		return
	
	discoveries_queue = discoveries.duplicate()
	on_complete_callback = on_complete
	
	# Update header label
	if discoveries_label:
		discoveries_label.text = "New Recipes Discovered: %d" % discoveries_queue.size()
	
	show()
	z_index = 150  # Above everything
	_show_next_discovery()

## Show the next recipe in the queue
func _show_next_discovery():
	# Fade out current card if it exists
	if current_card:
		_fade_out_current_card()
		return
	
	# Check if queue is empty
	if discoveries_queue.is_empty():
		_finish_reveal()
		return
	
	# Get next discovery
	var discovery = discoveries_queue.pop_front()
	print("[RecipeDiscoveryReveal] Showing discovery: %s" % discovery.get("display_name", "Unknown"))
	
	# Create and show recipe card
	var card = RecipeCardRevealScene.instantiate()
	recipe_card_container.add_child(card)
	current_card = card
	
	# Setup card with discovery data
	var ingredient_names = discovery.get("identity", "").split("+")
	if card.has_method("setup_from_ingredients"):
		card.setup_from_ingredients(ingredient_names, discovery.get("display_name", ""))
	
	# Animate in
	card.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(card, "modulate:a", 1.0, 0.5)
	
	# Update counter
	if discoveries_label:
		var remaining = discoveries_queue.size()
		discoveries_label.text = "New Recipes Discovered: %d remaining" % remaining

## Fade out and remove current card
func _fade_out_current_card():
	if not current_card:
		return
	
	var card_to_remove = current_card
	current_card = null
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(card_to_remove, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		card_to_remove.queue_free()
		_show_next_discovery()
	)

## Finish the reveal sequence
func _finish_reveal():
	print("[RecipeDiscoveryReveal] All discoveries shown")
	
	# Fade out the whole screen
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		hide()
		modulate.a = 1.0  # Reset for next time
		reveal_complete.emit()
		
		# Call completion callback
		if on_complete_callback.is_valid():
			on_complete_callback.call()
	)
