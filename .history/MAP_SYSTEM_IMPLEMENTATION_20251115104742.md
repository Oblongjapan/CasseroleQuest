# Map System - Slay the Spire Style Implementation

## Overview
The progression map has been redesigned to feature branching paths with visual connection lines, similar to Slay the Spire and Inscryption.

## Key Changes

### MapManager (`scripts/managers/map_manager.gd`)
- **15 Tiers Total**: Extended from 8 to 15 tiers for longer runs
- **Variable Node Counts**: Each tier has 2-4 nodes (except start/boss which have 1)
- **Branching Connections**: Each node connects to 1-3 nodes in the next tier
- **Path Tracking**: Added `current_path` array to track the player's chosen route
- **Strategic Tier Placement**:
  - Tier 0: Single starting cooking node
  - Every 5th tier: Shop/Rest/Super Shop options
  - Tier 14 (final): Single boss node
  - Other tiers: Mix of cooking, modifiers, and occasional shops/rest

### MapUI (`scripts/ui/map_ui.gd`)
- **Complete Rewrite**: New visual approach using Control nodes instead of VBox containers
- **Dynamic Positioning**: Nodes positioned in tree-like structure with proper spacing
- **Connection Lines**: Visual lines drawn between connected nodes
  - Gray lines for unexplored paths
  - Green lines for completed paths (active route)
- **Emoji Icons**: Visual node types with emoji symbols
  - 🍳 Cooking
  - ⚡ Modifier
  - 🛒 Shop
  - 💎 Super Shop
  - 🛏 Rest
  - 👹 Boss
- **Enhanced Styling**:
  - Color-coded nodes by type
  - White border for available nodes
  - Gray border for locked nodes
  - Yellow border on hover
  - Larger boss nodes visually emphasized
  - Completed nodes are grayed out

### Visual Layout
```
    [👹 BOSS]           <- Tier 14 (Final)
       |   |
      /     \
  [⚡] [🍳] [🛒]        <- Tier 13
    |  |  |  |
   /   |  |   \
[💎] [🍳] [⚡] [🛏]     <- Tier 12
 ...more tiers...
    [🍳]               <- Tier 0 (Start)
```

### Node Type Distribution
- **Cooking (🍳)**: ~40% of normal tiers - Pure gameplay, no modifier
- **Modifier (⚡)**: ~30% of normal tiers - Adds challenge/reward modifier
- **Shop (🛒)**: ~15% - Buy active items (Cover, Stir, Blow)
- **Super Shop (💎)**: ~10% - Better selection of items
- **Rest (🛏)**: ~5% - Card upgrades (placeholder implementation)
- **Boss (👹)**: Single node at tier 14 - 1.5x drain multiplier

## Player Experience

### Decision Making
- Players see all 15 tiers laid out vertically
- Branching paths require strategic choices
- Can plan ahead by seeing upcoming node types
- Each choice locks out alternative paths

### Visual Feedback
- **Available nodes**: Colored with white border, clickable
- **Locked nodes**: Dark gray, not clickable
- **Completed nodes**: Grayed out, path marked in green
- **Hover effect**: Yellow border + lightened color
- **Connection lines**: Show relationships between tiers

### Progression Flow
1. Start at bottom (Tier 0 - single cooking node)
2. Complete node → connections to next tier become available
3. Choose from available nodes in next tier
4. Repeat until reaching boss at top (Tier 14)
5. Defeat boss → Victory screen

## Technical Implementation

### Node Positioning Algorithm
```gdscript
# For each tier (bottom to top):
1. Calculate tier width based on node count
2. Center nodes horizontally in canvas
3. Position vertically with TIER_SPACING (180px)
4. Store position in button

# Connection lines:
1. Draw from center of node to center of connected nodes
2. Use different colors for active/inactive paths
3. Redraw on node selection
```

### Constants
- `NODE_SIZE`: 100x100 pixels
- `TIER_SPACING`: 180 pixels vertical
- `NODE_SPACING`: 140 pixels horizontal
- `LINE_WIDTH`: 4 pixels
- `LINE_COLOR`: Gray (0.5, 0.5, 0.5, 0.5)
- `LINE_COLOR_ACTIVE`: Green (0.3, 0.9, 0.3, 0.9)

## Files Modified/Created
1. `scripts/managers/map_manager.gd` - Extended to 15 tiers with branching
2. `scripts/ui/map_ui.gd` - Complete rewrite with tree visualization
3. `scripts/main.gd` - Added `map_ui.refresh_ui()` call on node selection

## Future Enhancements
- [ ] Animated line drawing as nodes are completed
- [ ] Particle effects on node completion
- [ ] Better rest node implementation (card upgrade UI)
- [ ] Boss-specific visual effects and mechanics
- [ ] Mini-map overview for large screens
- [ ] Tooltips showing modifier details on hover
- [ ] Sound effects for node selection
- [ ] Smooth camera scrolling to active tier

## Testing Checklist
- [x] Map generates with 15 tiers
- [x] Branching paths connect properly
- [x] Visual lines render between nodes
- [x] Node selection unlocks connected nodes
- [x] Completed paths show in green
- [x] Boss node appears at top
- [x] Shop nodes open shop interface
- [x] Modifier nodes apply effects
- [x] UI refreshes on node selection
