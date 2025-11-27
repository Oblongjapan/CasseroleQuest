# 🎮 GAME FLOW IMPLEMENTATION GUIDE

## Overview

The game has been restructured to match the complete flow document. The game now follows this state machine:

```
MAIN_MENU → FRIDGE_INIT → INGREDIENT_SELECTOR → COOKING → 
ROUND_COMPLETE → SHOP → INGREDIENT_SELECTOR (loop)
     ↓
ROUND_FAILED → (retry or return to menu)
```

---

## 🗂️ NEW FILES CREATED

### Managers
- `scripts/managers/game_state_manager.gd` - Centralized state management
- `scripts/managers/fridge_manager.gd` - Deck system (draw, discard, reshuffle)
- `scripts/managers/currency_manager.gd` - Moisture currency tracking
- `scripts/managers/shop_manager.gd` - Shop inventory and purchases

### UI Screens
- `scripts/ui/main_menu.gd` - Start/Quit menu
- `scripts/ui/round_complete_screen.gd` - Success screen with currency earned
- `scripts/ui/round_failed_screen.gd` - Failure screen with retry option
- `scripts/ui/shop_screen.gd` - Shop with upgrades, relics, ingredients

### Updated Files
- `scripts/main.gd` - Completely rewritten to orchestrate new flow
- `scripts/ui/ingredient_selector.gd` - Now shows exactly 2 cards from deck
- `scripts/managers/moisture_manager.gd` - Updated formula (worst_spice, best_heat)
- `scripts/singletons/event_bus.gd` - Added new signals
- `scripts/models/ingredient_model.gd` - Added duplicate() method

---

## 🎯 KEY SYSTEMS

### 1. Fridge Deck System

**How it works:**
- Game starts with 10 ingredient cards (8 unique + 2 duplicates)
- Each round draws 2 cards from the top
- Used cards go to discard pile
- When deck is empty, discard pile reshuffles back into deck
- **Upgrades are persistent** - when a card cycles back, it has your upgrades

**Example:**
```gdscript
# Round 1: Draw Chicken & Lettuce
fridge_manager.draw_cards(2)  # Returns [Chicken, Lettuce]

# After cooking, discard them
fridge_manager.discard_cards([chicken, lettuce])

# Buy upgrade: Chicken +20 Water
fridge_manager.upgrade_ingredient("Chicken Breast", "water", 20)

# Round 6: Deck reshuffles, Chicken comes back with +20 water!
```

### 2. Currency System

**How it works:**
- When you complete a round with remaining moisture, that becomes currency
- Currency persists through rounds
- Spend currency in the shop
- Lose currency if you return to main menu

**Example:**
```gdscript
# Round ends with 85 moisture remaining
currency_manager.add_currency(85)

# In shop: Buy upgrade for 40 currency
if currency_manager.spend_currency(40):
    # Purchase succeeded
```

### 3. Shop System

**Items available:**
1. **Ingredient Upgrades** - Permanently increase Water/Heat/reduce Spice
2. **Relics** - Passive effects (e.g., +10 Heat to all ingredients)
3. **New Ingredients** - Add new cards to your deck
4. **Active Items** - Upgraded Cover/Stir/Blow abilities

**Shop refresh:**
- Generates new inventory each round
- Shows 4 ingredient upgrades
- Shows 2 relics
- Shows 1 new ingredient
- Shows active items (after round 2+)

### 4. Moisture Formula (from document)

```gdscript
starting_moisture = ingredient1.water + ingredient2.water
worst_spice = max(ingredient1.spice, ingredient2.spice)
best_heat = max(ingredient1.heat, ingredient2.heat)

base_drain_rate = 5.0 + (worst_spice × 0.3) - (best_heat × 0.25)
base_drain_rate = max(0.1, base_drain_rate)  # Clamp to minimum
```

**Example:**
- Chicken (Water: 65, Heat: 55, Spice: 10)
- Lettuce (Water: 95, Heat: 20, Spice: 5)

```
Starting Moisture: 65 + 95 = 160
Worst Spice: max(10, 5) = 10
Best Heat: max(55, 20) = 55

Drain = 5.0 + (10 × 0.3) - (55 × 0.25)
      = 5.0 + 3.0 - 13.75
      = -5.75 → clamped to 0.1/sec
```

---

## 🎨 SETTING UP THE SCENE

The scene tree should look like this:

```
Main (scripts/main.gd)
├── CookRound/
│   ├── MoistureManager
│   ├── TimerManager
│   └── ItemManager
├── UI/
│   ├── MainMenu (Panel with scripts/ui/main_menu.gd)
│   │   └── VBoxContainer/
│   │       ├── TitleLabel
│   │       ├── TaglineLabel
│   │       ├── StartButton
│   │       └── QuitButton
│   ├── IngredientSelector (scripts/ui/ingredient_selector.gd)
│   │   └── VBoxContainer/
│   │       ├── TitleLabel
│   │       ├── RoundLabel
│   │       ├── CurrencyLabel
│   │       ├── IngredientGrid (GridContainer)
│   │       ├── DrainPreviewLabel
│   │       └── StartButton
│   ├── CookingUI (Control - for moisture bar, timer, etc.)
│   │   ├── MoistureBar
│   │   ├── TimerDisplay
│   │   └── ActiveItemsContainer/
│   │       ├── ActiveItemButton_1
│   │       ├── ActiveItemButton_2
│   │       └── ActiveItemButton_3
│   ├── RoundCompleteScreen (scripts/ui/round_complete_screen.gd)
│   │   └── VBoxContainer/
│   │       ├── TitleLabel
│   │       ├── MoistureLabel
│   │       ├── CurrencyEarnedLabel
│   │       ├── TotalCurrencyLabel
│   │       └── ContinueButton
│   ├── RoundFailedScreen (scripts/ui/round_failed_screen.gd)
│   │   └── VBoxContainer/
│   │       ├── TitleLabel
│   │       ├── MoistureLabel
│   │       ├── TimeLabel
│   │       ├── MessageLabel
│   │       └── ButtonsContainer/
│   │           ├── RetryButton
│   │           └── MenuButton
│   ├── ShopScreen (scripts/ui/shop_screen.gd)
│   │   └── ScrollContainer/VBoxContainer/
│   │       ├── TitleLabel
│   │       ├── CurrencyLabel
│   │       ├── RoundLabel
│   │       ├── ShopGrid (GridContainer)
│   │       └── DoneButton
│   ├── StatusLabel
│   └── Background (TextureRect - for microwave image)
```

---

## 🔧 HOW TO TEST

### 1. Test Main Menu
- Open scene in Godot
- Click Play
- Should see "MICROWAVE WAVE" with Start/Quit buttons

### 2. Test Ingredient Selector
- Click Start
- Should see exactly 2 ingredient cards
- Cards show their stats (Water, Heat, Spice)
- Button says "COOK FOR 15 SECONDS"

### 3. Test Cooking
- Click cook button
- Timer counts down from 15s
- Moisture drains
- Active item buttons work (if you have items)
- Success: Timer reaches 0 with moisture > 0
- Failure: Moisture reaches 0 before timer ends

### 4. Test Round Complete
- Complete a round successfully
- Should see currency earned (= remaining moisture)
- Shows total currency
- Click "Continue to Shop"

### 5. Test Shop
- Should see ingredient upgrades, relics, etc.
- Buy an upgrade
- Currency decreases
- Click "Done Shopping"

### 6. Test Next Round
- After shop, should return to ingredient selector
- Round number incremented
- Draw 2 new cards from deck
- If you upgraded an ingredient, it shows when that card appears again

### 7. Test Round Failed
- Let moisture reach 0
- Should see failure screen
- Options: Retry or Return to Menu
- Retry: Same round again
- Menu: Reset everything

---

## 🐛 TROUBLESHOOTING

### "Node not found" errors
- Make sure scene tree matches the structure above
- Check @ onready paths in main.gd

### Currency not updating
- Check that CurrencyManager is created in _ready()
- Verify signals are connected

### Deck not cycling
- Check FridgeManager.draw_cards() is being called
- Verify discard_cards() is called after cooking

### Upgrades not persisting
- Check FridgeManager.upgrade_ingredient() is called in shop
- Verify _apply_upgrades_to_card() is called in draw_cards()

### Shop shows no items
- Check ShopManager.refresh_shop() is called
- Verify shop_manager.setup() has correct references

---

## 📝 NEXT STEPS

### Minimal Scene Setup (Quick Test)
1. Create a simple scene with Main node
2. Add UI nodes (can be empty panels initially)
3. Connect signals in main.gd
4. Test state transitions with print statements

### Full Implementation
1. Design UI layouts for each screen
2. Add visual polish (colors, fonts, animations)
3. Implement relic visual indicators
4. Add sound effects (beeping, ding, purchase sounds)
5. Add particle effects for moisture drain
6. Implement more relics and active items
7. Balance difficulty curve

### Advanced Features
1. Save/load system (persist run progress)
2. Achievements/unlocks
3. More ingredients (15+ types)
4. Synergy bonuses (certain ingredient pairs)
5. Boss rounds every 5 rounds
6. Endless mode with leaderboards

---

## 🎓 UNDERSTANDING THE FLOW

```
Player clicks Start
  → EventBus.game_started.emit()
  → main._on_game_started()
  → fridge_manager.initialize_starting_deck() (10 cards shuffled)
  → currency_manager.reset() (start with 0 currency)
  → Change state to INGREDIENT_SELECTOR

Ingredient Selector shown
  → fridge_manager.draw_cards(2) (get 2 cards from top)
  → Display cards (auto-selected)
  → Player clicks "COOK FOR 15 SECONDS"
  → EventBus.round_started.emit(card1, card2)
  → fridge_manager.discard_cards([card1, card2])
  → Change state to COOKING

Cooking active
  → moisture_manager.setup() (calculate drain rate)
  → timer_manager.start_timer(15.0)
  → Each frame: update moisture, timer, cooldowns
  → Check conditions:
      - Moisture ≤ 0: FAILURE
      - Timer = 0: SUCCESS

Success path:
  → EventBus.round_completed.emit(true, final_moisture)
  → currency_manager.add_currency(final_moisture)
  → Show ROUND_COMPLETE screen
  → Player clicks "Continue to Shop"
  → EventBus.shop_opened.emit()
  → shop_manager.refresh_shop() (generate items)
  → Show SHOP screen

Shop interaction:
  → Player buys items
  → currency_manager.spend_currency()
  → fridge_manager.upgrade_ingredient() (if upgrade)
  → inventory_manager.add_relic() (if relic)
  → Player clicks "Done Shopping"
  → EventBus.shop_closed.emit()
  → current_round_number++
  → Return to INGREDIENT_SELECTOR (cycle continues)

Failure path:
  → EventBus.round_completed.emit(false, 0)
  → Show ROUND_FAILED screen
  → Player chooses:
      - Retry: Return to INGREDIENT_SELECTOR (same round)
      - Menu: Reset everything, return to MAIN_MENU
```

---

## 💡 TIPS

1. **Test incrementally** - Get main menu working, then selector, then cooking
2. **Use print statements** - Debug state transitions with prints
3. **Start simple** - Basic UI first, polish later
4. **Check signals** - Make sure all EventBus signals are connected
5. **Verify references** - @onready variables must match scene tree

Good luck with your microwave roguelike! 🎮
