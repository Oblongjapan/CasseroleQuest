# 🎨 SCENE TREE SETUP GUIDE

This document shows the **exact scene tree structure** needed for the game to work.

---

## 📋 COMPLETE SCENE TREE

```
Main (Node - scripts/main.gd)
│
├── CookRound (Node)
│   ├── MoistureManager (Node - scripts/managers/moisture_manager.gd)
│   ├── TimerManager (Node - scripts/managers/timer_manager.gd)
│   └── ItemManager (Node - scripts/managers/active_item_manager.gd)
│
└── UI (Control)
    │
    ├── MainMenu (Panel - scripts/ui/main_menu.gd)
    │   └── VBoxContainer
    │       ├── TitleLabel (Label) - text: "MICROWAVE WAVE"
    │       ├── TaglineLabel (Label) - text: "A Microwave's Thirst"
    │       ├── StartButton (Button) - text: "Start Game"
    │       └── QuitButton (Button) - text: "Quit"
    │
    ├── IngredientSelector (Panel - scripts/ui/ingredient_selector.gd)
    │   └── VBoxContainer
    │       ├── TitleLabel (Label)
    │       ├── RoundLabel (Label)
    │       ├── CurrencyLabel (Label)
    │       ├── IngredientGrid (GridContainer) - columns: 2
    │       ├── DrainPreviewLabel (Label)
    │       └── StartButton (Button) - text: "COOK FOR 15 SECONDS"
    │
    ├── CookingUI (Control)
    │   ├── MoistureBar (TextureProgressBar or ProgressBar)
    │   ├── TimerDisplay (Label)
    │   └── ActiveItemsContainer (HBoxContainer)
    │       ├── ActiveItemButton_1 (Button - scripts/ui/active_item_button_ui.gd)
    │       ├── ActiveItemButton_2 (Button - scripts/ui/active_item_button_ui.gd)
    │       └── ActiveItemButton_3 (Button - scripts/ui/active_item_button_ui.gd)
    │
    ├── RoundCompleteScreen (Panel - scripts/ui/round_complete_screen.gd)
    │   └── VBoxContainer
    │       ├── TitleLabel (Label)
    │       ├── MoistureLabel (Label)
    │       ├── CurrencyEarnedLabel (Label)
    │       ├── TotalCurrencyLabel (Label)
    │       └── ContinueButton (Button) - text: "Continue to Shop"
    │
    ├── RoundFailedScreen (Panel - scripts/ui/round_failed_screen.gd)
    │   └── VBoxContainer
    │       ├── TitleLabel (Label)
    │       ├── MoistureLabel (Label)
    │       ├── TimeLabel (Label)
    │       ├── MessageLabel (Label)
    │       └── ButtonsContainer (HBoxContainer)
    │           ├── RetryButton (Button) - text: "Retry"
    │           └── MenuButton (Button) - text: "Main Menu"
    │
    ├── ShopScreen (Panel - scripts/ui/shop_screen.gd)
    │   └── ScrollContainer
    │       └── VBoxContainer
    │           ├── TitleLabel (Label)
    │           ├── CurrencyLabel (Label)
    │           ├── RoundLabel (Label)
    │           ├── ShopGrid (GridContainer) - columns: 2
    │           └── DoneButton (Button) - text: "Done Shopping"
    │
    ├── StatusLabel (Label) - for debugging/status messages
    │
    └── Background (TextureRect or ColorRect) - microwave image
```

---

## 🎯 STEP-BY-STEP SETUP IN GODOT

### Step 1: Open Your Scene
1. Open `scenes/main.tscn` in Godot
2. Select the root `Main` node
3. Make sure it has the script `scripts/main.gd` attached

### Step 2: Create CookRound (if it doesn't exist)
This should already exist from your previous setup. If not:
1. Add child node → Node → name it "CookRound"
2. Add these 3 children to CookRound:
   - MoistureManager (Node)
   - TimerManager (Node)
   - ItemManager (Node)
3. Attach the respective scripts

### Step 3: Create UI Container
1. Add child node to Main → Control → name it "UI"
2. Set its layout to "Full Rect" (anchors: 0,0 to 1,1)

### Step 4: Create MainMenu
1. Right-click UI → Add Child Node → Panel → name it "MainMenu"
2. Attach script: `scripts/ui/main_menu.gd`
3. Add child to MainMenu → VBoxContainer
4. Add these children to VBoxContainer:
   - Label (name: TitleLabel, text: "MICROWAVE WAVE")
   - Label (name: TaglineLabel, text: "A Microwave's Thirst")
   - Button (name: StartButton, text: "Start Game")
   - Button (name: QuitButton, text: "Quit")

### Step 5: Create IngredientSelector
1. Right-click UI → Add Child Node → Panel → name it "IngredientSelector"
2. Attach script: `scripts/ui/ingredient_selector.gd`
3. Add child → VBoxContainer
4. Add these children to VBoxContainer:
   - Label (name: TitleLabel)
   - Label (name: RoundLabel)
   - Label (name: CurrencyLabel)
   - GridContainer (name: IngredientGrid, columns: 2)
   - Label (name: DrainPreviewLabel)
   - Button (name: StartButton, text: "COOK FOR 15 SECONDS")

### Step 6: Create CookingUI
This should mostly exist from your previous setup. Ensure it has:
1. Control node named "CookingUI"
2. MoistureBar (ProgressBar)
3. TimerDisplay (Label)
4. ActiveItemsContainer (HBoxContainer)
   - ActiveItemButton_1 (Button)
   - ActiveItemButton_2 (Button)
   - ActiveItemButton_3 (Button)

### Step 7: Create RoundCompleteScreen
1. Right-click UI → Add Child Node → Panel → name it "RoundCompleteScreen"
2. Attach script: `scripts/ui/round_complete_screen.gd`
3. Add child → VBoxContainer
4. Add these children:
   - Label (name: TitleLabel)
   - Label (name: MoistureLabel)
   - Label (name: CurrencyEarnedLabel)
   - Label (name: TotalCurrencyLabel)
   - Button (name: ContinueButton, text: "Continue to Shop")

### Step 8: Create RoundFailedScreen
1. Right-click UI → Add Child Node → Panel → name it "RoundFailedScreen"
2. Attach script: `scripts/ui/round_failed_screen.gd`
3. Add child → VBoxContainer
4. Add these children:
   - Label (name: TitleLabel)
   - Label (name: MoistureLabel)
   - Label (name: TimeLabel)
   - Label (name: MessageLabel)
   - HBoxContainer (name: ButtonsContainer)
     - Button (name: RetryButton, text: "Retry")
     - Button (name: MenuButton, text: "Main Menu")

### Step 9: Create ShopScreen
1. Right-click UI → Add Child Node → Panel → name it "ShopScreen"
2. Attach script: `scripts/ui/shop_screen.gd`
3. Add child → ScrollContainer
4. Add child to ScrollContainer → VBoxContainer
5. Add these children to VBoxContainer:
   - Label (name: TitleLabel)
   - Label (name: CurrencyLabel)
   - Label (name: RoundLabel)
   - GridContainer (name: ShopGrid, columns: 2)
   - Button (name: DoneButton, text: "Done Shopping")

### Step 10: Add StatusLabel and Background
1. Add to UI → Label (name: StatusLabel) - for debug messages
2. Add to UI → TextureRect (name: Background) - for microwave image
   - Set its layout to "Full Rect"
   - Move it to the top of the UI children (first child) so it renders behind everything

### Step 11: Configure Panel Sizes
For each Panel (MainMenu, IngredientSelector, etc.):
1. Select the panel
2. Set its Layout to "Center" or position it manually
3. Set custom_minimum_size (e.g., Vector2(400, 300))
4. Optionally add a StyleBox for visual styling

---

## 🔧 QUICK VERIFICATION CHECKLIST

After setting up, verify these @onready paths match your scene:

In `main.gd`:
```gdscript
@onready var moisture_manager: MoistureManager = $CookRound/MoistureManager ✓
@onready var timer_manager: TimerManager = $CookRound/TimerManager ✓
@onready var item_manager: ActiveItemManager = $CookRound/ItemManager ✓

@onready var main_menu: Panel = $UI/MainMenu ✓
@onready var ingredient_selector: Panel = $UI/IngredientSelector ✓
@onready var cooking_ui: Control = $UI/CookingUI ✓
@onready var round_complete_screen: Panel = $UI/RoundCompleteScreen ✓
@onready var round_failed_screen: Panel = $UI/RoundFailedScreen ✓
@onready var shop_screen: Panel = $UI/ShopScreen ✓

@onready var status_label: Label = $UI/StatusLabel ✓
@onready var item_button_1: Button = $UI/ActiveItemsContainer/ActiveItemButton_1 ✓
# (etc.)
```

If any path is incorrect, you'll get a "Node not found" error.

---

## 🎨 STYLING TIPS (Optional)

### Make it Look Good
1. **Panels**: Add a PanelContainer with a StyleBoxFlat
   - Background color: Color(0.2, 0.2, 0.2, 0.9)
   - Border width: 2
   - Corner radius: 8

2. **Labels**: 
   - TitleLabels: font_size = 24, bold
   - Normal labels: font_size = 14
   - Align text: center

3. **Buttons**:
   - custom_minimum_size: Vector2(150, 40)
   - Add hover/pressed styles

4. **Layout**:
   - VBoxContainer: separation = 10
   - HBoxContainer: separation = 5
   - Add MarginContainer around VBoxContainer with margins = 20

---

## 🚀 TESTING YOUR SETUP

1. **Save your scene** (Ctrl+S)
2. **Run the game** (F5)
3. **You should see**:
   - Main menu appears
   - Other screens are hidden
4. **Click "Start Game"**:
   - Main menu disappears
   - Ingredient selector appears with 2 random ingredients
5. **Click "COOK FOR 15 SECONDS"**:
   - Ingredient selector disappears
   - Cooking UI appears
   - Timer counts down
   - Moisture drains
6. **When timer reaches 0**:
   - Cooking UI disappears
   - Round complete screen appears
7. **Click "Continue to Shop"**:
   - Shop screen appears with items
8. **Click "Done Shopping"**:
   - Returns to ingredient selector with next 2 cards

If everything works, congrats! 🎉

---

## 🐛 COMMON ISSUES

### "Node not found" errors
**Problem**: Path in @onready doesn't match scene tree
**Solution**: 
1. Select the node you're trying to reference
2. Right-click → Copy Node Path
3. Paste into your script (without the root node name)

### Nothing appears when game starts
**Problem**: All UI panels are visible at once (overlapping)
**Solution**: 
1. Select each screen panel
2. In Inspector → Visibility → untick "Visible"
3. Only MainMenu should be visible initially
4. The scripts will show/hide panels automatically

### Button clicks don't work
**Problem**: Button signals not connected
**Solution**: Scripts connect signals in _ready(), but verify:
```gdscript
# In main_menu.gd:
func _ready():
    start_button.pressed.connect(_on_start_pressed)
    quit_button.pressed.connect(_on_quit_pressed)
```

### Cooking UI doesn't show ingredients
**Problem**: CookingUI children (moisture bar, timer) need their own UI scripts
**Solution**: These are already set up in your previous implementation. Make sure:
- MoistureBar connects to EventBus.moisture_changed
- TimerDisplay connects to EventBus.timer_updated

---

## 📝 MINIMAL TEST SCENE

If you want to test JUST the new flow without all the UI polish, you can create this minimal version:

```
Main
├── CookRound/
│   ├── MoistureManager
│   ├── TimerManager
│   └── ItemManager
└── UI/
    ├── MainMenu (Panel - empty, just has the script)
    ├── IngredientSelector (Panel - empty)
    ├── CookingUI (Control - reuse your existing one)
    ├── RoundCompleteScreen (Panel - empty)
    ├── RoundFailedScreen (Panel - empty)
    ├── ShopScreen (Panel - empty)
    └── StatusLabel (Label - shows all messages)
```

Even with empty panels, the state machine will work and you can see the flow in the console logs!

---

## ✅ YOU'RE DONE!

Once your scene tree matches this guide, run the game and enjoy your complete roguelike flow! 🎮

Check `IMPLEMENTATION_GUIDE.md` for more details on how the systems work together.
