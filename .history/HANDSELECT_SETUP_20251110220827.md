# HandSelector Setup Guide

## The Problem
The HandSelector isn't showing up because the scene node doesn't exist yet in `main.tscn`.

## Quick Fix - Option 1: Add the Node

### In Godot Editor:

1. **Open** `scenes/main.tscn`

2. **Find the UI node** in the scene tree

3. **Right-click UI** → Add Child Node

4. **Search for "Panel"** → Click Create

5. **Rename** the new Panel to `HandSelector`

6. **With HandSelector selected**, in the Inspector:
   - Click the script icon (📜) next to "Script"
   - Click "Load"
   - Navigate to `scripts/ui/hand_selector.gd`
   - Click "Open"

7. **Add children to HandSelector**:
   - Right-click HandSelector → Add Child Node → VBoxContainer
   - Right-click VBoxContainer → Add Child Node → Label → Rename to `TitleLabel`
   - Right-click VBoxContainer → Add Child Node → Label → Rename to `InfoLabel`
   - Right-click VBoxContainer → Add Child Node → GridContainer → Rename to `HandGrid`
     - Select HandGrid → In Inspector → Columns = 3
   - Right-click VBoxContainer → Add Child Node → Button → Rename to `ConfirmButton`
     - Select ConfirmButton → In Inspector → Text = "Cook These 2"

8. **Position HandSelector**:
   - Select HandSelector
   - In Inspector → Layout → Preset → "Center"
   - Or set custom_minimum_size to Vector2(600, 400)

9. **Set visibility**:
   - Select HandSelector
   - In Inspector → Visibility → **Visible = OFF** (uncheck the box)

10. **Save** the scene (Ctrl+S)

11. **Run** the game (F5)

---

## Quick Fix - Option 2: Use Fallback

If you don't want to set up the HandSelector node right now, the game will use a fallback:

**What happens:**
- Console shows: "Warning: HandSelector node not found! Using ingredient selector instead."
- Game draws 2 cards automatically and starts cooking
- No hand selection, just like before

**To see this:**
- Just run the game as-is
- Check the Output console for the warning message
- Game will still be playable

---

## Testing

After adding the HandSelector node:

1. **Run the game** (F5)
2. **Check console** for:
   ```
   [Main] HandSelector connected successfully
   [HandSelector] show_hand_selection called
   [HandSelector] Drew 3 cards
   [HandSelector] Showing panel
   ```
3. **Should see**: 3 ingredient cards on screen
4. **Click 2 cards** → They turn green
5. **Click "Cook These 2"** → Start cooking

---

## Troubleshooting

### "HandSelector node not found"
- Node doesn't exist in scene tree
- Solution: Follow "Quick Fix - Option 1" above

### "ConfirmButton not found!"
- VBoxContainer children are missing
- Solution: Add all 4 children (TitleLabel, InfoLabel, HandGrid, ConfirmButton)

### Cards don't show up
- HandGrid might not exist
- Solution: Make sure GridContainer is named "HandGrid" exactly

### Can't click cards
- Cards are generated dynamically - this is normal
- They appear when show_hand_selection() is called

---

## Verification Checklist

Scene tree should look like this:

```
Main
└── UI/
    ├── MainMenu
    ├── HandSelector ← NEW! (with script attached)
    │   └── VBoxContainer/
    │       ├── TitleLabel
    │       ├── InfoLabel
    │       ├── HandGrid (GridContainer, columns=3)
    │       └── ConfirmButton
    ├── IngredientSelector
    ├── CookingUI
    ├── RoundCompleteScreen
    ├── RoundFailedScreen
    └── ShopScreen
```

✅ All node names match exactly (case-sensitive!)
✅ Script attached to HandSelector panel
✅ HandSelector starts hidden (visible = false)
✅ GridContainer has columns set to 3

---

## Current Status

**Code changes made:**
- ✅ Added fallback in main.gd (works without HandSelector node)
- ✅ Added debug prints to track execution
- ✅ Added null checks in hand_selector.gd

**What you need to do:**
- 🔲 Add HandSelector node to scene (see Option 1 above)
- OR just run game with fallback (see Option 2)

Game is playable either way!
