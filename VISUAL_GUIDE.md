# 🎮 VISUAL PROJECT GUIDE

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    MAIN CONTROLLER (main.gd)                 │
│                  Orchestrates Game Flow                      │
└──────────┬──────────────────────────────────┬────────────────┘
           │                                  │
           ▼                                  ▼
┌──────────────────────────┐      ┌──────────────────────────┐
│   COOK ROUND MANAGERS    │      │      UI LAYER            │
│                          │      │                          │
│  ┌──────────────────┐   │      │  ┌──────────────────┐   │
│  │ MoistureManager  │   │      │  │  MoistureBarUI   │   │
│  │  - current_value │───┼──────┼─▶│  - shows bar     │   │
│  │  - drain_rate    │   │      │  │  - color change  │   │
│  └──────────────────┘   │      │  └──────────────────┘   │
│                          │      │                          │
│  ┌──────────────────┐   │      │  ┌──────────────────┐   │
│  │  TimerManager    │   │      │  │ TimerDisplayUI   │   │
│  │  - countdown     │───┼──────┼─▶│  - shows time    │   │
│  │  - check_done    │   │      │  │  - MM:SS format  │   │
│  └──────────────────┘   │      │  └──────────────────┘   │
│                          │      │                          │
│  ┌──────────────────┐   │      │  ┌──────────────────┐   │
│  │ ItemManager      │   │      │  │ ActiveItemButton │   │
│  │  - cooldowns[3]  │───┼──────┼─▶│  - 3 buttons     │   │
│  │  - use_item()    │   │      │  │  - cooldown UI   │   │
│  └──────────────────┘   │      │  └──────────────────┘   │
│                          │      │                          │
└──────────┬───────────────┘      │  ┌──────────────────┐   │
           │                      │  │ IngredientSelect │   │
           │                      │  │  - pick 2        │   │
           │                      │  │  - start button  │   │
           │                      │  └──────────────────┘   │
           │                      └──────────┬───────────────┘
           │                                 │
           ▼                                 ▼
┌─────────────────────────────────────────────────────────────┐
│                     EVENT BUS (Autoload)                     │
│              Signals for Communication                       │
│                                                              │
│  • round_started(ingredient_1, ingredient_2)                │
│  • round_completed(success, final_moisture)                 │
│  • moisture_changed(new_value)                              │
│  • timer_updated(time_remaining)                            │
│  • item_used(item_index)                                    │
│  • item_cooldown_updated(index, remaining)                  │
└─────────────────────────────────────────────────────────────┘
           ▲                                 ▲
           │                                 │
           │        ┌───────────────────────┴┐
           │        │                         │
┌──────────┴────────┴───┐         ┌──────────┴──────────────┐
│   INGREDIENTS DATA     │         │   ACTIVE ITEMS DATA     │
│      (Autoload)        │         │      (Autoload)         │
│                        │         │                         │
│  • 8 Ingredients       │         │  • Cover (8s CD)        │
│  • Stats (W/H/D/S)    │         │  • Stir (6s CD)         │
│  • Drain calculation   │         │  • Blow (10s CD)        │
└────────────────────────┘         └─────────────────────────┘
```

---

## Game Flow Diagram

```
START
  │
  ▼
┌─────────────────────┐
│ MAIN MENU           │ (Future)
│ (Currently skipped) │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ INGREDIENT SELECTOR                 │
│                                     │
│ ┌───┐ ┌───┐ ┌───┐                 │
│ │ 1 │ │ 2 │ │ 3 │ ← 6 Random      │
│ └───┘ └───┘ └───┘                 │
│ ┌───┐ ┌───┐ ┌───┐                 │
│ │ 4 │ │ 5 │ │ 6 │                 │
│ └───┘ └───┘ └───┘                 │
│                                     │
│ Click 2, then "Start Cooking!"      │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ COOK ROUND (15 seconds)             │
│                                     │
│ Moisture: [████████░░] 80/100       │
│ Timer: 00:08                        │
│                                     │
│ [Cover] [Stir] [Blow]               │
│                                     │
│ Every frame:                        │
│  • Update moisture (drain)          │
│  • Update timer (countdown)         │
│  • Update cooldowns (items)         │
│  • Check win/loss                   │
└──────┬───────────────┬──────────────┘
       │               │
  Moisture = 0    Timer = 0
       │          (Moisture > 0)
       ▼               ▼
┌─────────────┐  ┌─────────────┐
│  FAILURE    │  │  SUCCESS    │
│  "Dried!"   │  │  "Done!"    │
└──────┬──────┘  └──────┬──────┘
       │                │
       └────────┬───────┘
                │
                ▼
       ┌────────────────┐
       │ Show Results   │
       │ Wait 2 seconds │
       └────────┬───────┘
                │
                ▼
       ┌────────────────┐
       │ Back to        │
       │ Ingredient     │
       │ Selector       │
       └────────────────┘
                │
                ▼
              LOOP!
```

---

## Signal Flow Examples

### 1️⃣ Round Start Flow
```
User: Clicks "Start Cooking!"
  │
  ▼
IngredientSelector.gd
  │ emit EventBus.round_started(ing1, ing2)
  │ hide()
  │
  ▼
Main.gd receives signal
  │ _on_round_started(ing1, ing2)
  │
  ├─▶ MoistureManager.setup(ing1, ing2)
  │     │ Calculate drain rate
  │     └─▶ emit EventBus.moisture_changed(100)
  │
  ├─▶ TimerManager.start_timer(15.0)
  │     └─▶ emit EventBus.timer_updated(15.0)
  │
  └─▶ ItemManager.reset_cooldowns()
        └─▶ emit EventBus.item_cooldown_updated(0-2, 0.0)
```

### 2️⃣ Item Usage Flow
```
User: Clicks "Stir" button
  │
  ▼
ActiveItemButtonUI.gd
  │ _pressed()
  │
  ▼
Main.gd
  │ try_use_item(1) ← item_index 1 = Stir
  │
  ▼
ItemManager.use_item(1, moisture_mgr)
  │ Check cooldown > 0? → No
  │ Apply effect
  │
  ▼
ActiveItem.apply_effect(moisture_mgr)
  │ Type.STIR
  │
  ▼
MoistureManager.restore_moisture(20.0)
  │ current_moisture += 20
  │ emit EventBus.moisture_changed(new_value)
  │
  ▼
ItemManager continues
  │ cooldowns[1] = 6.0
  │ emit EventBus.item_used(1)
  │ emit EventBus.item_cooldown_updated(1, 6.0)
  │
  ▼
ActiveItemButtonUI receives signals
  │ _on_item_used(1)
  │   disabled = true
  │   start showing cooldown timer
  │
  └─▶ Button text: "Stir (6.0)"
```

### 3️⃣ Moisture Update Flow (Every Frame)
```
Main._process(delta)
  │ if current_round_active:
  │
  ▼
MoistureManager.update_moisture(delta)
  │ Calculate total_drain (base + modifiers)
  │ current_moisture -= total_drain * delta
  │ emit EventBus.moisture_changed(current_moisture)
  │
  ▼
MoistureBarUI receives signal
  │ _on_moisture_changed(new_value)
  │   value = new_value
  │   label.text = "%d/100"
  │   modulate = Color based on value
  │       > 60: GREEN
  │       > 30: YELLOW
  │        ≤ 30: RED
  │
  ▼
User sees bar update in real-time
```

---

## File Dependencies Map

```
main.gd
 ├─ depends on ─▶ moisture_manager.gd
 ├─ depends on ─▶ timer_manager.gd
 ├─ depends on ─▶ active_item_manager.gd
 ├─ uses ───────▶ EventBus (autoload)
 └─ uses ───────▶ ActiveItemsData (autoload)

moisture_manager.gd
 ├─ depends on ─▶ ingredient_model.gd (class_name)
 └─ uses ───────▶ EventBus

timer_manager.gd
 └─ uses ───────▶ EventBus

active_item_manager.gd
 ├─ depends on ─▶ active_item.gd (class_name)
 ├─ depends on ─▶ moisture_manager.gd (for effects)
 └─ uses ───────▶ EventBus

ingredient_selector.gd
 ├─ depends on ─▶ ingredient_model.gd (class_name)
 ├─ uses ───────▶ IngredientsData (autoload)
 └─ uses ───────▶ EventBus

[UI Controllers]
 └─ All use ────▶ EventBus only (no other dependencies!)

ingredients.gd (autoload)
 └─ depends on ─▶ ingredient_model.gd

active_items_data.gd (autoload)
 └─ depends on ─▶ active_item.gd
```

---

## Scene Tree Structure

```
Main (Node) ← main.gd
│
├─ CookRound (Node)
│  ├─ MoistureManager (Node) ← moisture_manager.gd
│  ├─ TimerManager (Node) ← timer_manager.gd
│  └─ ItemManager (Node) ← active_item_manager.gd
│
└─ UI (CanvasLayer)
   ├─ Background (ColorRect)
   │
   ├─ MoistureBar (ProgressBar) ← moisture_bar_ui.gd
   │  └─ MoistureLabel (Label)
   │
   ├─ TimerDisplay (Label) ← timer_display_ui.gd
   │
   ├─ StatusLabel (Label)
   │
   ├─ ActiveItemsContainer (HBoxContainer)
   │  ├─ ActiveItemButton_1 (Button) ← active_item_button_ui.gd
   │  │                                   @export item_index = 0
   │  ├─ ActiveItemButton_2 (Button) ← active_item_button_ui.gd
   │  │                                   @export item_index = 1
   │  └─ ActiveItemButton_3 (Button) ← active_item_button_ui.gd
   │                                      @export item_index = 2
   │
   └─ IngredientSelector (Panel) ← ingredient_selector.gd
      └─ VBoxContainer
         ├─ TitleLabel (Label)
         ├─ IngredientGrid (GridContainer)
         │  └─ [Cards created dynamically]
         └─ StartButton (Button)
```

---

## Ingredient Stats Visual Guide

```
Each ingredient has 4 stats (0-100):

┌────────────────────────────────────────┐
│ INGREDIENT NAME                        │
├────────────────────────────────────────┤
│ Water Content:    ████████░░ 80/100   │  ← More = higher starting moisture
│ Heat Resistance:  ██████░░░░ 60/100   │  ← More = slower drain
│ Density:          ███████░░░ 70/100   │  ← More = holds moisture better
│ Spice Level:      ████░░░░░░ 40/100   │  ← More = faster drain
└────────────────────────────────────────┘

Drain Formula:
drain_per_second = (Spice × 0.5) - (Heat Resistance × 0.3) - (Density × 0.2)

Example: Lettuce
  Spice: 5 → 2.5
  Heat Res: 20 → -6.0
  Density: 25 → -5.0
  Result: 2.5 - 6.0 - 5.0 = -8.5/sec (very slow drain)

Example: Broccoli
  Spice: 12 → 6.0
  Heat Res: 40 → -12.0
  Density: 60 → -12.0
  Result: 6.0 - 12.0 - 12.0 = -18.0/sec (negative = gains moisture?!)
  
Note: Negative drain means very stable - won't dry out!
```

---

## Active Item Effects Timeline

```
COVER (8s cooldown, 5s effect)
═══════════════════════════════
Use      Effect Duration        Ready Again
 ▼       ◄────────────►         ▼
[■]──────[████████████]─────────[■]
 0s      1s    ...    5s        8s

During effect: drain_rate × 0.6 (40% reduction)


STIR (6s cooldown, instant effect)
═══════════════════════════
Use      Cooldown             Ready Again
 ▼       ◄──────────►         ▼
[■]──────[████████]───────────[■]
 0s                            6s

At use: moisture += 20 (instant)


BLOW (10s cooldown, 3s effect)
═══════════════════════════════════
Use      Effect Duration            Ready Again
 ▼       ◄──────►                   ▼
[■]──────[██████]───────────────────[■]
 0s      1s  ... 3s                 10s

During effect: drain_rate × 0.4 (60% reduction)
```

---

## Typical Round Timeline

```
Time: 15s  14s  13s  12s  11s  10s  9s   8s   7s   6s   5s   4s   3s   2s   1s   0s
      │    │    │    │    │    │    │    │    │    │    │    │    │    │    │    │
Moist:100  95   90   85   80   75   70   65   60   55   50   45   40   35   30   25
      ▲                        ▲                   ▲                        ▲
      │                        │                   │                        │
    Start                   Use Cover           Cover ends              Use Stir
                             ↓40% drain          ↓normal drain          +20 moisture
                             for 5s                                     = 50 moisture

      GREEN ─────────────────────────── YELLOW ──────────────────────── RED ────▶

Win Condition: Reach 0s with moisture > 0
Lose Condition: Moisture = 0 before timer ends
```

---

## Data Structures Quick Reference

### IngredientModel
```gdscript
{
    name: String           # "Chicken Breast"
    water_content: int     # 0-100
    heat_resistance: int   # 0-100
    density: int           # 0-100
    spice_level: int       # 0-100
}
```

### ActiveItem
```gdscript
{
    type: Type                # COVER, STIR, or BLOW
    name: String              # "Cover"
    description: String       # "Trap steam..."
    cooldown_duration: float  # 8.0 seconds
}
```

### Drain Modifier (temporary)
```gdscript
{
    amount: float    # -0.4 = reduce drain by 40%
    duration: float  # 5.0 seconds remaining
}
```

---

## Common Modification Patterns

### Add New Ingredient
1. Open `scripts/data/ingredients.gd`
2. Add to INGREDIENTS dict:
```gdscript
"new_food": {
    "name": "New Food",
    "water_content": 50,
    "heat_resistance": 50,
    "density": 50,
    "spice_level": 50
}
```
3. Test by playing - it will appear in random pools

### Add New Active Item
1. Add type to `active_item.gd`:
```gdscript
enum Type { COVER, STIR, BLOW, NEW_ITEM }
```
2. Add effect in `apply_effect()`:
```gdscript
Type.NEW_ITEM:
    moisture_manager.your_effect_here()
```
3. Add to `active_items_data.gd`
4. Add button to scene
5. Update UI script

### Adjust Balance
**Easier:**
- Increase timer: `timer_manager.start_timer(20.0)`
- Decrease drain coefficients in formula
- Increase item effect strength

**Harder:**
- Decrease timer: `timer_manager.start_timer(10.0)`
- Increase drain coefficients
- Decrease item effect strength
- Increase item cooldowns

---

## Debugging Checklist

When something doesn't work:

✅ **Check EventBus connections**
```gdscript
print(EventBus.moisture_changed.get_connections())
```

✅ **Check if round is active**
```gdscript
print("Round active: ", current_round_active)
```

✅ **Check drain rate**
```gdscript
print("Drain rate: ", base_drain_rate)
```

✅ **Check moisture value**
```gdscript
print("Moisture: ", current_moisture)
```

✅ **Check item cooldowns**
```gdscript
print("Cooldowns: ", cooldowns)
```

✅ **Check autoloads loaded**
```gdscript
print(EventBus)  # Should not be null
print(IngredientsData)
print(ActiveItemsData)
```

---

This visual guide should help you understand exactly how everything connects! 🎮
