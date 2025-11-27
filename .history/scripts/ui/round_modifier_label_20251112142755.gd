extends Label
class_name RoundModifierLabel

## Displays the current round modifier with a tooltip on hover

var current_modifier: RoundModifierModel = null

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP  # Enable mouse events
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

## Update the label with a new modifier
func set_modifier(modifier: RoundModifierModel) -> void:
	current_modifier = modifier
	if modifier:
		text = "⚡ %s" % modifier.name
		tooltip_text = modifier.description
		
		# Color code by effect type
		match modifier.modifier_type:
			RoundModifierModel.ModifierType.DRAIN_MULTIPLIER:
				if modifier.value > 1.0:
					modulate = Color(1.0, 0.5, 0.5)  # Red for harder
				elif modifier.value < 1.0:
					modulate = Color(0.5, 1.0, 0.5)  # Green for easier
				else:
					modulate = Color.WHITE
			
			RoundModifierModel.ModifierType.TIMER_BONUS:
				if modifier.value > 0:
					modulate = Color(0.5, 1.0, 0.5)  # Green for more time
				elif modifier.value < 0:
					modulate = Color(1.0, 0.5, 0.5)  # Red for less time
				else:
					modulate = Color.WHITE
			
			RoundModifierModel.ModifierType.MOISTURE_BONUS:
				if modifier.value > 0:
					modulate = Color(0.5, 0.8, 1.0)  # Blue for more moisture
				elif modifier.value < 0:
					modulate = Color(1.0, 0.6, 0.3)  # Orange for less moisture
				else:
					modulate = Color.WHITE
			
			RoundModifierModel.ModifierType.CURRENCY_BONUS:
				modulate = Color(1.0, 0.9, 0.3)  # Gold for currency
			
			RoundModifierModel.ModifierType.SHOP_DISCOUNT:
				modulate = Color(0.7, 0.5, 1.0)  # Purple for shop
			
			RoundModifierModel.ModifierType.VOLATILITY_CHANGE:
				modulate = Color(1.0, 0.5, 0.5)  # Red for volatility
			
			_:
				modulate = Color.WHITE
	else:
		text = ""
		tooltip_text = ""
		modulate = Color.WHITE

## Clear the modifier display
func clear_modifier() -> void:
	set_modifier(null)

func _on_mouse_entered() -> void:
	if current_modifier:
		# Slightly brighten on hover
		modulate = modulate * 1.2

func _on_mouse_exited() -> void:
	# Reset to original color (reapply modifier to restore color)
	if current_modifier:
		set_modifier(current_modifier)
