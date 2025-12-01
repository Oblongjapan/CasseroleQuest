from itertools import combinations

# All 13 ingredients
ingredients = [
    "Asparagus", "Bread", "Broccoli", "Carrot", "Chicken Breast",
    "Lettuce", "Peas", "Potato", "Rice", "Salmon", "Spinach", "Steak", "Tofu"
]

# Generate all possible 4-ingredient combinations
all_combos = set()
for combo in combinations(ingredients, 4):
    # Sort alphabetically and join with |
    key = "|".join(sorted(combo))
    all_combos.add(key)

print(f"Total possible 4-ingredient combinations: {len(all_combos)}")

# Read existing recipes from the file
existing_combos = set()
with open(r"c:\Users\willi\OneDrive\Documents\Microwavr\scripts\data\recipes.gd", "r", encoding="utf-8") as f:
    for line in f:
        # Look for 4-ingredient recipe lines
        if line.strip().startswith('"') and line.count('|') == 3:
            # Extract the key (ingredients before the colon)
            if '": "' in line:
                key = line.strip().split('": "')[0].strip('"')
                existing_combos.add(key)

print(f"Existing 4-ingredient combinations: {len(existing_combos)}")
print(f"Missing combinations: {len(all_combos - existing_combos)}")

# Find missing combinations
missing = sorted(all_combos - existing_combos)

print("\nMissing 4-ingredient combinations:")
for combo in missing:
    print(combo)
