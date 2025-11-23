# Visual Shop Grid System

## Overview
A flexible, editor-based shop layout system where you can manually place and arrange shop slots in the Godot scene editor.

## Files Created
- `scripts/ui/shop_slot.gd` - Individual shop slot component
- `scripts/ui/visual_shop_grid.gd` - Grid manager that populates slots
- `scenes/shop_slot.tscn` - Shop slot scene
- `scenes/visual_shop_grid.tscn` - Complete shop layout template

## How to Use

### 1. Open the Visual Shop Grid Scene
Open `scenes/visual_shop_grid.tscn` in the Godot editor.

### 2. Customize the Layout
You can now:
- **Move slots around** - Drag and position ShopSlot nodes anywhere
- **Add more slots** - Instance `shop_slot.tscn` and add to the grid
- **Remove slots** - Delete unwanted slot nodes
- **Change slot types** - Select a slot and change its `slot_type` property:
  - `INGREDIENT` - Only shows ingredient cards
  - `UPGRADE` - Only shows upgrade cards  
  - `RELIC` - Only shows relic cards
  - `FREE_SAMPLE` - For free ingredient samples
  - `ANY` - Can show any item type

### 3. Configure Free Samples
To create free sample slots:
1. Select a ShopSlot node
2. Enable `is_free_sample` checkbox
3. Set `slot_type` to `FREE_SAMPLE`
4. Adjust the grid's `free_sample_count` property

### 4. Layout Examples

#### Default Layout (Included)
```
FREE SAMPLES
[Sample 1] [Sample 2] [Sample 3]

FOR SALE
[Ingredient] [Upgrade]   [Upgrade]   [Relic]
[Ingredient] [Any Item]  [Any Item]  [Any Item]
```

#### Alternative: Two-Column Layout
```
FREE SAMPLES        FOR SALE
[Sample 1]          [Ingredient]
[Sample 2]          [Upgrade]
[Sample 3]          [Relic]
                    [Any]
```

#### Alternative: Compact Layout
```
[Free] [Free] [Free] | [Item] [Item] [Item] [Item]
```

### 5. Integration

To integrate with your existing shop system:

```gdscript
# In your shop screen or main game controller
@onready var visual_shop: VisualShopGrid = $VisualShopGrid

func show_shop():
    # Setup managers
    visual_shop.setup(shop_manager, currency_manager, fridge_manager)
    
    # Refresh the shop (auto-populates slots)
    visual_shop.refresh_shop(current_round_number)
    
    # Connect signals
    visual_shop.free_samples_ready.connect(_on_free_samples_ready)
    visual_shop.all_slots_filled.connect(_on_shop_ready)

func _on_free_samples_ready(samples: Array[Dictionary]):
    print("Player can choose from %d free samples" % samples.size())
```

## Shop Slot Properties

### Exported Variables
- `slot_type` (SlotType enum) - What type of items this slot accepts
- `slot_label` (String) - Label shown when slot is empty
- `is_free_sample` (bool) - If true, items in this slot are free

### Methods
- `can_accept_item(item: Dictionary) -> bool` - Check if slot accepts this item type
- `set_item(item, shop_mgr, currency_mgr)` - Place an item in the slot
- `clear_slot()` - Remove the item and reset

## Visual Shop Grid Properties

### Exported Variables
- `auto_populate` (bool) - Automatically fill slots when shop refreshes (default: true)
- `free_sample_count` (int) - How many free samples to generate (default: 3)

### Signals
- `all_slots_filled()` - Emitted when all paid slots are populated
- `free_samples_ready(samples: Array[Dictionary])` - Emitted when free samples are generated

## Styling Tips

### Custom Slot Colors
Slots automatically color their borders based on type:
- Green = Ingredients
- Blue = Upgrades  
- Purple = Relics
- Gold = Free Samples
- White = Any type

### Adjusting Slot Size
Select a ShopSlot node and modify:
- `custom_minimum_size` - Change width/height
- Position using anchors/offsets

### Grouping Slots
Use Container nodes to organize slots:
- `HBoxContainer` - Horizontal row
- `VBoxContainer` - Vertical column
- `GridContainer` - Grid layout
- `Control` - Manual positioning

## Next Steps

1. **Open `scenes/visual_shop_grid.tscn`** in Godot
2. **Rearrange the slots** to your liking
3. **Add/remove slots** as needed
4. **Test in-game** to see how items populate
5. **Customize styling** with themes/shaders

## Advanced: Creating Custom Slot Layouts

Example: Create a "Featured Item" mega-slot:

1. Instance a ShopSlot
2. Scale it up: `custom_minimum_size = Vector2(400, 400)`
3. Set `slot_type = ANY`
4. Position it prominently at the top
5. In code, manually place your best item there first

This gives you full control over shop presentation while keeping the logic automated!
