# Testing the Ingredient Sprite Spreading Implementation

## Quick Start

To test this implementation in Godot:

1. **Open the project in Godot 4.x**
   ```bash
   # Open Godot and import the project
   # Navigate to project.godot
   ```

2. **Run the game (F5)**
   - The main game scene will load
   - Proceed through the draft selector to pick ingredients
   - Select ingredients to cook

3. **Observe the visual changes:**

### What to Look For:

#### 1. Draft Selector (First Screen)
- Above each ingredient card, you should see a colored rectangular sprite
- The color is unique to each ingredient
- Multiple cards of the same ingredient should show the same color

#### 2. Ingredient Selector (After Draft)
- Each ingredient card displays a colored sprite box at the top
- Sprites maintain their colors from the draft selector
- Cards are arranged in a grid

#### 3. Plate Display (During Cooking Round)
- **NEW**: A PlateDisplay should appear in the center of the screen
- Shows the 2 selected ingredients as colored overlapping sprites
- Sprites overlap by approximately 15-20 pixels
- The display:
  - Appears when cooking starts
  - Remains visible during the round
  - Disappears when the round ends

## Visual Verification Checklist

### ✅ Card Display
- [ ] Draft cards show colored sprite boxes
- [ ] Ingredient selector cards show colored sprite boxes
- [ ] Colors are consistent for the same ingredient
- [ ] Different ingredients have different colors
- [ ] Sprite boxes are positioned above the button text

### ✅ Overlap Effect
- [ ] Multiple ingredients in cards show side-by-side
- [ ] When 2+ ingredients are shown, they overlap slightly
- [ ] The overlap creates a "stacked" visual effect
- [ ] Sprites don't completely cover each other (partial overlap)

### ✅ Plate Display
- [ ] PlateDisplay appears when cooking starts
- [ ] Shows exactly 2 ingredient sprites (or 1 sprite twice for same ingredient)
- [ ] Sprites overlap horizontally
- [ ] Display is centered in the game area
- [ ] PlateDisplay disappears when round ends (win or lose)

### ✅ Color Consistency
- [ ] "Chicken" always appears as the same color
- [ ] "Lettuce" always appears as the same color
- [ ] High water content ingredients are more saturated
- [ ] High density ingredients are brighter

## Running the Test Script

To run automated tests:

1. **Create a test scene:**
   ```
   - Create new scene in Godot
   - Add Node as root
   - Attach scripts/tests/test_ingredient_sprite_spreading.gd
   - Save as test_scene.tscn
   ```

2. **Run the test scene:**
   ```
   - Press F6 to run current scene
   - Check console output for test results
   ```

3. **Expected output:**
   ```
   === Testing Ingredient Sprite Spreading ===
   
   Test 1: Color generation...
   Test 2: Sprite container creation...
   Test 3: Overlap configuration...
   Test 4: Plate display logic...
   
   === Test Results ===
   ✓ Same ingredient produces same color
   ✓ Different ingredients produce different colors
   ✓ Container can hold multiple sprite panels
   ✓ Negative separation applies correctly
   ✓ Two different ingredients → 2 sprites
   ✓ Same ingredient twice → 2 sprites
   
   === Tests Complete ===
   ```

## Manual Testing Scenarios

### Scenario 1: Single Ingredient Twice
1. Draft/select the same ingredient twice
2. Start cooking
3. **Expected:** PlateDisplay shows 2 sprite boxes of the same color, overlapping

### Scenario 2: Two Different Ingredients
1. Draft/select two different ingredients
2. Start cooking
3. **Expected:** PlateDisplay shows 2 sprite boxes of different colors, overlapping

### Scenario 3: Draft Multiple Rounds
1. Play through multiple cooking rounds
2. Draft new ingredients each time
3. **Expected:** 
   - Ingredient colors remain consistent across rounds
   - New ingredients get new unique colors
   - Card displays always show sprites

### Scenario 4: Visual Progression
1. Start game → See draft cards with sprites
2. Select ingredients → See ingredient cards with sprites
3. Start cooking → See plate display with overlapping sprites
4. End round → Plate display disappears
5. Next draft → See draft cards again with sprites

## Troubleshooting

### Issue: No sprites visible on cards
**Check:**
- Inspect the scene tree during runtime
- Verify VBoxContainer exists with sprite container child
- Check console for errors about missing ingredient model

### Issue: Sprites not overlapping
**Check:**
- HBoxContainer separation value (should be negative, e.g., -15)
- Use Godot inspector to view separation property
- Verify multiple sprites are actually being created

### Issue: PlateDisplay not showing
**Check:**
- PlateDisplay node exists in main.tscn
- Script is attached correctly
- EventBus signals are connected (round_started, round_completed)
- PlateDisplay is child of UI CanvasLayer

### Issue: All ingredients same color
**Check:**
- Color generation uses ingredient.name (not instance)
- Hash function is working correctly
- HSV values are in correct range (0-1)

## Performance Notes

- Sprite containers are lightweight (just Panels and ColorRects)
- Creating/destroying happens only during transitions
- No per-frame updates needed for static displays
- Minimal memory footprint

## Configuration for Testing

You can adjust these values for testing:

### Make overlap more obvious:
```gdscript
# In draft_selector.gd line ~194
container.add_theme_constant_override("separation", -30)  # Increase overlap
```

### Make sprites larger:
```gdscript
# In draft_selector.gd line ~198
panel.custom_minimum_size = Vector2(80, 60)  # Larger sprites
```

### Change colors:
```gdscript
# In _get_ingredient_color() function
saturation = 1.0  # Maximum saturation (more vivid)
value = 1.0  # Maximum brightness
```

## Expected Visual Appearance

### Card with Sprite (ASCII Art):
```
┌─────────────────┐
│   ┌────┐        │ ← Colored sprite (50x35)
│   │████│        │
│   └────┘        │
├─────────────────┤
│ [INGREDIENT]    │
│ Lettuce         │ ← Button with text
│ Water: 95       │
│ Heat Res: 20    │
└─────────────────┘
```

### Plate Display (ASCII Art):
```
   Centered in screen
   ┌──────────────┐
   │  ┌───┐┌───┐  │ ← Two sprites overlapping
   │  │███││███│  │   Visible during cooking
   │  └───┘└───┘  │
   └──────────────┘
```

## Success Criteria

The implementation is successful if:
1. ✅ Ingredients display as colored sprites in cards
2. ✅ Multiple ingredients overlap horizontally
3. ✅ PlateDisplay shows during cooking rounds
4. ✅ Colors are consistent and deterministic
5. ✅ No errors in console
6. ✅ Smooth transitions (show/hide)
7. ✅ Works across all UI contexts (draft, selector, plate)

## Next Steps

After verifying the implementation works:
1. Gather feedback on overlap amount (too much/little?)
2. Adjust sprite sizes if needed
3. Add real ingredient sprite images when available
4. Consider adding hover effects or animations
5. Possibly add ingredient icons/symbols to sprites

## Questions to Ask

- Does the overlap amount (15-20px) look good?
- Are the sprite sizes appropriate (50x35 for cards, 80x80 for plate)?
- Should sprites have borders or shadows?
- Should there be a subtle animation when they appear?
- Are the colors distinguishable enough?

## Documentation

See these files for more details:
- `INGREDIENT_SPRITE_IMPLEMENTATION.md` - Technical implementation details
- `VISUAL_EXAMPLES.md` - Visual examples and configuration
- `scripts/ui/ingredient_sprite_container.gd` - Reusable component
- `scripts/ui/plate_display.gd` - Plate display component
