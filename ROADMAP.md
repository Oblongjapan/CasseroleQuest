# Development Roadmap - Week by Week

## ✅ Week 1: Core Mechanics (COMPLETED)

### Implementation Status
- [x] IngredientModel class with drain calculation
- [x] ActiveItem class with effect application
- [x] MoistureManager with drain system
- [x] TimerManager with countdown
- [x] ActiveItemManager with cooldowns
- [x] EventBus signal architecture
- [x] Basic scene structure
- [x] Project configuration with autoloads

### Next Steps for Week 1
1. **Open in Godot 4.x** and verify no errors
2. **Test basic gameplay loop**:
   - Select 2 ingredients
   - Watch moisture drain
   - Use active items
   - Complete/fail round
3. **Balance testing**: Try different ingredient combos
4. **Bug fixes**: Address any runtime errors

---

## Week 2: UI & Polish

### Priority Tasks
- [ ] **Improve Ingredient Selection UI**
  - Add ingredient icons/sprites
  - Better card layout with stats visualization
  - Hover tooltips with drain rate preview
  - Selection feedback animations

- [ ] **Enhance Moisture Bar**
  - Add gradient fill shader
  - Smooth color transitions
  - Particle effects when low
  - Pulsing animation when critical

- [ ] **Better Active Item Buttons**
  - Custom button styles
  - Cooldown progress circle
  - Visual feedback on use (particles, scale animation)
  - Disabled state styling

- [ ] **Timer Display Enhancement**
  - Larger, more visible font
  - Pulsing/shaking when < 5s
  - Progress circle around timer
  - "Danger zone" red background

### Stretch Goals
- [ ] Background microwave interior sprite
- [ ] Food sprite in center that changes based on moisture
- [ ] Round end screen with stats breakdown
- [ ] Transition animations between states

---

## Week 3: Audio & Feedback

### Audio Tasks
- [ ] **Sound Effects**
  - Microwave humming loop (during cooking)
  - Microwave ding (round complete)
  - Button press sounds (item usage)
  - Moisture drain sound (subtle hissing)
  - Warning beep (moisture low)
  - Success/failure jingles

- [ ] **Music** (Optional)
  - Menu theme (calm, inviting)
  - Cooking theme (tense, upbeat)

### Visual Feedback
- [ ] **Particle Systems**
  - Steam rising (moisture draining)
  - Water droplets (stir item used)
  - Ice particles (blow item used)
  - Sparkles (round complete)

- [ ] **Screen Effects**
  - Screen shake when moisture critical
  - Color grading shift (warm → cool with blow)
  - Vignette effect when low moisture

- [ ] **Animations**
  - Food rotation animation during cooking
  - Microwave door opening/closing
  - Item button press animations

---

## Week 4: Content & Balance

### New Ingredients (5-10 more)
- [ ] Pasta (low water, high density)
- [ ] Soup (very high water, low density)
- [ ] Pizza (medium all stats)
- [ ] Cheese (low water, high spice)
- [ ] Corn (medium water, high resistance)
- [ ] Beans (medium water, high density)
- [ ] Tomato (high water, medium spice)
- [ ] Bacon (low water, high spice)

### New Active Items (Optional)
- [ ] **Poke** - Check moisture, reveals exact drain rate for 3s
- [ ] **Rotate** - Redistribute moisture, move 10 from edges to center
- [ ] **Vent** - Release steam, increase drain but reset cooldowns

### Meta Features
- [ ] **Persistent Stats**
  - Track best moisture finish
  - Track longest streak
  - Track total rounds completed
  - Ingredient usage stats

- [ ] **Difficulty Modes**
  - Easy: 20s timer, slower drain
  - Normal: 15s timer (current)
  - Hard: 10s timer, faster drain
  - Extreme: 8s timer, no stir item

- [ ] **Progression** (if time)
  - Unlock ingredients after X rounds
  - Unlock new active items
  - Recipe combinations (bonus for specific pairs)

---

## Week 5: Buffer & QA (If Available)

### Bug Fixing
- [ ] Test all ingredient combinations
- [ ] Edge case testing (moisture exactly 0, timer exactly 0)
- [ ] Cooldown overlap testing
- [ ] UI responsiveness at different resolutions
- [ ] Performance profiling

### Balance Pass
- [ ] Adjust drain rates if too easy/hard
- [ ] Adjust item cooldowns
- [ ] Adjust item effect strengths
- [ ] Test difficulty modes

### Polish
- [ ] Tutorial/instructions screen
- [ ] Settings menu (audio volume, fullscreen)
- [ ] Credits screen
- [ ] Controller support (if needed)

---

## Post-Jam Ideas

### Roguelike Expansion
- [ ] Multiple rounds in a run (survival mode)
- [ ] Item upgrades between rounds
- [ ] Random events during cooking
- [ ] Boss rounds (special challenge conditions)

### Advanced Mechanics
- [ ] Combo system (ingredient synergies)
- [ ] Temperature tracking (separate from moisture)
- [ ] Ingredient conditions (frozen, defrosted, overcooked)
- [ ] Multiple food slots (cook 2+ dishes at once)

### Multiplayer
- [ ] Co-op: Both manage same moisture
- [ ] Versus: Sabotage opponent's moisture
- [ ] Relay: Take turns with active items

---

## Current File Structure

```
Microwavr/
├── scenes/
│   └── main.tscn
├── scripts/
│   ├── main.gd
│   ├── models/
│   │   ├── ingredient_model.gd
│   │   └── active_item.gd
│   ├── managers/
│   │   ├── moisture_manager.gd
│   │   ├── timer_manager.gd
│   │   └── active_item_manager.gd
│   ├── ui/
│   │   ├── moisture_bar_ui.gd
│   │   ├── timer_display_ui.gd
│   │   ├── active_item_button_ui.gd
│   │   └── ingredient_selector.gd
│   ├── data/
│   │   ├── ingredients.gd
│   │   └── active_items_data.gd
│   └── singletons/
│       └── event_bus.gd
├── project.godot
├── icon.svg
├── README.md
├── QUICK_REFERENCE.md
└── ROADMAP.md (this file)
```

---

## Git Workflow Recommendations

### Branching Strategy
- `main` - stable, working builds
- `dev` - active development
- `feature/ingredient-sprites` - specific features
- `fix/moisture-overflow-bug` - bug fixes

### Commit Conventions
- `feat:` new features
- `fix:` bug fixes
- `ui:` UI changes
- `balance:` game balance adjustments
- `docs:` documentation updates

Example: `feat: add pasta and soup ingredients`

---

## Success Metrics

### Minimum Viable Product (MVP)
- [x] 8 ingredients
- [x] 3 active items
- [x] Basic UI
- [x] Win/loss conditions
- [x] One complete round playable

### Polished Prototype
- [ ] 12+ ingredients
- [ ] Enhanced UI with animations
- [ ] Sound effects
- [ ] Round end screen with stats
- [ ] Balanced gameplay

### Full Game Jam Submission
- [ ] 15+ ingredients
- [ ] Multiple difficulty modes
- [ ] Full audio implementation
- [ ] Particle effects
- [ ] Meta progression or stats tracking

---

## Testing Schedule

### Daily Testing (5-10 min)
- Play 3-5 rounds
- Try different ingredient combos
- Note any bugs or balance issues

### Weekly Playtesting (30 min)
- Full feature test
- Record completion times
- Note player friction points
- Gather feedback from others

### Pre-Submission (1 hour)
- Full playthrough of all content
- Test edge cases
- Verify no critical bugs
- Polish pass on visuals/audio

---

## Notes for Future Development

### Performance Targets
- 60 FPS on target hardware
- < 50 MB download size
- < 2 second load time

### Accessibility Considerations
- Color-blind friendly moisture bar (use shapes/patterns)
- Keyboard shortcuts for all buttons
- Adjustable text size
- Sound can be muted without losing gameplay info

### Mobile Port Potential
- Touch-friendly button sizes
- Portrait orientation support
- Simplified UI for small screens
- No precise timing required (good for touch)
